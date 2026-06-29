/**
 * Account-deletion handler extracted from index.ts unchanged in behavior.
 * Cleans up the user's Firestore subcollections, scan storage objects,
 * profile picture, and Auth record.
 */

import { Firestore, Query } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import * as logger from "firebase-functions/logger";

async function deleteAllInQuery(db: Firestore, query: Query): Promise<number> {
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

async function safeDeleteStorageObject(path: string): Promise<void> {
  try {
    await getStorage().bucket().file(path).delete();
  } catch (err: unknown) {
    const code = (err as { code?: number | string } | undefined)?.code;
    if (code !== 404 && code !== "storage/object-not-found") {
      throw err;
    }
  }
}

async function safeDeleteStoragePrefix(prefix: string): Promise<void> {
  try {
    await getStorage().bucket().deleteFiles({ prefix });
  } catch (err: unknown) {
    const code = (err as { code?: number | string } | undefined)?.code;
    if (code !== 404 && code !== "storage/object-not-found") {
      throw err;
    }
  }
}

export async function processAccountDeletion(args: {
  db: Firestore;
  userId: string;
}): Promise<void> {
  const { db, userId } = args;
  const requestRef = db.collection("account_deletion_requests").doc(userId);
  const startedAt = new Date().toISOString();

  await requestRef.set(
    { status: "processing", started_at: startedAt },
    { merge: true },
  );

  let deletedDocs = 0;

  try {
    deletedDocs += await deleteAllInQuery(db, db.collection(`users/${userId}/favorites`));
    deletedDocs += await deleteAllInQuery(db, db.collection(`users/${userId}/collection`));
    deletedDocs += await deleteAllInQuery(db, db.collection(`users/${userId}/fave_moves`));
    deletedDocs += await deleteAllInQuery(db, db.collection(`users/${userId}/scan_jobs`));
    deletedDocs += await deleteAllInQuery(
      db,
      db.collection("community_notes").where("user_id", "==", userId),
    );
    deletedDocs += await deleteAllInQuery(
      db,
      db.collection("scores").where("user_id", "==", userId),
    );

    await db.collection("users").doc(userId).delete();

    await safeDeleteStorageObject(`profile_pics/${userId}.jpg`);
    await safeDeleteStoragePrefix(`collection_scans/${userId}/`);
    await safeDeleteStoragePrefix(`collection_items/${userId}/`);

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

    logger.info("Account deletion completed", { userId, deletedDocs });
  } catch (error) {
    logger.error("Account deletion failed", { userId, error });
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
}
