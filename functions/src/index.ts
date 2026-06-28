import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Query } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import OpenAI from "openai";

const app = initializeApp();

const DATABASE_ID = "otakudb";
const db = getFirestore(app, DATABASE_ID);
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const RECOGNITION_MODEL = "gpt-4o-mini";

type RecognitionMode = "ownership_check" | "bulk_import";

type RecognitionCandidate = {
  title: string;
  platform: string;
  confidence: number;
};

type RankedGameMatch = {
  game_id: string;
  game_title: string;
  platform: string;
  match_score: number;
  combined_confidence: number;
};

type ProcessedDetectedGame = {
  raw_title: string;
  raw_platform: string;
  normalized_platform: string;
  model_confidence: number;
  matches: RankedGameMatch[];
};

type GameCandidate = {
  id: string;
  title: string;
  altTitle: string;
  platform: string;
};

async function deleteAllInQuery(query: Query): Promise<number> {
  let deleted = 0;
  let hasMore = true;

  while (hasMore) {
    const snap = await query.limit(400).get();
    hasMore = !snap.empty;
    if (!hasMore) {
      continue;
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snap.size;
  }

  return deleted;
}

function normalizeText(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function tokenize(value: string): string[] {
  return normalizeText(value).split(" ").filter((token) => token.length > 1);
}

function jaccardOverlap(a: string, b: string): number {
  const aTokens = new Set(tokenize(a));
  const bTokens = new Set(tokenize(b));
  if (aTokens.size === 0 || bTokens.size === 0) {
    return 0;
  }

  let intersection = 0;
  for (const token of aTokens) {
    if (bTokens.has(token)) {
      intersection += 1;
    }
  }
  const union = aTokens.size + bTokens.size - intersection;
  if (union <= 0) {
    return 0;
  }
  return intersection / union;
}

function titleSimilarity(recognizedTitle: string, gameTitle: string): number {
  const recognized = normalizeText(recognizedTitle);
  const game = normalizeText(gameTitle);

  if (!recognized || !game) {
    return 0;
  }

  if (recognized === game) {
    return 1;
  }

  if (recognized.includes(game) || game.includes(recognized)) {
    return 0.88;
  }

  const overlap = jaccardOverlap(recognized, game);
  return Math.min(0.8, overlap * 0.85);
}

function clampConfidence(value: unknown, fallback = 0.5): number {
  if (typeof value !== "number" || Number.isNaN(value)) {
    return fallback;
  }
  return Math.max(0, Math.min(1, value));
}

function normalizePlatform(platform: string | undefined): string {
  const raw = normalizeText(platform ?? "");
  if (!raw) {
    return "";
  }

  const aliases: Record<string, string[]> = {
    mvs: ["mvs", "neo geo mvs", "neogeo mvs", "neo geo arcade"],
    aes: ["aes", "neo geo aes", "neogeo aes", "home cart"],
    ngcd: ["ngcd", "neo geo cd", "neogeo cd"],
    cps1: ["cps1", "cps 1", "capcom cps1"],
    cps2: ["cps2", "cps 2", "capcom cps2"],
  };

  for (const [canonical, values] of Object.entries(aliases)) {
    if (values.some((value) => raw === normalizeText(value))) {
      return canonical;
    }
  }

  return raw.replace(/\s+/g, "");
}

function inferMimeType(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".png")) {
    return "image/png";
  }
  if (lower.endsWith(".webp")) {
    return "image/webp";
  }
  return "image/jpeg";
}

function extractJsonFromResponse(content: string): unknown {
  const trimmed = content.trim();

  try {
    return JSON.parse(trimmed);
  } catch {
    // Keep trying with fenced JSON blocks.
  }

  const blockMatch = trimmed.match(/```json\s*([\s\S]*?)```/i);
  if (blockMatch) {
    return JSON.parse(blockMatch[1]);
  }

  const firstCurly = trimmed.indexOf("{");
  const lastCurly = trimmed.lastIndexOf("}");
  if (firstCurly >= 0 && lastCurly > firstCurly) {
    const candidate = trimmed.slice(firstCurly, lastCurly + 1);
    return JSON.parse(candidate);
  }

  throw new Error("Unable to parse JSON from model output");
}

