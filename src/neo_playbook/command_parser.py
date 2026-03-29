"""
Parse MAME command.dat into structured data for Firestore.

Follows MAME's architecture:
  1) Romset-level identity (keyed by shortname)
  2) Raw text payload (verbatim blob)
  3) Structured data for UI rendering

Usage:
    from neo_playbook.command_parser import parse_command_dat
    result = parse_command_dat("kof94", str(COMMAND_DAT))
    # result = {"rom_names": ["kof94"], "title": "...", "raw_text": "...", "sections": [...]}
"""

import re
import unicodedata

from neo_playbook.paths import COMMAND_DAT

# Category prefix → category name
_CATEGORY_MAP = {
    "_(": "throw",
    "_)": "command",
    "_@": "special",
    "_*": "super",
    "_&": "ultra",
    "_#": "other",
}

# Weird control-char patterns found in some command.dat entries
_TO_CLEAN = [
    "(-/-/\u2500) ",
    "(-/I/\u2500) ",
    "(-/-/O) ",
    "(-/I/O) ",
    "(!/I/O) ",
]


def _is_section_header(line: str) -> bool:
    """Detect section delimiter lines like '- TERRY BOGARD -  Japan Team'."""
    if not line or (line[0] != "-" and line[0] != "\u2014"):
        return False
    # Must not have _ near start (would be a move line starting with _)
    if "_" in line[:10]:
        return False
    # Must have a second '-' after position 2 (closing the header)
    return line[2:].find("-") > 0


def _is_separator_line(line: str) -> bool:
    """Detect horizontal rule lines (─────...)."""
    stripped = line.strip()
    return len(stripped) > 10 and all(c in "─-═" for c in stripped)


def _classify_section(title: str) -> str:
    """Determine section_type from the title text."""
    upper = title.upper()
    if "CONTROL" in upper:
        return "controls"
    if "HOW TO PLAY" in upper:
        return "how_to_play"
    if "COMMON" in upper or "BASIC" in upper:
        return "common"
    if "CHEAT" in upper:
        return "other"
    return "character"


def _parse_section_title(header_line: str) -> tuple[str, str | None]:
    """Extract title and optional subtitle from a section header line.

    Examples:
        '- TERRY BOGARD -                 Italy Team\\n'
          → ('TERRY BOGARD', 'Italy Team')
        '- COMMON COMMANDS -\\n'
          → ('COMMON COMMANDS', None)
        '- RUGAL BERNSTEIN - (Secret Character)\\n'
          → ('RUGAL BERNSTEIN', 'Secret Character')
    """
    line = header_line.strip()

    # Strip leading dash/em-dash and spaces
    line = line.lstrip("-\u2014 ")

    # Find the closing dash
    dash_pos = line.find(" -")
    if dash_pos < 0:
        dash_pos = line.find(" \u2014")
    if dash_pos < 0:
        return line.strip(), None

    title = line[:dash_pos].strip()
    rest = line[dash_pos + 2:].strip().lstrip("-\u2014 ").strip()

    # Clean up parentheses from subtitle
    if rest.startswith("(") and rest.endswith(")"):
        rest = rest[1:-1].strip()

    subtitle = rest if rest else None
    return title, subtitle


def _clean_line(line: str) -> str:
    """Remove known garbage patterns from a line."""
    result = line
    for pattern in _TO_CLEAN:
        result = result.replace(pattern, "")
    return result


def _parse_move_line(line: str) -> dict | None:
    """Parse a single move line into a structured dict.

    Move lines have the format:
        CATEGORY MOVE_NAME                          INPUT_NOTATION
    where the separator is 8+ spaces.

    Returns None for empty/unparseable lines.
    """
    stripped = line.rstrip("\n").rstrip()
    if len(stripped) < 2:
        return None

    # Detect category prefix (first 2 chars)
    category = ""
    text = stripped
    prefix = stripped[:2]
    if prefix in _CATEGORY_MAP:
        category = _CATEGORY_MAP[prefix]
        text = stripped[2:].lstrip()

    # Check for backtick lines (notes/comments in command.dat)
    if stripped.startswith("_`") or stripped.startswith("`"):
        note_text = stripped.lstrip("_` ")
        if note_text:
            return {"name": note_text, "input": "", "category": "", "note": "info"}
        return None

    # Split name and input by 8+ space separator
    match = re.search(r"  {7,}", text)
    if match:
        name = text[:match.start()].strip()
        input_notation = text[match.end():].strip()
    else:
        # No separator — text-only line (description, note, etc.)
        name = text.strip()
        input_notation = ""

    if not name:
        return None

    return {
        "name": name,
        "input": input_notation,
        "category": category,
        "note": None,
    }


