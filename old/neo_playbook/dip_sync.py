"""
Sync DIP settings (soft DIPs + debug DIPs) to Firestore collection ``dip_settings``.

Usage:
    uv run python -m neo_playbook sync-dips --roms 2020bb,kof94
    uv run python -m neo_playbook sync-dips --all [--force]
"""

import yaml

from neo_playbook.firebase_sync import init_firebase
from neo_playbook.paths import DIPS_YAML, DEBUG_DIPS_YAML

try:
    from firebase_admin import firestore
except ImportError:
    raise SystemExit(
        "firebase-admin is required for sync-dips.\n"
        "Install it with:  uv pip install 'neo-playbook[firebase]'"
    )


def _load_yaml(path):
    """Load a YAML file and return its contents as a dict."""
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}


def sync_dip_settings(
    db, rom_name: str, soft_dips: dict, debug_dips: dict, force: bool = False
) -> bool:
    """Build and write a DIP settings document to Firestore.

    Creates/updates document at ``dip_settings/{rom_name}``.
    Returns True if written, False if skipped.
    """
    doc_ref = db.collection("dip_settings").document(rom_name)

    if not force:
        existing = doc_ref.get()
        if existing.exists:
            print(f"  [dip_settings] {rom_name}: already exists, skipping (use --force)")
            return False

    game_soft = soft_dips.get(rom_name)
    game_debug = debug_dips.get(rom_name)

    if not game_soft and not game_debug:
        print(f"  [dip_settings] {rom_name}: no DIP data found")
        return False

    # Build regions map from soft DIPs
    regions = {}
    if game_soft:
        for region_code, region_data in game_soft.items():
            region_doc = {
                "game_name": region_data.get("game_name", ""),
                "special_settings": [
                    {"description": s["description"], "value": str(s["value"])}
                    for s in region_data.get("special_settings", [])
                ],
                "simple_settings": [
                    {
                        "description": s["description"],
                        "default_value": s["default_value"],
                        "value_descriptions": s["value_descriptions"],
                    }
                    for s in region_data.get("simple_settings", [])
                ],
            }
            regions[region_code] = region_doc

    # Build debug DIPs (filter out UNKNOWN entries)
    debug_doc = {}
    if game_debug:
        for group_key, group_entries in game_debug.items():
            filtered = {
                bit_key: desc
                for bit_key, desc in group_entries.items()
                if str(desc).upper() not in ("UNKNOWN", "UNKNOWN+")
            }
            if filtered:
                debug_doc[str(group_key)] = filtered

    doc = {
        "rom_name": rom_name,
        "regions": regions,
        "debug_dips": debug_doc,
        "synced_at": firestore.SERVER_TIMESTAMP,
    }

    doc_ref.set(doc)

    n_regions = len(regions)
    n_settings = sum(
        len(r.get("special_settings", [])) + len(r.get("simple_settings", []))
        for r in regions.values()
    )
    n_debug = sum(len(v) for v in debug_doc.values())
    print(
        f"  [dip_settings] {rom_name}: synced "
        f"({n_regions} region(s), {n_settings} settings, {n_debug} debug entries)"
    )
    return True


def main(rom_names: list[str] | None = None, all_roms: bool = False, force: bool = False):
    """Sync DIP settings for the given romset shortnames."""
    soft_dips = _load_yaml(DIPS_YAML)
    debug_dips = _load_yaml(DEBUG_DIPS_YAML)

    if all_roms:
        # Union of all rom names from both sources
        rom_names = sorted(set(soft_dips.keys()) | set(debug_dips.keys()))
        print(f"\n[sync-dips] Found {len(rom_names)} games with DIP data")
    elif not rom_names:
        print("No roms specified. Use --roms or --all.")
        return

    init_firebase()
    db = firestore.client(database_id="otakudb")

    print(f"\n[sync-dips] Processing {len(rom_names)} game(s)\n")

    synced = 0
    skipped = 0

    for rom_name in rom_names:
        print(f"[{rom_name}]")
        if sync_dip_settings(db, rom_name, soft_dips, debug_dips, force=force):
            synced += 1
        else:
            skipped += 1

    print(f"\n[sync-dips] Done: {synced} synced, {skipped} skipped")
