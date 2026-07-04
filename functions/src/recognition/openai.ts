/**
 * OpenAI wrappers for the two-pass recognition flow plus an optional
 * reference-image disambiguation fallback.
 *
 * Both passes use strict JSON schema response formats so the model
 * cannot stray from the contract.
 *
 *  Pass 1: `visual_extraction_result`
 *    Pure visual evidence per detected item.
 *
 *  Pass 2: `db_constrained_match_result`
 *    For each item, the model picks at most one game_id from the
 *    candidate list we built from Firestore. It cannot invent ids.
 *
 *  Fallback: `reference_disambiguation_result`
 *    For visually-ambiguous text matches, compare the user's crop
 *    against a handful of catalog reference images.
 */

import OpenAI from "openai";
import {
  ChatCompletionContentPart,
  ChatCompletionMessageParam,
} from "openai/resources/chat/completions";
import {
  CandidateForModel,
  DbConstrainedMatchResult,
  ExtractedItem,
  VisualExtractionResult,
} from "./types";
import { PreparedImage } from "./preprocess";

export const PROMPT_VERSION = "scan_pipeline.v2.2026-06-29";

export type ModelTier = {
  /** First-pass visual extraction (cheap). */
  visual: string;
  /** Second-pass DB-constrained match (cheap by default, escalate on hard cases). */
  match: string;
  /** Stronger model used only for hard cases (low confidence, close top candidates). */
  hardCase: string;
};

export const DEFAULT_MODELS: ModelTier = {
  visual: "gpt-4o-mini",
  match: "gpt-4o-mini",
  hardCase: "gpt-4o",
};

const VISUAL_EXTRACTION_SCHEMA = {
  name: "visual_extraction_result",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      scene_summary: { type: "string" },
      estimated_item_count: { type: "integer", minimum: 0, maximum: 50 },
      items: {
        type: "array",
        maxItems: 25,
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            candidate_id: { type: "string" },
            visible_text: { type: "string" },
            visible_text_lines: {
              type: "array",
              items: { type: "string" },
              maxItems: 20,
            },
            platform_hints: {
              type: "array",
              items: { type: "string" },
              maxItems: 6,
            },
            item_type: {
              type: "string",
              enum: [
                "box", "cartridge", "pcb", "disc", "marquee",
                "flyer", "manual", "spine", "shelf", "unknown",
              ],
            },
            raw_title_hint: { type: "string" },
            uncertainty_reason: { type: "string" },
            bounding_box: {
              anyOf: [
                {
                  type: "object",
                  additionalProperties: false,
                  properties: {
                    x: { type: "number" },
                    y: { type: "number" },
                    width: { type: "number" },
                    height: { type: "number" },
                  },
                  required: ["x", "y", "width", "height"],
                },
                { type: "null" },
              ],
            },
          },
          required: [
            "candidate_id", "visible_text", "visible_text_lines",
            "platform_hints", "item_type", "raw_title_hint",
            "uncertainty_reason", "bounding_box",
          ],
        },
      },
    },
    required: ["scene_summary", "estimated_item_count", "items"],
  },
} as const;

const DB_CONSTRAINED_SCHEMA = {
  name: "db_constrained_match_result",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      selections: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            candidate_id: { type: "string" },
            selected_game_id: {
              anyOf: [{ type: "string" }, { type: "null" }],
            },
            confidence: { type: "number", minimum: 0, maximum: 1 },
            evidence: { type: "string" },
            rejected_close_candidates: {
              type: "array",
              items: { type: "string" },
              maxItems: 5,
            },
            needs_user_confirmation: { type: "boolean" },
          },
          required: [
            "candidate_id", "selected_game_id", "confidence",
            "evidence", "rejected_close_candidates", "needs_user_confirmation",
          ],
        },
      },
    },
    required: ["selections"],
  },
} as const;

const REFERENCE_DISAMBIGUATION_SCHEMA = {
  name: "reference_disambiguation_result",
  strict: true,
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      selected_game_id: { anyOf: [{ type: "string" }, { type: "null" }] },
      confidence: { type: "number", minimum: 0, maximum: 1 },
      evidence: { type: "string" },
    },
    required: ["selected_game_id", "confidence", "evidence"],
  },
} as const;

function dataUrlPart(
  image: PreparedImage,
  detail: "high" | "low" | "auto" = "high",
): ChatCompletionContentPart {
  return {
    type: "image_url",
    image_url: {
      url: `data:${image.mimeType};base64,${image.buffer.toString("base64")}`,
      detail,
    },
  };
}

function urlPart(
  url: string,
  detail: "high" | "low" | "auto" = "high",
): ChatCompletionContentPart {
  return { type: "image_url", image_url: { url, detail } };
}