async function requestImageRecognition(
  imageBase64: string,
  mimeType: string,
): Promise<RecognitionCandidate[]> {
  const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

  const completion = await openai.chat.completions.create({
    model: RECOGNITION_MODEL,
    temperature: 0,
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "You identify arcade game boxes, cartridges, marquees, and discs from photos. Return strict JSON only.",
      },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: [
              "Return JSON as {\"games\":[{\"title\":string,\"platform\":string,\"confidence\":number}]}",
              "- Include up to 4 most likely games visible in the image.",
              "- confidence must be between 0 and 1.",
              "- platform should use arcade-style labels like MVS, AES, NGCD, CPS1, CPS2 when possible.",
              "- If uncertain, still provide best guesses with lower confidence.",
            ].join("\n"),
          },
          {
            type: "image_url",
            image_url: {
              url: `data:${mimeType};base64,${imageBase64}`,
            },
          },
        ],
      },
    ],
  });

  const content = completion.choices[0]?.message?.content ?? "{}";
  const parsed = extractJsonFromResponse(content) as { games?: unknown[] };
  if (!Array.isArray(parsed.games)) {
    return [];
  }

  return parsed.games
    .map((entry) => {
      if (typeof entry !== "object" || entry === null) {
        return null;
      }
      const game = entry as Record<string, unknown>;
      const title = String(game.title ?? "").trim();
      if (!title) {
        return null;
      }
      const platform = String(game.platform ?? "").trim();
      const confidence = clampConfidence(game.confidence, 0.45);
      return { title, platform, confidence };
    })
    .filter((entry): entry is RecognitionCandidate => entry !== null)
    .slice(0, 8);
}

async function loadGameCandidates(platformHint: string): Promise<GameCandidate[]> {
  let query = db.collection("games").limit(1500);
  if (platformHint) {
    query = db.collection("games").where("platform", "==", platformHint).limit(1500);
  }

  let snapshot = await query.get();
  if (snapshot.empty && platformHint) {
    snapshot = await db.collection("games").limit(1500).get();
  }

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      title: String(data.title ?? ""),
      altTitle: String(data.alt_title ?? ""),
      platform: String(data.platform ?? ""),
    };
  });
}

function rankMatches(
  recognized: RecognitionCandidate,
  games: GameCandidate[],
): RankedGameMatch[] {
  const normalizedPlatform = normalizePlatform(recognized.platform);
  const modelConfidence = clampConfidence(recognized.confidence, 0.45);

  return games
    .map((game) => {
      const titleScore = Math.max(
        titleSimilarity(recognized.title, game.title),
        titleSimilarity(recognized.title, game.altTitle),
      );

      const platformScore =
        normalizedPlatform && normalizePlatform(game.platform) === normalizedPlatform
          ? 0.08
          : 0;

      const matchScore = Math.max(0, Math.min(1, titleScore + platformScore));
      return {
        game_id: game.id,
        game_title: game.title,
        platform: game.platform,
        match_score: Number(matchScore.toFixed(3)),
        combined_confidence: Number((matchScore * modelConfidence).toFixed(3)),
      };
    })
    .filter((match) => match.match_score >= 0.35)
    .sort((a, b) => b.combined_confidence - a.combined_confidence)
    .slice(0, 5);
}

export const processAccountDeletionRequest = onDocumentCreated(
  {
    document: "account_deletion_requests/{userId}",
    database: DATABASE_ID,
    region: "europe-west1",
  },
  async (event) => {
    const userId = event.params.userId;
    const requestRef = db.collection("account_deletion_requests").doc(userId);
    const startedAt = new Date().toISOString();

    await requestRef.set(
      {
        status: "processing",
        started_at: startedAt,
      },
      { merge: true },
    );

    let deletedDocs = 0;

    try {
      deletedDocs += await deleteAllInQuery(db.collection(`users/${userId}/favorites`));
      deletedDocs += await deleteAllInQuery(db.collection(`users/${userId}/collection`));
      deletedDocs += await deleteAllInQuery(db.collection(`users/${userId}/fave_moves`));
      deletedDocs += await deleteAllInQuery(db.collection(`users/${userId}/scan_jobs`));
      deletedDocs += await deleteAllInQuery(
        db.collection("community_notes").where("user_id", "==", userId),
      );
      deletedDocs += await deleteAllInQuery(
        db.collection("scores").where("user_id", "==", userId),
      );

      await db.collection("users").doc(userId).delete();

      const profilePicPath = `profile_pics/${userId}.jpg`;
      try {
        await getStorage().bucket().file(profilePicPath).delete();
      } catch (err: unknown) {
        const code = (err as { code?: number | string } | undefined)?.code;
        if (code !== 404 && code !== "storage/object-not-found") {
          throw err;
        }
      }

      try {
        await getStorage().bucket().deleteFiles({
          prefix: `collection_scans/${userId}/`,
        });
      } catch (err: unknown) {
        const code = (err as { code?: number | string } | undefined)?.code;
        if (code !== 404 && code !== "storage/object-not-found") {
          throw err;
        }
      }

      try {
        await getAuth().deleteUser(userId);
      } catch (err: unknown) {
        const code = (err as { code?: string } | undefined)?.code;
        if (code !== "auth/user-not-found") {
          throw err;
        }
      }

      await requestRef.set(
        {
          status: "completed",
          completed_at: new Date().toISOString(),
          deleted_doc_count: deletedDocs,
        },
        { merge: true },
      );

      logger.info("Account deletion completed", {
        userId,
        deletedDocs,
      });
    } catch (error) {
      logger.error("Account deletion failed", {
        userId,
        error,
      });

      await requestRef.set(
        {
          status: "failed",
          failed_at: new Date().toISOString(),
          error_message: error instanceof Error ? error.message : String(error),
        },
        { merge: true },
      );

      throw error;
    }
  },
);

