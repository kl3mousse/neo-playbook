# ComboFox Moves Profile — Consumer Specification

**Contract:** `combofox-moves-profile`
**Version:** `1.0.0`
**Schema:** `schema.json` (JSON Schema Draft 2020-12) — ships alongside this document.

This document is self-contained. A consumer application (e.g. a Flutter
frontend, a Web viewer, a documentation generator) can integrate a
Moves Profile without any access to the source repository. All the
information required to read, render and reason about a profile is
captured here or in the accompanying `schema.json`.

---

## 1. Purpose and scope

A **Moves Profile** describes, for a given fighting-game dataset
(platform + ROM set + region), the following:

- The set of **buttons** used by the game (with symbols and labels).
- Optional **button groups** used as shorthands in notations.
- The list of **characters** in the game.
- The list of **moves** for those characters, each with:
  - a canonical **input expression tree** (structured, machine-readable);
  - a raw notation snippet **preserved verbatim** for fallback display;
  - **activation** semantics (player input, automatic follow-up, contextual);
  - optional **annotations** (guard properties, hit properties, notes…);
  - optional **follow-up** references to other moves.
- A canonical **attribution** block, including a pre-formatted display string.

Profiles are produced by the ComboFox curation pipeline. Once a profile
is included in a signed bundle (see §10), it is immutable for that build
id.

---

## 2. Bundle layout

A bundle is a folder with the following contents:

```
<dataset_id>/<build_id>/
    profile.json              # this is the main artefact
    schema.json               # copy of the JSON Schema for this contract
    CONSUMER_SPEC.md          # this document
    HANDOFF.md                # optional integration notes
    examples/
        minimal.profile.json
        activation-automatic.profile.json
        …
    rendering-samples.json    # optional reference renderings
    manifest.json             # versions, checksums, counts
```

`manifest.json` is authoritative for versions and file integrity:

```json
{
  "contract": { "name": "combofox-moves-profile", "version": "1.0.0", "gold_schema_version": "1.0.0" },
  "silver_schema_version": "0.2.0",
  "dataset_id": "ngpc-kofr2",
  "build_id": "…",
  "generated_at": "2026-07-29T00:00:00Z",
  "source_profile_id": "…",
  "profile_id": "…",
  "profile_revision": 1,
  "counts": { "characters": 23, "moves": 289, "moves_parsed": 286, "moves_partial": 0, "moves_unparsed": 0, "moves_automatic": 3, "moves_contextual_trigger": 0 },
  "attribution_display_text": "…",
  "files": [ { "path": "profile.json", "sha256": "…", "bytes": 123456 }, … ]
}
```

Consumers **MUST** verify the SHA-256 of every file they load against
the manifest before using the data.

---

## 3. Top-level profile shape

```jsonc
{
  "gold_schema_version": "1.0.0",              // MUST equal "1.0.0"
  "silver_schema_version": "0.2.0",            // upstream version — informational
  "id": "ngpc-kof-r2@rev1",                    // stable profile id
  "profile_revision": 1,                       // integer, monotonic per dataset
  "generated_at": "2026-07-29T00:00:00Z",      // ISO 8601 UTC, optional
  "applies_to": { … },                         // §4
  "attribution": { … },                        // §5
  "buttons": [ … ],                            // §6
  "button_groups": [ … ],                      // §6 — optional
  "characters": [ … ],                         // §7
  "moves": [ … ]                               // §8
}
```

Order matters: `characters[]` and `moves[]` preserve the editorial
ordering intended by the curators (character roster order, and per-move
authoring order). Consumers **SHOULD** preserve this order in UI lists
unless the user explicitly opts in to a different sort.

---

## 4. `applies_to`

```json
{
  "game_id": "kof-r2",         // opaque game slug — MAY be null
  "platform": "ngpc",          // opaque platform slug (e.g. ngpc, mvs, cps2)
  "region": "world",           // opaque region tag — MAY be null
  "rom_ids": ["kofr2"],        // 0..N MAME/ROM ids
  "notation_frame": "player_relative"  // "player_relative" | "stick_absolute" | "mixed_explicit"
}
```

**`notation_frame` is required.**
- `player_relative`: `forward` / `back` are always from the character's
  perspective; the consumer **MUST** mirror direction arrows when the
  character faces left.
- `stick_absolute`: directions are absolute stick positions (e.g. `left`
  and `right` are literal); no mirroring needed.
- `mixed_explicit`: expression nodes carry the disambiguation on the
  `direction` node's `relative` boolean; consumers **MUST** honour it
  per node.

