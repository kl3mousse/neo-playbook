/**
 * Cloud Function entry points.
 *
 * Keep this file slim:
 *  - Firebase Admin init
 *  - secret binding
 *  - one onDocumentCreated trigger per handler
 *
 * All real logic lives in `./account_deletion.ts` and
 * `./recognition/pipeline.ts`.
 */

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import OpenAI from "openai";

import { processAccountDeletion } from "./account_deletion";
import { runScanPipeline } from "./recognition/pipeline";
import { RecognitionMode } from "./recognition/types";

const app = initializeApp();
const DATABASE_ID = "otakudb";
const db = getFirestore(app, DATABASE_ID);
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

export const processAccountDeletionRequest = onDocumentCreated(
  {
    document: "account_deletion_requests/{userId}",
    database: DATABASE_ID,
    region: "europe-west1",
  },
  async (event) => {
    const userId = event.params.userId;
    await processAccountDeletion({ db, userId });
  },
);

export const processCollectionScanJob = onDocumentCreated(
  {
    document: "users/{userId}/scan_jobs/{jobId}",
    database: DATABASE_ID,
    region: "europe-west1",
    secrets: [OPENAI_API_KEY],
    memory: "1GiB",
    timeoutSeconds: 240,
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
          updated_at: new Date().toISOString(),
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
      // Deduplicate: if the same user already produced a completed job
      // for an image with the identical FNV-1a hash, reuse its result.
      if (imageHash) {
        const existing = await db
          .collection(`users/${userId}/scan_jobs`)
          .where("image_hash", "==", imageHash)
          .where("status", "==", "completed")
          .limit(1)
          .get();

        if (!existing.empty && existing.docs[0].id !== jobId) {
          const prev = existing.docs[0].data();
          await jobRef.set(
            {
              status: "completed",
              completed_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
              mode,
              model: prev.model ?? null,
              models: prev.models ?? null,
              prompt_version: prev.prompt_version ?? null,
              schema_version: prev.schema_version ?? null,
              detected_games: prev.detected_games ?? [],
              parse_warnings: ["Reused prior recognition result with identical image hash"],
              reused_from_job_id: existing.docs[0].id,
            },
            { merge: true },
          );
          return;
        }
      }

      const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });
      await runScanPipeline({
        db, jobRef, userId, jobId, imagePath, mode, openai,
      });

      logger.info("Collection scan processed", { userId, jobId, mode });
    } catch (error) {
      logger.error("Collection scan processing failed", { userId, jobId, error });
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