export const processCollectionScanJob = onDocumentCreated(
  {
    document: "users/{userId}/scan_jobs/{jobId}",
    database: DATABASE_ID,
    region: "europe-west1",
    secrets: [OPENAI_API_KEY],
  },
  async (event) => {
    const userId = event.params.userId;
    const jobId = event.params.jobId;
    const jobRef = db.doc(`users/${userId}/scan_jobs/${jobId}`);
    const data = event.data?.data() ?? {};

    if ((data.status as string | undefined) && data.status !== "queued") {
      return;
    }

    const imagePath = data.image_path as string | undefined;
    const imageHash = data.image_hash as string | undefined;
    const mode = (data.mode as RecognitionMode | undefined) ?? "ownership_check";

    if (!imagePath) {
      await jobRef.set(
        {
          status: "failed",
          failed_at: new Date().toISOString(),
          error_message: "Missing image_path",
        },
        { merge: true },
      );
      return;
    }

    await jobRef.set(
      {
        status: "processing",
        processing_started_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      { merge: true },
    );

    try {
      if (imageHash) {
        const existing = await db
          .collection(`users/${userId}/scan_jobs`)
          .where("image_hash", "==", imageHash)
          .where("status", "==", "completed")
          .limit(1)
          .get();

        if (!existing.empty && existing.docs[0].id !== jobId) {
          const existingData = existing.docs[0].data();
          await jobRef.set(
            {
              status: "completed",
              completed_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
              model: existingData.model ?? RECOGNITION_MODEL,
              mode,
              detected_games: existingData.detected_games ?? [],
              parse_warnings: ["Reused prior recognition result with identical image hash"],
              reused_from_job_id: existing.docs[0].id,
            },
            { merge: true },
          );
          return;
        }
      }

      const bucket = getStorage().bucket();
      const file = bucket.file(imagePath);
      const [exists] = await file.exists();
      if (!exists) {
        throw new Error(`Image not found at ${imagePath}`);
      }

      const [bytes] = await file.download();
      const mimeType = (data.mime_type as string | undefined) ?? inferMimeType(imagePath);
      const recognized = await requestImageRecognition(bytes.toString("base64"), mimeType);
      const parseWarnings: string[] = [];

      if (recognized.length === 0) {
        parseWarnings.push("No game candidates returned by the model");
      }

      const processedDetectedGames: ProcessedDetectedGame[] = [];
      for (const candidate of recognized) {
        const normalizedPlatform = normalizePlatform(candidate.platform);
        const games = await loadGameCandidates(normalizedPlatform);
        const matches = rankMatches(candidate, games);

        if (matches.length === 0) {
          parseWarnings.push(`No catalog matches for "${candidate.title}"`);
        }

        processedDetectedGames.push({
          raw_title: candidate.title,
          raw_platform: candidate.platform,
          normalized_platform: normalizedPlatform,
          model_confidence: clampConfidence(candidate.confidence, 0.45),
          matches,
        });
      }

      await jobRef.set(
        {
          status: "completed",
          mode,
          model: RECOGNITION_MODEL,
          completed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          detected_games: processedDetectedGames,
          parse_warnings: parseWarnings,
        },
        { merge: true },
      );

      logger.info("Collection scan processed", {
        userId,
        jobId,
        mode,
        candidates: processedDetectedGames.length,
      });
    } catch (error) {
      logger.error("Collection scan processing failed", {
        userId,
        jobId,
        error,
      });

      await jobRef.set(
        {
          status: "failed",
          failed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          error_message: error instanceof Error ? error.message : String(error),
        },
        { merge: true },
      );
      throw error;
    }
  },
);