Consumers **MUST** tolerate unknown `notation_frame` values by treating
them as `player_relative`.

---

## 5. `attribution`

```json
{
  "primary_source": {
    "name": "StrategyWiki",
    "url": "https://strategywiki.org/wiki/…",
    "version": null,
    "license": "CC BY-SA 4.0",
    "notes": "Movelists compiled by …"
  },
  "additional_sources": [
    { "name": "SNK Fandom",  "url": "…", "role": "context_only", "notes": null },
    { "name": "MAME",         "url": null, "role": "metadata",    "notes": null }
  ],
  "display_text": "Move data from StrategyWiki (https://…). Licensed under CC BY-SA 4.0. …"
}
```

- Consumers **MUST** render `display_text` verbatim (line breaks allowed)
  in any UI surface that displays the profile data — this satisfies the
  attribution requirement of the primary source's license.
- `additional_sources[].role` is one of `secondary_facts`, `context_only`,
  `metadata`.
- `primary_source.url`, `version`, `license`, `notes` may each be `null`.

---

## 6. `buttons` and `button_groups`

```json
"buttons": [
  { "symbol": "A", "label": "A (Weak)" },
  { "symbol": "B", "label": "B (Strong)" }
],
"button_groups": [
  { "symbol": "AB", "label": "A + B", "members": ["A", "B"] }
]
```

- Every `button.symbol` referenced by `expression.kind == "button"` in
  the profile **MUST** resolve either to a `buttons[].symbol` or to a
  `button_groups[].symbol`. Consumers **SHOULD** display groups as a
  single icon or as their `label`.

---

## 7. `characters`

```json
[
  { "id": "terry",   "name": "Terry Bogard" },
  { "id": "andy",    "name": "Andy Bogard" }
]
```

- `id` is opaque and stable. Every `move.character_id` (when non-null)
  **MUST** resolve to a `characters[].id`.

---

## 8. `moves`

```jsonc
{
  "id": "kof-r2/terry/power-wave",       // globally unique within the profile
  "character_id": "terry",               // MAY be null (system-level moves)
  "name": "Power Wave",
  "aliases": ["Burn Knuckle low"],       // optional
  "category": "special_move",            // §8.1
  "gauge": null,                         // free-text gauge/meter hint, or null
  "source_raw": "236 + A",               // verbatim snippet from source — fallback
  "source_dialect": "training_notation", // optional hint (see §11)
  "activation": { "kind": "by_player_input" },  // §8.2
  "input_expressions": [ … ],            // §8.3
  "annotations": [ … ],                  // §8.4 — optional
  "follow_ups": [ … ]                    // §8.5 — optional
}
```

### 8.1 `category`

Enum: `normal`, `command_normal`, `throw`, `special`, `super`,
`desperation`, `super_desperation`, `climax`, `movement`, `system`,
`cheat`, `info`, `unknown`.

Consumers **MUST** tolerate unknown values by treating them as
`unknown`.

### 8.2 `activation`

```jsonc
{
  "kind": "by_player_input" | "automatic_after_move" | "contextual_trigger" | "unknown",
  "trigger": {                          // required for automatic_/contextual_
    "kind": "on_hit" | "on_mid_hit" | "on_low_hit" | "on_high_hit"
          | "on_wall_hit" | "on_counter_hit" | "on_block"
          | "on_landing" | "on_wakeup" | "on_activation"
          | "near_wall" | "custom",
    "parent_move_id": "kof-r2/terry/…",   // required when kind == "automatic_after_move"
    "description": "…"                    // optional
  },
  "description": "…"                     // optional
}
```

**Invariants:**

- If `activation.kind == "by_player_input"`, the move **MUST** have at
  least one `input_expressions[]` entry.
- If `activation.kind == "automatic_after_move"`, then:
  - `input_expressions` MAY be absent or empty (the move fires without
    player input);
  - `activation.trigger.parent_move_id` **MUST** be present and
    resolve to another `moves[].id` in the same profile.
- If `activation.kind == "contextual_trigger"`, then `activation.trigger`
  **MUST** be present with either a `kind` or a `description`.
- If `activation.kind == "unknown"`, the consumer **SHOULD** display the
  raw `source_raw` and any `description` verbatim.

Consumers **MUST** tolerate unknown values of `activation.kind` and
`trigger.kind` — treat as `unknown` and fall back to `source_raw`.

### 8.3 `input_expressions[]`

Each entry is an **input wrapper**:

