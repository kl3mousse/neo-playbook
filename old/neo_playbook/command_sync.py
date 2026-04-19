"""
Sync parsed command.dat data to Firestore collection ``command_dat``.

Usage:
    uv run python -m neo_playbook sync-moves --roms kof94,samsho
    uv run python -m neo_playbook sync-moves --roms kof94 --force
"""

from neo_playbook.command_parser import parse_command_dat, list_all_romsets
from neo_playbook.firebase_sync import init_firebase
from neo_playbook.paths import COMMAND_DAT

try:
    from firebase_admin import firestore
except ImportError:
    raise SystemExit(
        "firebase-admin is required for sync-moves.\n"
        "Install it with:  uv pip install 'neo-playbook[firebase]'"
    )


def _slugify(text: str) -> str:
    """Convert a section title to a Firestore-safe document ID."""
    return (
        text.lower()
        .replace(" ", "-")
        .replace("~", "")
        .replace("'", "")
        .replace('"', "")
        .replace("(", "")
        .replace(")", "")
        .strip("-")
    )


def sync_command_data(db, rom_name: str, force: bool = False) -> bool:
    """Parse command.dat for a romset and write to Firestore.

    Creates/updates document at ``command_dat/{rom_name}``.
    Returns True if written, False if skipped.
    """
    doc_ref = db.collection("command_dat").document(rom_name)

    if not force:
        existing = doc_ref.get()
        if existing.exists:
            print(f"  [command_dat] {rom_name}: already exists, skipping (use --force)")
            return False

    parsed = parse_command_dat(rom_name, str(COMMAND_DAT))
    if parsed is None:
        print(f"  [command_dat] {rom_name}: not found in command.dat")
        return False

    # Build the Firestore document
    doc = {
        "rom_names": parsed["rom_names"],
        "title": parsed["title"],
        "raw_text": parsed["raw_text"],
        "sections": parsed["sections"],
        "synced_at": firestore.SERVER_TIMESTAMP,
    }

    doc_ref.set(doc)

    n_sections = len(parsed["sections"])
    n_moves = sum(len(s["moves"]) for s in parsed["sections"])
    print(f"  [command_dat] {rom_name}: synced ({n_sections} sections, {n_moves} moves)")
    return True


def main(rom_names: list[str] | None = None, all_roms: bool = False, force: bool = False):
    """Sync command.dat data for the given romset shortnames."""
    if all_roms:
        rom_names = list_all_romsets(str(COMMAND_DAT))
        print(f"\n[sync-moves] Found {len(rom_names)} romsets in command.dat")
    elif not rom_names:
        print("No roms specified. Use --roms or --all.")
        return

    init_firebase()
    db = firestore.client(database_id="otakudb")

    print(f"\n[sync-moves] Processing {len(rom_names)} romset(s)\n")

    synced = 0
    skipped = 0

    for rom_name in rom_names:
        print(f"[{rom_name}]")
        if sync_command_data(db, rom_name, force=force):
            synced += 1
        else:
            skipped += 1

    print(f"\n[sync-moves] Done: {synced} synced, {skipped} skipped")