def list_all_romsets(dat_filepath: str | None = None) -> list[str]:
    """Return the parent romset shortname for every entry in command.dat.

    The parent is the first name in each ``$info=`` line.
    """
    if dat_filepath is None:
        dat_filepath = str(COMMAND_DAT)

    romsets: list[str] = []
    with open(dat_filepath, "r", encoding="UTF-8") as f:
        for line in f:
            if line.startswith("$info"):
                names = [n.strip() for n in line[6:].split(",")]
                if names and names[0]:
                    romsets.append(names[0])
    return romsets


def parse_command_dat(rom_name: str, dat_filepath: str | None = None) -> dict | None:
    """Parse command.dat for a given romset shortname.

    Returns a dict ready for Firestore:
        {
            "rom_names": ["kof94"],
            "title": "The King of Fighters '94",
            "raw_text": "...",
            "sections": [
                {
                    "title": "CONTROLS",
                    "subtitle": None,
                    "order": 0,
                    "section_type": "controls",
                    "moves": [...]
                },
                ...
            ]
        }

    Returns None if rom_name not found in the file.
    """
    if dat_filepath is None:
        dat_filepath = str(COMMAND_DAT)

    with open(dat_filepath, "r", encoding="UTF-8") as f:
        rows = f.readlines()

    # ── Phase 1: locate the entry ─────────────────────────────
    found = False
    rom_names: list[str] = []
    entry_start = -1
    entry_end = -1

    for i, row in enumerate(rows):
        if not found and row.startswith("$info"):
            game_list = [g.strip() for g in row[6:].split(",")]
            if rom_name in game_list:
                found = True
                rom_names = game_list
                entry_start = i
                continue

        if found and row.startswith("$end"):
            entry_end = i
            break

    if not found:
        return None

    # ── Phase 2: extract raw text and title ───────────────────
    # Skip the $info line; content starts after $cmd
    content_lines = rows[entry_start + 1 : entry_end]

    # Skip $cmd line if present
    raw_lines = []
    title_line = ""
    past_cmd = False
    for line in content_lines:
        if not past_cmd:
            if line.strip() == "$cmd":
                past_cmd = True
                continue
            # Some entries start with $cmd on same line as $info
            past_cmd = True

        raw_lines.append(line)

    raw_text = "".join(raw_lines)

    # Title is the first non-empty line (game name + copyright)
    for line in raw_lines:
        stripped = line.strip()
        if stripped:
            title_line = stripped
            break

    # ── Phase 3: parse into sections ──────────────────────────
    sections: list[dict] = []
    current_section: dict | None = None
    section_order = 0

    for line in raw_lines:
        # Skip separator lines (─────...)
        if _is_separator_line(line):
            continue

        if _is_section_header(line):
            # Save previous section
            if current_section is not None:
                sections.append(current_section)

            title, subtitle = _parse_section_title(line)
            current_section = {
                "title": title,
                "subtitle": subtitle,
                "order": section_order,
                "section_type": _classify_section(title),
                "moves": [],
            }
            section_order += 1
            continue

        # If we have an active section, parse move lines
        if current_section is not None:
            cleaned = _clean_line(line)
            move = _parse_move_line(cleaned)
            if move is not None:
                current_section["moves"].append(move)

    # Don't forget the last section
    if current_section is not None:
        sections.append(current_section)

    return {
        "rom_names": rom_names,
        "title": title_line,
        "raw_text": raw_text,
        "sections": sections,
    }
