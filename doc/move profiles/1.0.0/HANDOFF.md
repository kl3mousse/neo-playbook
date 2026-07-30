# Handoff — ComboFox Moves Profile (Gold v1.0.0), Dataset `ngpc-kofr2`

This document is the copy-paste briefing for the downstream team
(e.g. the Flutter agent) that will integrate the Gold Moves Profile
into a runtime application. It is self-contained: the Flutter agent
does **not** need to read the source repository.

---

## 1. What you receive

A bundle folder (checked into `data/4. gold/moves-profile/v1.0.0/bundles/ngpc-kofr2/<build_id>/`)
containing:

| File | Purpose |
| --- | --- |
| `profile.json` | The Gold Moves Profile for KOF R-2 (NGPC). Runtime artefact. |
| `schema.json` | JSON Schema Draft 2020-12 for Gold Moves Profile v1.0.0. |
| `CONSUMER_SPEC.md` | Full consumer specification. Read this before integrating. |
| `HANDOFF.md` | This file. |
| `examples/*.profile.json` | Minimal Gold-valid examples for tests. |
| `rendering-samples.json` | Reference renderings for representative moves. |
| `manifest.json` | Contract version, dataset id, build id, counts, SHA-256 checksums. |

## 2. Contract

- **Contract name:** `combofox-moves-profile`
- **Contract version:** `1.0.0`
- **Gold schema version:** `1.0.0`
- **Silver schema version (upstream):** `0.2.0`

Semver: 1.x.y is backwards-compatible. 2.x may break. Consumers **MUST**
verify `gold_schema_version` starts with `"1."` before loading.

## 3. Dataset

- **Dataset id:** `ngpc-kofr2`
- **Platform:** `ngpc` (Neo Geo Pocket Color)
- **ROM ids:** `kofr2`
- **Region:** `world`
- **Notation frame:** `player_relative` (mirror directions when facing left)

## 4. Counts (KOF R-2, this build)

- 23 characters, 289 moves.
- Parse status: 286 parsed, 0 partial, 0 unparsed, 3 activation-only
  (automatic follow-ups without player input).
- Activations: 3 `automatic_after_move`, 0 `contextual_trigger`,
  286 `by_player_input`.

## 5. Attribution

Render `attribution.display_text` verbatim in the UI at least once per
session on any surface using the data. Primary source is **StrategyWiki**
under **CC BY-SA 4.0**. Additional sources are listed in
`attribution.additional_sources` (roles: `context_only`, `metadata`).

## 6. Integration checklist

1. Copy the bundle folder into the app assets (or download at runtime).
2. Read `manifest.json`. Verify `contract.version` starts with `"1."`.
3. Verify SHA-256 of every file in `manifest.files[]` matches.
4. Load `profile.json`.
5. Optional but recommended: validate `profile.json` against `schema.json`
   with a JSON Schema Draft 2020-12 validator.
6. Index buttons, button groups, characters, moves by id.
7. Implement renderers per `CONSUMER_SPEC.md` §9. Six reference outputs
   are provided in `rendering-samples.json`:
   - `numpad` (e.g. `236 A`),
   - `classic_2d` (e.g. `QCF + A`),
   - `icon_tokens` (structured list),
   - `accessible_en` (English screen-reader text),
   - `accessible_fr` (French screen-reader text),
   - `activation_hint_en` (English one-liner for non-`by_player_input`).
8. Render `attribution.display_text` in the credits panel.

## 7. Rendering & accessibility rules (see `CONSUMER_SPEC.md` §9 for details)

- `parse_status == "parsed"` → structured rendering.
- `parse_status == "partial"` → structured where possible, fall back to
  the `fallback` node's `source_raw` where the parse stopped.
- `parse_status == "unparsed"` → display `source_raw` verbatim in monospace;
  do NOT synthesise structured text. Accessible renderers **MUST** prefix
  with `"unclear notation:"` (English) / `"notation non parsée :"` (French).