```jsonc
{
  "parse_status": "parsed" | "partial" | "unparsed",
  "expression": { … },        // absent when parse_status == "unparsed"
  "source_raw": "236 + A"     // raw notation snippet from the source
}
```

Rules:
- `parse_status == "parsed"`: `expression` is a fully structured tree; no
  descendant node is a `fallback` and no descendant wrapper carries
  `parse_status == "partial"`. Consumers **SHOULD** prefer structured
  rendering (see §9).
- `parse_status == "partial"`: `expression` is present but contains at
  least one `fallback` node. Consumers **SHOULD** render structured
  where possible, and use the fallback branch's `source_raw` where the
  parse could not proceed.
- `parse_status == "unparsed"`: `expression` is absent. `source_raw`
  **MUST** be present. Consumers **MUST** display `source_raw` verbatim
  (monospace recommended) — do **NOT** synthesise structured output.

### 8.4 `annotations[]`

```jsonc
[
  { "kind": "hit_property",     "value": "overhead", "description": null },
  { "kind": "guard_property",   "value": "unblockable" },
  { "kind": "damage_modifier",  "value": "×1.5" },
  { "kind": "stock_cost",       "value": "1" },
  { "kind": "positioning",      "value": "switches sides" },
  { "kind": "custom",           "value": null, "description": "Chip damage on block." }
]
```

`annotation.kind` is one of `hit_property`, `damage_modifier`,
`stock_cost`, `guard_property`, `positioning`, `custom`.
- For `hit_property` the `value` MUST be one of `high, mid, low,
  overhead, reverse_high, reverse_mid, reverse_low, unblockable, throw,
  counter_hit_only, air_only`.
- For `guard_property` the `value` MUST be one of `high, mid, low,
  unblockable, throw`.
- Other kinds carry a free-form `value` (any JSON) and/or a
  `description` string.

Consumers **MUST** tolerate unknown `kind`s and unknown enum `value`s
by rendering `description` (or the raw `value` as text).

### 8.5 `follow_ups[]`

```jsonc
[ { "move_id": "kof-r2/terry/…", "relation": "cancel" | "chain" | "follow_up" | "variant" | "extension" } ]
```

`relation` is optional; when present, unknown values MUST be tolerated
by treating the follow-up as a plain reference.

Every `move_id` **MUST** resolve to another `moves[].id` in the same
profile.

---

## 9. Expression trees

An `expression` is a discriminated union on `kind`. The 14 kinds are:

| kind | shape |
| --- | --- |
| `button` | `{ "kind":"button", "symbol":"A" }` — `symbol` MUST resolve in §6. |
| `direction` | `{ "kind":"direction", "direction": <dir>, "relative": <bool>? }` where `<dir>` ∈ `neutral, forward, back, up, down, up_forward, up_back, down_forward, down_back, any`. |
| `motion` | `{ "kind":"motion", "shape": <motion> }` where `<motion>` ∈ `quarter_circle_forward, quarter_circle_back, half_circle_forward, half_circle_back, dragon_punch_forward, dragon_punch_back, reverse_dragon_punch_forward, reverse_dragon_punch_back, full_circle, double_quarter_circle_forward, double_quarter_circle_back, pretzel_forward, pretzel_back`. |
| `neutral` | `{ "kind":"neutral" }` — return stick to neutral. |
| `sequence` | `{ "kind":"sequence", "steps": [Expr, …] }` — ordered, min 1. |
| `alternative` | `{ "kind":"alternative", "options": [Expr, …] }` — any-of, min 2. |
| `simultaneous` | `{ "kind":"simultaneous", "inputs": [Expr, …] }` — concurrent (e.g. `A + B`), min 2. |
| `charge` | `{ "kind":"charge", "charge_direction": <dir>, "duration_ms": <int>?, "then": Expr }`; `charge_direction` ∈ `back, down, down_back, forward, down_forward`. |
| `hold` | `{ "kind":"hold", "input": Expr, "duration_ms": <int>? }` |
| `release` | `{ "kind":"release", "input": Expr }` |
| `repeat` | `{ "kind":"repeat", "input": Expr, "count": <int>, "mash": <bool> }` |
| `contextual` | `{ "kind":"contextual", "input": Expr, "requirements": [Req, …] }` |
| `optional` | `{ "kind":"optional", "input": Expr }` |
| `fallback` | `{ "kind":"fallback", "source_raw": "…" }` |

**Requirements** (used in `contextual.requirements`):