function textPart(text: string): ChatCompletionContentPart {
  return { type: "text", text };
}

/**
 * First-pass: extract pure visual evidence from the photo (no DB matching).
 */
export async function runVisualExtraction(
  client: OpenAI,
  model: string,
  images: {
    full: PreparedImage;
    sharpened: PreparedImage;
    crops: PreparedImage[];
  },
  opts: { singleSubject?: boolean } = {},
): Promise<VisualExtractionResult> {
  const singleSubjectDirective = opts.singleSubject
    ? [
        "IMPORTANT: This is a single-game import scan.",
        "Focus on the ONE dominant foreground game item. If multiple items are visible, return ONLY the most prominent one.",
        "Do NOT return more than one item in the 'items' array.",
      ]
    : [];

  const userContent: ChatCompletionContentPart[] = [
    textPart(
      [
        "Goal: Extract verifiable visual evidence for every distinct game item visible.",
        "Treat any title you read as a weak hint only — do NOT invent titles, sequels, regions, or years.",
        "Return strict JSON matching the provided schema.",
        "Guidelines:",
        "- candidate_id must be unique per item (e.g. 'item_1', 'item_2').",
        "- visible_text: every readable word/number on the item (max ~400 chars total).",
        "- visible_text_lines: one entry per readable line.",
        "- platform_hints: short tokens like 'MVS', 'AES', 'Neo Geo', 'CPS-2', 'Capcom Play System', 'Neo Geo CD'.",
        "- item_type: pick one of box, cartridge, pcb, disc, marquee, flyer, manual, spine, shelf, unknown.",
        "- raw_title_hint: only the title you can DIRECTLY read. Leave empty if unsure.",
        "- bounding_box: normalized 0..1 coords inside the FULL image, or null if you can't estimate.",
        "- uncertainty_reason: brief reason if you are not confident.",
        "Multiple images of the same scene are provided (full + sharpened + optional crops); fuse evidence across them.",
        ...singleSubjectDirective,
      ].join("\n"),
    ),
    textPart("Full image:"),
    dataUrlPart(images.full, "high"),
    textPart("Contrast/sharpened version for label legibility:"),
    dataUrlPart(images.sharpened, "high"),
  ];

  for (let i = 0; i < images.crops.length; i++) {
    userContent.push(textPart(`Crop ${i + 1} of ${images.crops.length}:`));
    userContent.push(dataUrlPart(images.crops[i], "high"));
  }

  const messages: ChatCompletionMessageParam[] = [
    {
      role: "system",
      content:
        "You are an expert arcade/console game cataloguer. You read box art, cartridges, PCBs, " +
        "marquees, discs, and shelf spines. You ONLY describe what is visibly present. " +
        "You return strict JSON.",
    },
    { role: "user", content: userContent },
  ];

  const completion = await client.chat.completions.create({
    model,
    temperature: 0,
    response_format: { type: "json_schema", json_schema: VISUAL_EXTRACTION_SCHEMA },
    messages,
  });

  const content = completion.choices[0]?.message?.content ?? "{}";
  const parsed = JSON.parse(content) as VisualExtractionResult;
  parsed.items = (parsed.items ?? []).map((item, idx) => ({
    candidate_id: item.candidate_id || `item_${idx + 1}`,
    visible_text: item.visible_text ?? "",
    visible_text_lines: item.visible_text_lines ?? [],
    platform_hints: item.platform_hints ?? [],
    item_type: item.item_type ?? "unknown",
    raw_title_hint: item.raw_title_hint ?? "",
    uncertainty_reason: item.uncertainty_reason ?? "",
    bounding_box: item.bounding_box ?? null,
  } as ExtractedItem));
  parsed.scene_summary = parsed.scene_summary ?? "";
  parsed.estimated_item_count = parsed.estimated_item_count ?? parsed.items.length;
  return parsed;
}

export type DbConstrainedRequest = {
  item: ExtractedItem;
  candidates: CandidateForModel[];
  crop?: PreparedImage | null;
};

/**
 * Second-pass: pick one game_id per item, ONLY from the provided candidate
 * list, or null. The schema makes invented ids structurally hard but the
 * pipeline also validates the result against the candidate set.
 */
