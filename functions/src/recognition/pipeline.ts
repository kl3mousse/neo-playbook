/**
 * High-level orchestration for one scan job:
 *
 *  1. Download original from Storage.
 *  2. Preprocess with sharp (EXIF rotate, resize, sharpen, optional crops).
 *  3. First OpenAI pass: visual evidence extraction.
 *  4. Build retrieval candidates per item from the in-memory catalog.
 *  5. Second OpenAI pass: DB-constrained match (model picks from the list only).
 *  6. Calibrated ranking + auto-accept decision.
 *  7. Write a backward-compatible `detected_games` array back to Firestore,
 *     plus extra evidence/debug fields the Flutter app ignores today.
 */

import OpenAI from "openai";
import { DocumentReference, Firestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import * as logger from "firebase-functions/logger";
import { preprocessImage } from "./preprocess";
import {
  DEFAULT_MODELS,
  DbConstrainedRequest,
  PROMPT_VERSION,
  runDbConstrainedMatch,
  runVisualExtraction,
} from "./openai";
import { candidatesForPlatform, getCatalog } from "./catalog";
import { rankCandidates, toCandidatesForModel } from "./retriever";
import { finalizeRanking } from "./ranker";
import { normalizePlatform } from "./platforms";
import {
  DbConstrainedSelection,
  ExtractedItem,
  RankedCandidate,
  RecognitionMode,
} from "./types";

export const SCHEMA_VERSION = "scan_pipeline.v2";

type MatchOut = {
  game_id: string;
  game_title: string;
  platform: string;
  match_score: number;
  combined_confidence: number;
};

type ProcessedDetectedGame = {
  // --- Backward-compatible shape (consumed by the Flutter app today) ---
  candidate_id: string;
  raw_title: string;
  raw_platform: string;
  normalized_platform: string;
  model_confidence: number;
  matches: MatchOut[];
  // --- New evidence fields (additive; old clients ignore) ---
  visible_text: string;
  visible_text_lines: string[];
  platform_hints: string[];
  item_type: string;
  bounding_box: unknown;
  evidence: string;
  selected_game_id: string | null;
  rejected_close_candidates: string[];
  needs_user_confirmation: boolean;
  auto_accepted: boolean;
};

export type ScanPipelineOptions = {
  db: Firestore;
  jobRef: DocumentReference;
  userId: string;
  jobId: string;
  imagePath: string;
  mode: RecognitionMode;
  openai: OpenAI;
};

export async function runScanPipeline(opts: ScanPipelineOptions): Promise<void> {
  const { db, jobRef, userId, jobId, imagePath, mode, openai } = opts;

  const bucket = getStorage().bucket();
  const file = bucket.file(imagePath);
  const [exists] = await file.exists();
  if (!exists) throw new Error(`Image not found at ${imagePath}`);
  const [originalBytes] = await file.download();

  const prepared = await preprocessImage(originalBytes);

  const extraction = await runVisualExtraction(openai, DEFAULT_MODELS.visual, {
    full: prepared.full,
    sharpened: prepared.sharpened,
    crops: prepared.crops,
  });

  const parseWarnings: string[] = [];
  if (extraction.items.length === 0) {
    parseWarnings.push("Vision pass returned no items");
  }

  const catalog = await getCatalog(db);

  type ItemContext = {
    item: ExtractedItem;
    rawTitle: string;
    rawPlatform: string;
    normalizedPlatform: string;
    candidates: RankedCandidate[];
  };

  const contexts: ItemContext[] = [];
  for (const item of extraction.items) {
    const platformHint = item.platform_hints[0] ?? "";
    const normalizedPlatform = normalizePlatform(platformHint);
    const pool = candidatesForPlatform(catalog, normalizedPlatform);
    const ranked = rankCandidates(pool, item, { recognizedPlatform: normalizedPlatform });
    if (ranked.length === 0) {
      const label = item.raw_title_hint || item.visible_text.slice(0, 40);
      if (label) parseWarnings.push(`No catalog matches for "${label}"`);
    }
    contexts.push({
      item,
      rawTitle: item.raw_title_hint,
      rawPlatform: platformHint,
      normalizedPlatform,
      candidates: ranked,
    });
  }

  let selections: DbConstrainedSelection[] = [];
  const matchRequests: DbConstrainedRequest[] = contexts
    .filter((c) => c.candidates.length > 0)
    .map((c) => ({
      item: c.item,
      candidates: toCandidatesForModel(c.candidates),
      crop: null,
    }));

  if (matchRequests.length > 0) {
    try {
      const matchResult = await runDbConstrainedMatch(
        openai,
        DEFAULT_MODELS.match,
        prepared.full,
        matchRequests,
      );
      selections = matchResult.selections;
    } catch (err) {
      logger.warn("DB-constrained match step failed", {
        jobId,
        userId,
        error: err instanceof Error ? err.message : String(err),
      });
      parseWarnings.push("DB-constrained match step failed; falling back to retrieval scores only");
    }
  }

  const selectionByCandidate = new Map(selections.map((s) => [s.candidate_id, s]));

  const detectedGames: ProcessedDetectedGame[] = contexts.map((ctx) => {
    const selection = selectionByCandidate.get(ctx.item.candidate_id);
    const final = finalizeRanking(ctx.candidates, selection);
    const matches: MatchOut[] = final.ranked.map((r) => ({
      game_id: r.game.id,
      game_title: r.game.title,
      platform: r.game.platform,
      match_score: Number(r.title_score.toFixed(3)),
      combined_confidence: Number(r.combined_confidence.toFixed(3)),
    }));
    return {
      candidate_id: ctx.item.candidate_id,
      raw_title: ctx.rawTitle,
      raw_platform: ctx.rawPlatform,
      normalized_platform: ctx.normalizedPlatform,
      model_confidence: Number((selection?.confidence ?? 0).toFixed(3)),
      matches,
      visible_text: ctx.item.visible_text,
      visible_text_lines: ctx.item.visible_text_lines,
      platform_hints: ctx.item.platform_hints,
      item_type: ctx.item.item_type,
      bounding_box: ctx.item.bounding_box ?? null,
      evidence: final.evidence,
      selected_game_id: final.selectedGameId,
      rejected_close_candidates: final.rejectedCloseCandidates,
      needs_user_confirmation: final.needsUserConfirmation,
      auto_accepted: final.autoAccepted,
    };
  });

  await jobRef.set(
    {
      status: "completed",
      mode,
      model: DEFAULT_MODELS.match,
      models: DEFAULT_MODELS,
      prompt_version: PROMPT_VERSION,
      schema_version: SCHEMA_VERSION,
      completed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      detected_games: detectedGames,
      parse_warnings: parseWarnings,
      scene_summary: extraction.scene_summary,
      preprocess: prepared.metadata,
    },
    { merge: true },
  );

  // Separate debug document so the main job stays compact and the
  // evaluation harness can collect per-job raw evidence.
  try {
    await jobRef.collection("debug").doc("v2").set(
      {
        prompt_version: PROMPT_VERSION,
        schema_version: SCHEMA_VERSION,
        models: DEFAULT_MODELS,
        visual_extraction: extraction,
        model_selections: selections,
        candidate_counts: contexts.map((c) => ({
          candidate_id: c.item.candidate_id,
          count: c.candidates.length,
        })),
        created_at: new Date().toISOString(),
      },
      { merge: true },
    );
  } catch (err) {
    logger.warn("Failed to persist debug data", {
      userId, jobId, error: err instanceof Error ? err.message : String(err),
    });
  }
}