```jsonc
{
  "kind": "state" | "spatial" | "phase" | "stance" | "custom",
  "value": "airborne" | "in_corner" | "on_wakeup" | …,
  "description": "…"                              // free-text override
}
```

Full lists of `value`s are enumerated in `schema.json`. Consumers
**MUST** tolerate unknown `kind`/`value` combinations by falling back
to `description` or the token literal.

### 9.1 Recommended renderers

The bundle ships a reference rendering (`rendering-samples.json`) for
each of these six output formats:

- **numpad** — e.g. `236 A`, `[db]~f B`, `2A | 5B`.
- **classic 2D** — e.g. `QCF + A`, `charge db, f + B`.
- **icon tokens** — a structured list; each token is one of
  `{ type: "button"|"direction"|"motion"|"neutral"|"charge"|"repeat"|"fallback"|… }`.
- **accessible English** — natural sentences, screen-reader friendly.
- **accessible French** — natural sentences, screen-reader friendly.
- **activation hint** — one-liner describing non-`by_player_input`
  activations.

Consumers may implement their own renderers; the reference outputs are
provided for smoke-testing.

**Fallback rule:** Any `fallback` node **MUST** be rendered as its
`source_raw` in monospace font. Accessible renderers **MUST** prefix
the value with `"unclear notation:"` (English) / `"notation non parsée :"`
(French) so screen readers do not vocalise raw notation as speech.

**Player-relative rule:** When `applies_to.notation_frame == "player_relative"`,
consumers rendering visual arrows **MUST** mirror `forward` and `back`
(and their diagonals) when the character is facing left.

---

## 10. Versioning and forward compatibility

- The contract version follows semver on `gold_schema_version`.
- **1.x.y** is backwards compatible: additions may appear as new
  optional top-level fields, new enum values, new expression `kind`s,
  new annotation `kind`s. Consumers **MUST**:
  - ignore unknown top-level fields;
  - treat unknown `activation.kind`, `activation.trigger.kind`,
    `expression.kind`, `annotation.kind`, `requirement.kind`,
    `requirement.value`, `follow_ups[].relation`, `move.category` values
    as `unknown` — never raise;
  - fall back to `source_raw` whenever a structured branch is unknown
    or malformed.
- A **major** bump (2.0.0) may introduce breaking changes. Bundles
  produced under 2.x will have `gold_schema_version: "2.x.y"` and MAY
  be rejected by 1.x consumers.
- Consumers **MUST** verify `gold_schema_version` starts with `"1."`
  before parsing. Otherwise they **MUST** refuse to load and surface a
  "please update the app" message.

---

## 11. Notation dialect hints

Moves and (in a partial parse) fallback branches MAY carry a
`source_dialect` string. It is a curator hint identifying the source's
notation dialect, e.g. `training_notation`, `strategywiki`,
`arcade_notation`, `command_dat`. Consumers **MAY** use it to select
the right monospace glyph set or tooltip. Unknown values are safe to
display as-is.

---

## 12. Determinism and reproducibility

For a given Silver input, build id and `generated_at` timestamp, the
generated `profile.json` is byte-identical. Consumers can therefore
pin builds by SHA-256 (see `manifest.json`).

---

## 13. Refusal conditions

Consumers **MUST** refuse to load a profile when any of the following
holds:
- `gold_schema_version` does not start with `"1."`.
- `profile.json`'s SHA-256 does not match the manifest entry.
- A `move.character_id` does not resolve to a declared character.
- A `follow_ups[].move_id` does not resolve to a declared move.
- An `activation.kind == "automatic_after_move"` move has no
  resolvable `trigger.parent_move_id`.
- A wrapper with `parse_status == "unparsed"` has no `source_raw`.

Refusal **SHOULD** be surfaced as a user-actionable error including
the offending move id.

---

## 14. Minimal integration checklist

1. Download the bundle folder.
2. Read `manifest.json`. Verify `contract.version` starts with `"1."`.
3. Verify SHA-256 of every file listed in `manifest.files[]`.
4. Load `profile.json`.
5. Optionally load `schema.json` and validate `profile.json` against it
   (JSON Schema Draft 2020-12) — recommended for defensive consumers.
6. Index `buttons[].symbol` ∪ `button_groups[].symbol`, `characters[].id`,
   `moves[].id`.
7. For each move, choose a renderer per §9.1. Fall back to
   `source_raw` when in doubt.
8. Display `attribution.display_text` verbatim at least once per
   session on any surface using the data.

That's it. No repository access, no live services required.
