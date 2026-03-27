"""Centralised path constants for the neo-playbook project."""

from pathlib import Path

# Project root is two levels up from this file (src/neo_playbook/paths.py)
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── data sources ──────────────────────────────────────────────
DATA_DIR = PROJECT_ROOT / "data"
GAMES_JSON = DATA_DIR / "games.json"
DIPS_YAML = DATA_DIR / "dips.yaml"
DEBUG_DIPS_YAML = DATA_DIR / "debug_dips.yaml"
COMMAND_DAT = DATA_DIR / "command-dat" / "command.dat"
ROM_DIR = DATA_DIR / "rom"

# ── assets (static, checked in) ──────────────────────────────
ASSETS_DIR = PROJECT_ROOT / "assets"
FONTS_DIR = ASSETS_DIR / "fonts"
IMAGES_DIR = ASSETS_DIR / "images"
ICONS_DIR = IMAGES_DIR / "icons"
TEMPLATES_DIR = ASSETS_DIR / "templates"

# fonts
FONT_OSAKA = FONTS_DIR / "osaka.unicode.ttf"
FONT_ERBOS = FONTS_DIR / "ErbosdracoNovaOpenNbpRegular-yGa5.ttf"
FONT_ARCADE = FONTS_DIR / "AnonymousPro-Regular-arcade-controls.ttf"

# ── output (generated, git-ignored) ──────────────────────────
OUTPUT_DIR = PROJECT_ROOT / "output"
CACHE_DIR = OUTPUT_DIR / "cache"
SOFT_DIPS_CACHE = CACHE_DIR / "soft-dips"
PDF_DIR = OUTPUT_DIR / "pdf"

# ── secrets ───────────────────────────────────────────────────
SECRETS_FILE = PROJECT_ROOT / "secrets.json"