export async function runDbConstrainedMatch(
  client: OpenAI,
  model: string,
  fullImage: PreparedImage,
  requests: DbConstrainedRequest[],
): Promise<DbConstrainedMatchResult> {
  if (requests.length === 0) return { selections: [] };

  const itemsPayload = requests.map((r) => ({
    candidate_id: r.item.candidate_id,
    visible_text: r.item.visible_text,
    visible_text_lines: r.item.visible_text_lines,
    platform_hints: r.item.platform_hints,
    item_type: r.item.item_type,
    raw_title_hint: r.item.raw_title_hint,
    uncertainty_reason: r.item.uncertainty_reason,
    bounding_box: r.item.bounding_box,
    candidates: r.candidates,
  }));

  const userContent: ChatCompletionContentPart[] = [
    textPart(
      [
        "Task: for each item, choose exactly ONE candidate from its provided 'candidates' list, or null.",
        "Strict rules:",
        "- selected_game_id MUST be one of the provided game_id values for THAT item, or null.",
        "- Never invent a game_id. Never copy an id from a different item.",
        "- Prefer matches supported by visible text (titles, subtitles, region tags, system labels).",
        "- Sequel/region mismatches must be rejected. 'Metal Slug' does NOT match 'Metal Slug 3'.",
        "- 'KOF 98' refers to The King of Fighters '98; 'KOF 2002' to KOF 2002.",
        "- 'Samurai Spirits' == 'Samurai Shodown'; 'Garou Densetsu' == 'Fatal Fury'.",
        "- 'CPS1 / CPS 1 / Capcom Play System' are the same platform.",
        "- If platform_hints conflict with the candidate's platform, lower confidence and set needs_user_confirmation=true.",
        "- evidence: short string citing the visible words or visual cues that justify the choice.",
        "- rejected_close_candidates: up to 5 game_id strings from THIS item's list you considered but ruled out.",
        "- confidence is between 0 and 1.",
        "- needs_user_confirmation must be true unless evidence is unambiguous.",
        "Return strict JSON matching the schema.",
      ].join("\n"),
    ),
    textPart("Items and their candidate sets:"),
    textPart(JSON.stringify({ items: itemsPayload })),
    textPart("Reference full image:"),
    dataUrlPart(fullImage, "high"),
  ];

  for (const r of requests) {
    if (r.crop) {
      userContent.push(textPart(`Crop for ${r.item.candidate_id}:`));
      userContent.push(dataUrlPart(r.crop, "high"));
    }
  }

  const messages: ChatCompletionMessageParam[] = [
    {
      role: "system",
      content:
        "You are a precise arcade/console game catalog matcher. You ONLY select game ids " +
        "from the provided candidate list. You return strict JSON.",
    },
    { role: "user", content: userContent },
  ];

  const completion = await client.chat.completions.create({
    model,
    temperature: 0,
    response_format: { type: "json_schema", json_schema: DB_CONSTRAINED_SCHEMA },
    messages,
  });

  const content = completion.choices[0]?.message?.content ?? "{}";
  const parsed = JSON.parse(content) as DbConstrainedMatchResult;
  parsed.selections = parsed.selections ?? [];
  return parsed;
}

export type ReferenceCandidate = {
  game_id: string;
  title: string;
  image_urls: string[];
};

export type ReferenceDisambiguationResult = {
  selected_game_id: string | null;
  confidence: number;
  evidence: string;
};

/**
 * Optional hard-case fallback: compare the user crop against reference
 * artwork URLs and pick the closest visual match. Uses the stronger
 * model from the tier.
 */
export async function runReferenceImageDisambiguation(
  client: OpenAI,
  model: string,
  cropImage: PreparedImage,
  candidates: ReferenceCandidate[],
): Promise<ReferenceDisambiguationResult> {
  if (candidates.length === 0) {
    return { selected_game_id: null, confidence: 0, evidence: "no candidates" };
  }

  const userContent: ChatCompletionContentPart[] = [
    textPart(
      [
        "Pick the game whose reference artwork most closely matches the user crop visually.",
        "Use color, logo, character art, and layout. Ignore minor cropping differences.",
        "Return strict JSON.",
      ].join("\n"),
    ),
    textPart("User crop:"),
    dataUrlPart(cropImage, "high"),
  ];

  for (const c of candidates) {
    userContent.push(textPart(`Reference for ${c.game_id} (${c.title}):`));
    for (const url of c.image_urls) {
      userContent.push(urlPart(url, "high"));
    }
  }

  const messages: ChatCompletionMessageParam[] = [
    {
      role: "system",
      content: "You compare images and pick the closest match from the provided list. Strict JSON only.",
    },
    { role: "user", content: userContent },
  ];

  const completion = await client.chat.completions.create({
    model,
    temperature: 0,
    response_format: {
      type: "json_schema",
      json_schema: REFERENCE_DISAMBIGUATION_SCHEMA,
    },
    messages,
  });

  const content = completion.choices[0]?.message?.content ?? "{}";
  return JSON.parse(content) as ReferenceDisambiguationResult;
}
