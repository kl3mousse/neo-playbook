"""
Firebase sync: pushes game data to Firestore and images to Firebase Storage.

Usage:
    uv run python -m neo_playbook sync              # sync all games (skip unchanged)
    uv run python -m neo_playbook sync --force       # re-upload everything
"""

import json
import mimetypes
import os
from datetime import datetime, timezone
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, storage
except ImportError:
    raise SystemExit(
        "firebase-admin is required for sync.\n"
        "Install it with:  uv pip install 'neo-playbook[firebase]'"
    )

from neo_playbook.paths import GAMES_JSON, CACHE_DIR, FIREBASE_SERVICE_ACCOUNT, SECRETS_FILE

# Image keys we sync to Firebase Storage
IMAGE_KEYS = [
    "wallpaper",
    "cover3d",
    "screenshot_title",
    "screenshot_main",
    "screenshot_alt",
    "mini_marquee",
    "background",
]

# ── Firebase init ─────────────────────────────────────────────


def _load_config():
    """Load Firebase config from secrets.json."""
    with open(SECRETS_FILE, "r", encoding="utf-8") as f:
        secrets = json.load(f)
    return {
        "storageBucket": secrets.get(
            "FIREBASE_STORAGE_BUCKET", "otaku-playbook.firebasestorage.app"
        ),
    }


def init_firebase():
    """Initialise Firebase Admin SDK (idempotent)."""
    if firebase_admin._apps:
        return

    if not FIREBASE_SERVICE_ACCOUNT.exists():
        raise SystemExit(
            f"Firebase service account key not found at {FIREBASE_SERVICE_ACCOUNT}\n"
            "Download it from the Firebase console → Project settings → Service accounts → Generate new private key\n"
            "Then save it as firebase-service-account.json at the project root."
        )

    config = _load_config()
    cred = credentials.Certificate(str(FIREBASE_SERVICE_ACCOUNT))
    firebase_admin.initialize_app(cred, config)
    print("[firebase] Initialised")


# ── Data loading ──────────────────────────────────────────────


def load_games():
    """Load games from the local JSON file."""
    with open(GAMES_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


# ── Image upload ──────────────────────────────────────────────


def _resolve_local_path(local_value: str | None) -> Path | None:
    """Resolve a game image 'local' value to an absolute path."""
    if not local_value:
        return None

    # Try as-is first (absolute or valid relative from cwd)
    p = Path(local_value)
    if p.exists():
        return p

    # Strip the img-cache/ prefix and look in output/cache/
    basename = Path(local_value).name
    cache_path = CACHE_DIR / basename
    if cache_path.exists():
        return cache_path

    return None


def upload_image(game_id: str, image_key: str, local_path: Path) -> str:
    """Upload a single image to Firebase Storage and return its public URL."""
    bucket = storage.bucket()
    ext = local_path.suffix
    blob_path = f"images/{game_id}/{image_key}{ext}"
    blob = bucket.blob(blob_path)

    content_type = mimetypes.guess_type(str(local_path))[0] or "application/octet-stream"
    blob.upload_from_filename(str(local_path), content_type=content_type)
    blob.make_public()

    return blob.public_url


def sync_images_to_storage(game: dict) -> dict:
    """Upload all images for a game. Returns a map of image_key → storage info."""
    game_id = game["id"]
    images = game.get("images", {})
    storage_map = {}

    for key in IMAGE_KEYS:
        img = images.get(key, {})
        local_path = _resolve_local_path(img.get("local"))
        if local_path is None:
            continue

        try:
            public_url = upload_image(game_id, key, local_path)
            storage_map[key] = {
                "url": img.get("url"),
                "storage_url": public_url,
                "storage_path": f"images/{game_id}/{key}{local_path.suffix}",
            }
            print(f"    [storage] {key}: uploaded")
        except Exception as e:
            print(f"    [storage] {key}: FAILED — {e}")

    return storage_map


# ── Firestore sync ────────────────────────────────────────────


def _game_to_firestore_doc(game: dict, storage_images: dict) -> dict:
    """Convert a game dict to a Firestore-ready document."""
    doc = {}

    # Direct fields
    for field in [
        "page_type", "platform", "id", "hfsdb_id",
        "title", "alt_title", "year", "publisher",
        "type", "generation", "genre", "nb_players",
        "description", "background_vshift", "invert_screenshots",
    ]:
        if field in game:
            doc[field] = game[field]

    # Images — merge original URLs with storage URLs
    if storage_images:
        doc["images"] = storage_images
    elif "images" in game:
        # Fallback: store original image URLs without storage paths
        doc["images"] = {
            k: {"url": v.get("url")}
            for k, v in game["images"].items()
            if v.get("url")
        }

    # ROMs
    if "roms" in game:
        doc["roms"] = game["roms"]

    # Platform-specific
    if "platform_specific" in game:
        doc["platform_specific"] = game["platform_specific"]

    # Sync metadata
    doc["synced_at"] = firestore.SERVER_TIMESTAMP

    return doc


def sync_game_to_firestore(db, game: dict, storage_images: dict, force: bool = False):
    """Sync a single game to Firestore."""
    game_id = game["id"]
    doc_ref = db.collection("games").document(game_id)

    if not force:
        existing = doc_ref.get()
        if existing.exists:
            print(f"  [firestore] {game['title']}: already exists, skipping")
            return False

    doc = _game_to_firestore_doc(game, storage_images)
    doc_ref.set(doc, merge=True)
    print(f"  [firestore] {game['title']}: synced")
    return True


# ── Main orchestrator ─────────────────────────────────────────


def main(force: bool = False):
    """Load games.json, upload images to Storage, sync to Firestore."""
    init_firebase()

    db = firestore.client(database_id="otakudb")
    games = load_games()

    # Filter to actual game entries
    game_entries = [g for g in games if g.get("page_type") == "game"]
    print(f"\n[sync] {len(game_entries)} games to sync\n")

    synced = 0
    skipped = 0

    for game in game_entries:
        title = game.get("title", game.get("id", "?"))
        print(f"[{game['id']}] {title}")

        # 1. Upload images to Storage
        storage_images = sync_images_to_storage(game)

        # 2. Sync to Firestore
        was_synced = sync_game_to_firestore(db, game, storage_images, force=force)
        if was_synced:
            synced += 1
        else:
            skipped += 1

    print(f"\n[sync] Done: {synced} synced, {skipped} skipped")