- `activation.kind != "by_player_input"` → show the activation hint
  alongside (or instead of) the input notation. For `automatic_after_move`,
  link to the parent move.
- Player-relative directions **MUST** be mirrored visually when the
  character faces left.

## 8. Forward compatibility (MUST-honour rules)

- Ignore unknown top-level fields.
- Treat unknown `activation.kind`, `activation.trigger.kind`,
  `expression.kind`, `annotation.kind`, `requirement.kind`,
  `requirement.value`, `follow_ups[].relation`, `move.category` values
  as `unknown` — never raise.
- Fall back to `source_raw` (move-level or wrapper-level) whenever a
  structured branch is unknown or malformed.

## 9. Refusal conditions (from CONSUMER_SPEC §13)

Refuse to load and surface a user-actionable error if:
- `gold_schema_version` does not start with `"1."`, or
- any file's SHA-256 does not match the manifest, or
- a `move.character_id`, `follow_ups[].move_id` or
  `activation.trigger.parent_move_id` reference does not resolve, or
- a wrapper with `parse_status == "unparsed"` has no `source_raw`.

## 10. What NOT to do

- Do **NOT** read the ComboFox source repository. The bundle is the
  entire contract.
- Do **NOT** synthesise input notations for `parse_status == "unparsed"`
  moves. Use `source_raw` verbatim.
- Do **NOT** rewrite or "clean up" `attribution.display_text` — it is
  the license credit.
- Do **NOT** treat moves as a set. Preserve the array order — it is the
  editorial ordering.

## 11. Known limits (v1.0.0, KOF R-2 build)

- 3 moves are `automatic_after_move` follow-ups without player input.
  They rely on their parent move to be executed.
- Charge notations use `duration_ms` (nullable). When null, choose a
  sensible default UI hint (e.g. "hold ~1 s").
- The `source_dialect` field on moves is informational; consumers may
  ignore it.

## 12. Retrieval commands (for pipeline operators — NOT for the Flutter agent)

The Gold pipeline is invoked from the source repository as follows.
The Flutter agent does **not** need to run these — they produce the
bundle that is handed off.

```sh
# From the repo root, with the .venv activated:
python3 "data/4. gold/moves-profile/v1.0.0/build_from_silver.py" \
    "data/3. silver/moves-profiles/examples/v0.2.0/ngpc/kofr2.profile.json" \
    /tmp/kofr2.gold.json --at "2026-07-29T00:00:00Z"

python3 "data/4. gold/moves-profile/v1.0.0/validate.py" /tmp/kofr2.gold.json

python3 "data/4. gold/moves-profile/v1.0.0/build_bundle.py" \
    --silver "data/3. silver/moves-profiles/examples/v0.2.0/ngpc/kofr2.profile.json" \
    --dataset-id ngpc-kofr2 \
    --build-id 2026-07-29 \
    --generated-at 2026-07-29T00:00:00Z
```

## 13. Publication note

This bundle is delivered as **files inside the Git repository**
(under `data/4. gold/moves-profile/v1.0.0/bundles/`). It is **not**
pushed to Firebase Firestore by this build. The existing Firestore
publication pipeline (`data/4. gold/combofox-firestore/`) is unaffected
and continues to serve the pre-existing `games`, `command_dat` and
`dip_settings` collections. If future work requires Firestore
publication of Gold Moves Profiles, it would be added as a new
collection alongside them.

For push to production Firestore, credentials at
`data/4. gold/combofox-firestore/firebase-serviceaccount.json` are
required and are **not** present in this environment. Publication is
therefore prepared as artefacts only.

## 14. Test evidence

Silver v0.2.0 tests: 71+ pass (unchanged).
Gold v1.0.0 tests: 29 pass (`data/4. gold/moves-profile/v1.0.0/test_gold.py`).

Deterministic bundle: two consecutive builds with identical
`--generated-at` produce byte-identical files (verified in
`TestBundle.test_bundle_reproducible`).
