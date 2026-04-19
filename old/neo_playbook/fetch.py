"""
Data enrichment pipeline: reads data/games.json, enriches it with
HFSdb API data, downloads images, extracts soft DIPs, generates 
command block PNGs, and writes the enriched JSON back.

Usage:
    uv run python -m neo_playbook fetch              # enrich all games (skip already populated)
    uv run python -m neo_playbook fetch --force       # re-fetch everything from HFSdb
"""

import json
import os
import sys
import time

from neo_playbook.get_image import download_image
from neo_playbook.hfsdb import get_game_from_hfsdb
from neo_playbook.dips import SoftDipsSettings
from neo_playbook.mame_commands import get_command_blocks
from neo_playbook.paths import GAMES_JSON, COMMAND_DAT, DIPS_YAML, DEBUG_DIPS_YAML, ROM_DIR, CACHE_DIR

DATA_FILE = str(GAMES_JSON)
COMMAND_DAT_FILE = str(COMMAND_DAT)
HFSDB_LANG = "FR"


def load_data():
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def save_data(entries):
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)


def enrich_from_hfsdb(game, force=False):
    """Fetch game data from HFSdb API and populate description, images, etc."""
    hfsdb_id = game.get("hfsdb_id")
    if hfsdb_id is None:
        return

    # Skip if already enriched (unless --force)
    if not force and game.get("description") is not None:
        print(f"  [hfsdb] {game['title']}: already enriched, skipping")
        return

    print(f"  [hfsdb] {game['title']}: fetching from HFSdb #{hfsdb_id}...", end="")
    hfs_game = get_game_from_hfsdb(hfsdb_id)
    if hfs_game is None:
        print(" ERROR")
        return

    # Description
    if HFSDB_LANG == "FR":
        game["description"] = hfs_game.get("description_fr")
    else:
        game["description"] = hfs_game.get("description_en")

    # Cover 3D
    for media in hfs_game.get("medias", []):
        if media["type"] == "cover3d" and not media["file"].upper().endswith("GIF"):
            game["images"]["cover3d"]["url"] = media["file"]
            break

    # Wallpaper
    for media in hfs_game.get("medias", []):
        if media["type"] == "wallpaper" and media.get("res_y", 0) > 32:
            game["images"]["wallpaper"]["url"] = media["file"]
            break

    # Screenshots
    for media in hfs_game.get("medias", []):
        if media["type"] == "screenshot" and not media["file"].upper().endswith("GIF"):
            if media.get("metadata") and media["metadata"][0]["value"] == "title":
                game["images"]["screenshot_title"]["url"] = media["file"]
            else:
                if game["images"]["screenshot_main"]["url"] is None:
                    game["images"]["screenshot_main"]["url"] = media["file"]
                elif game["images"]["screenshot_alt"]["url"] is None:
                    game["images"]["screenshot_alt"]["url"] = media["file"]

    # Mini marquee
    for media in hfs_game.get("medias", []):
        if (media["type"] == "instructioncard"
                and not media["file"].upper().endswith("GIF")
                and media.get("res_x", 0) < media.get("res_y", 0)):
            game["images"]["mini_marquee"]["url"] = media["file"]
            break

    # Number of players
    for metadata in hfs_game.get("metadata", []):
        if metadata["id"] == 85507:
            p = metadata["value"]
            game["nb_players"] = "2P" if p == "2 joueurs" else p
            break
        if metadata["id"] == 48762:
            p = metadata["value"]
            game["nb_players"] = "1P" if p == "1 joueur" else p
            break

    # Genre
    for metadata in hfs_game.get("metadata", []):
        if metadata.get("name") == "genre":
            game["genre"] = metadata["value"]
            break

    print(" done")


def download_all_images(game):
    """Download all images that have a URL but no local file."""
    for key, img in game.get("images", {}).items():
        url = img.get("url")
        if url is None:
            continue
        # Skip if already downloaded
        if img.get("local") and os.path.exists(img["local"]):
            continue
        local = download_image(url)
        if local:
            img["local"] = local
            print(f"  [img] {key}: {os.path.basename(local)}")


def extract_softdips(game):
    """Extract soft DIP settings from ROM files for Neo Geo games."""
    if game.get("platform") != "neogeo":
        return
    if not game.get("roms"):
        return

    dips = SoftDipsSettings(str(DIPS_YAML), str(DEBUG_DIPS_YAML))
    softdips_image = None

    for rom in game["roms"]:
        rom_name = rom.get("rom_name")
        if not rom_name:
            continue
        if rom.get("exclude_softdips"):
            continue

        if not dips.game_settings_found(game_code=rom_name, region="US"):
            dips.enrich_softdip_settings_from_rom(
                game_id=rom_name,
                path=str(ROM_DIR / f"{rom_name}.zip"),
                language="US",
            )
            dips.enrich_softdip_settings_from_rom(
                game_id=rom_name,
                path=str(ROM_DIR / f"{rom_name}.zip"),
                language="EU",
            )

        if dips.game_settings_found(game_code=rom_name, region="US"):
            dips.generate_settings_image(game_code=rom_name, region="US", path=str(CACHE_DIR))
            softdips_image = dips.generate_settings_image(
                game_code=rom_name, region="EU", path=str(CACHE_DIR)
            )
        else:
            softdips_image = None

    game["softdips_image"] = softdips_image
    if softdips_image:
        print(f"  [dips] {game['title']}: {os.path.basename(softdips_image)}")


def generate_command_blocks(game):
    """Generate command block PNGs from MAME command.dat."""
    if not game.get("roms"):
        return

    # Skip if already generated
    if game.get("command_blocks"):
        return

    for rom in game["roms"]:
        rom_name = rom.get("rom_name")
        if not rom_name:
            continue
        files = get_command_blocks(rom_name, COMMAND_DAT_FILE)
        if files:
            game["command_blocks"] = files
            print(f"  [cmd] {game['title']}: {len(files)} blocks from {rom_name}")
            return

    game["command_blocks"] = []


def main():
    force = "--force" in sys.argv

    entries = load_data()
    games = [e for e in entries if e.get("page_type") == "game"]
    print(f"Loaded {len(entries)} entries ({len(games)} games)")

    for i, game in enumerate(games, 1):
        print(f"\n[{i}/{len(games)}] {game.get('title', '???')}")

        # Step 1: HFSdb enrichment
        enrich_from_hfsdb(game, force=force)

        # Step 2: Download images
        download_all_images(game)

        # Step 3: Soft DIP extraction
        extract_softdips(game)

        # Step 4: Command block generation
        generate_command_blocks(game)

    save_data(entries)
    print(f"\nDone. Enriched data written to {DATA_FILE}")


if __name__ == "__main__":
    main()
