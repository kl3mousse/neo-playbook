import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Query } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

const app = initializeApp();

const DATABASE_ID = "otakudb";
const db = getFirestore(app, DATABASE_ID);

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

export const processAccountDeletionRequest = onDocumentCreated(
  {
    document: "account_deletion_requests/{userId}",
    database: DATABASE_ID,
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
