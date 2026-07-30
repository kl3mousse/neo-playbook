# Spike — Gold Moves Profile v1.0.0 in Flutter (ComboFox)

> Spike scope: prove that Gold Moves Profile v1.0.0 can be reliably parsed,
> rendered, made accessible and disambiguated (player command vs automatic
> activation) inside a ComboFox-styled Flutter widget layer, without
> replacing production move lists yet.
>
> Bundle verified: `doc/move profiles/1.0.0/` — 7 files, SHA-256 checksums
> all match (`profile.json`, `schema.json`, `CONSUMER_SPEC.md`, `HANDOFF.md`,
> `examples/minimal.profile.json`, `examples/activation-automatic.profile.json`,
> `rendering-samples.json`).

## 1. Architecture retenue

The spike lives entirely under `lib/experimental/gold_moves_profile_v1/`
and is not imported by any production screen. It is organised into four
strictly ordered folders:

- `domain/` — pure Dart, no Flutter, sealed unions, enums with `.wire`
  strings, no `Map<String, dynamic>` leaks.
- `parsing/` — JSON → `domain/` with JSON-pointer errors
  (`GoldParseException { message, path, rawValue }`), version + reference
  validation, forward-compat unknown handling; SHA-256 utility.
- `rendering/` — Flutter-independent intermediate representation
  (`RenderToken`) plus six pure renderers: `NumpadRenderer`,
  `Classic2dRenderer`, `IconTokensRenderer`, `AccessibleEnRenderer`,
  `AccessibleFrRenderer`, `ActivationHintRenderer`.
- `presentation/` — Flutter widgets (`GoldInputRow`, `GoldMoveCard`,
  `GoldProvenanceView`) and a `kDebugMode`-gated harness
  (`GoldMovesHarnessScreen` at `/debug/gold-moves-profile-v1`).

Public entry point: `gold_moves_profile.dart` (barrel). Only test code
and the debug harness import it. Production code is unchanged; the only
production-facing edit is a single import + one line
`...buildGoldHarnessRoutes()` added to `lib/router.dart`, which returns
`const []` when `kDebugMode == false`. No Firestore, no shared prefs,
no assets pipeline touched.

Rationale: keep the whole spike in a single tree so it can be deleted
in a single commit if we choose No-Go; keep parsing and rendering pure
Dart so they can later move to a `packages/gold_moves_profile/` package
if we choose Go.

## 2. Inventaire exact des fichiers du bundle

| File | SHA-256 | Status |
|------|---------|--------|
| `profile.json` | `5e1b2f8597929502470e4b0b19492142fa5b85d07a8875c95ef4133cdee94b24` | ✅ |
| `schema.json` | `206dd174689fe4864c911ed2f35c1dc694e375eb72545d678074a6f0466be8fd` | ✅ |
| `CONSUMER_SPEC.md` | `87c71490afeee6f932525b89ab5168b8722c1156ffaba80908297219de8af9a0` | ✅ |
| `HANDOFF.md` | `e3d505aa6799e20bd47b332d97e5c7d79020d21ed3c256e875d44491adb5e25a` | ✅ |
| `examples/minimal.profile.json` | `eec3c1491d3e6debc6d7b71487f7bdc0c9429045664a28c162020f68630c3a3f` | ✅ |
| `examples/activation-automatic.profile.json` | `f60d274e9dc3820b5d2ee238639f0e627491d3af588130066d332fb26df5d120` | ✅ |
| `rendering-samples.json` | `1b6c765d40b17579d3022c7bdea3700737c852b8ffde684ba31bfbcb29a986cd` | ✅ |

Checksums re-computed at test time (`checksum_test.dart`, 7 tests, all
green).

## 3. Couverture du contrat Gold

Every discriminant defined in `schema.json` §Expression and §Activation
is either a concrete sealed subclass or explicitly tolerated as an
`unknown` variant:

- **Expressions** — 14 typed variants: `neutral`, `direction`, `button`,
  `motion`, `charge`, `sequence`, `simultaneous`, `alternative`, `hold`,
  `release`, `repeat`, `optional`, `contextual`, `fallback` — plus
  `UnknownExpression` for any future `kind`.
- **Motion shapes** — 13 typed enum values (`quarter_circle_*`, `dp*`,
  `rdp*`, `360`, `double_qcf/qcb`, `half_circle_*`, `half_circle_up`).
  Unknown shapes are downgraded to `UnknownExpression` so a strict switch
  is impossible to write silently.
- **Requirements** — 5 kinds (`state`, `spatial`, `phase`, `stance`,
  `custom`) with raw string preserved.
- **Activation** — 3 kinds (`by_player_input`, `automatic_after_move`,
  `contextual_trigger`) plus `unknown`.
- **Triggers** — 11 kinds (`on_hit`, `on_mid_hit`, `on_low_hit`,
  `on_block`, `on_air_hit`, `on_activation`, `on_link_window`,
  `on_button_press`, `on_release`, `on_super_freeze`, `on_stagger`,
  `custom`) plus `unknown`.
- **Follow-up relation** — `follow_up`, `alternative`, `sequel`,
  `context_menu`, plus `unknown`.
- **Notation frame** — 3 typed values; unknowns fall back to
  `player_relative` while `rawNotationFrame` is preserved (§5).
- **Attribution** — `primary_source`, `additional_sources[]`,
  `display_text` (verbatim), `notes`, `license`, `version`, `url`.
- **Unknown top-level fields** — preserved in
  `ProfileGold.unknownFields`.
- **`parse_status`** — strict, throws on unknown values (used only
  during parse; the resulting typed enum is `parsed | partial |
  unparsed`).

Refusal cases implemented per §13:
1. `gold_schema_version` not starting with `"1."` → immediate refusal
   with actionable message (test: `refuses gold_schema_version=2.0.0`).
2. `by_player_input` without at least one `input_expression` → refusal.
3. `automatic_after_move` without `trigger.parent_move_id` → refusal.
4. `parse_status = "unparsed"` without `source_raw` → refusal.
5. Unresolved `character_id`, `follow_ups[].move_id`,
   `activation.trigger.parent_move_id` → refusal
   (`strictReferences: true`, default).

## 4. Résultats pour KOF R-2 (`profile.json`)

Parsed from the real 289-move bundle (`kof_r2_profile_test.dart`,
14 tests all green):

| Metric | Value |
|--------|-------|
| Characters | **23** |
| Moves | **289** |
| `by_player_input` | **286** |
| `automatic_after_move` | **3** |
| `contextual_trigger` | 0 |
| `parse_status = parsed` | **286** |
| `parse_status = partial` | 0 |
| `parse_status = unparsed` | 0 |
| Moves missing `source_raw` | 0 |
| All move ids unique | ✅ |
| All `character_id` refs resolve | ✅ |
| All `follow_up` refs resolve | ✅ |
| All `parent_move_id` refs resolve | ✅ |
| `notation_frame` | `player_relative` |

Provenance: `strategywiki-kofr2-moves`, license `CC BY-SA 4.0`,
`display_text` preserved verbatim and rendered as-is in
`GoldProvenanceView`.

## 5. Représentation intermédiaire choisie

The IR is a flat `List<RenderToken>` with sealed variants:
`RtMotion`, `RtDirection(value, relative)`, `RtButton(symbol)`,
`RtNeutral`, `RtCharge(chargeDirection, durationMs)`,
`RtHoldStart/HoldEnd`, `RtReleaseStart/ReleaseEnd`,
`RtOptionalStart/OptionalEnd`, `RtRepeatStart(count, mash)/RepeatEnd`,
`RtSimultaneousStart/Separator/End`, `RtAlternative(options)`,
`RtFallback(sourceRaw)`, `RtContextualHint(requirements)`,
`RtUnknown(rawKind)`.

Design decisions:
- **Alternative kept as nested lists**, not flattened, because the six
  renderers each need distinct separators (` | ` for numpad, ` OR ` for
  accessible_en, ` OU ` for accessible_fr). Flattening would lose the
  grouping.
- **Contextual hint lifted to a tail token**, matching
  `rendering-samples.json` for `Hatsugane`. Renderers that produce a
  prose form (accessible_en/fr) then lift it back to a prefix; renderers
  that produce compact input (numpad, classic_2d) drop it.
- **`RenderToken.toJson()`** — direction only emits `relative` when
  explicitly `false`, matching the exact shape of the sample JSON.
- IR is Flutter-independent → can be consumed by CLI tooling, unit
  tests, or a future non-Flutter renderer (e.g. Firestore export).

## 6. Comportement des renderers

All six renderers are byte-exact against `rendering-samples.json` for
the four sample moves (test:
`render_samples_conformance_test.dart`, 6 tests, all green):

| Renderer | Sample | Output |
|----------|--------|--------|
| numpad | Aragami | `236 A` |
| numpad | Hatsugane (contextual alt) | `4 P \| 6 P` |
| numpad | Musasabi (charge+hold) | `[2]~8 P (hold)` |
| classic_2d | Aragami | `qcf + A` |
| accessible_en | Aragami | `quarter circle forward then press A` |
| accessible_en | Hatsugane | `near opponent: press back and P OR press forward and P` |
| accessible_fr | Aragami | `quart de cercle avant puis appuyer sur A` |
| activation_hint_en | Arashin | `"Fires automatically on a mid hit as a follow-up of 'ngpc-kofr2-kyo-spc-nue-tumi'. (Mid Hit — automatic)"` |
| icon_tokens | all | JSON-equal (relative flag omitted when true) |

## 7. Accessibilité et localisation

- `GoldInputRow` wraps its chip `Wrap` in a single
  `Semantics(container: true, label: sentence, excludeSemantics: true)`,
  so screen readers announce **one whole sentence per command**, not per
  pictogram. This directly follows §11 of `CONSUMER_SPEC.md`.
- Two locales are shipped: EN and FR (`GoldLocale.en | fr`). The card
  picks the correct sentence from `AccessibleEnRenderer` or
  `AccessibleFrRenderer`.
- Requirements are translated (spatial `near_opponent` → "close to the
  opponent" / "près de l'adversaire", etc.).
- Widget test `accessible sentence is exposed on the input row`
  confirms the sentence is reachable via `find.bySemanticsLabel`.
- Text scaling to 2.0× keeps the layout valid (widget test).

## 8. Traitement des activations automatiques

Player command vs automatic activation is disambiguated at three levels:

1. **Domain** — `MoveGold.isAutomaticFollowUp` / `isPlayerInput` /
   `hasStructuredInput` helpers.
2. **Rendering** — `ActivationHintRenderer` emits a full sentence in EN
   and FR (`renderEn`, `renderFr`), never a numpad string.
3. **UI** — `GoldMoveCard._automaticBanner()` renders a distinct
   Container with `Icons.autorenew`, secondary accent border, and the
   full activation-hint sentence wrapped in one Semantics label. The
   normal pictogram row is not rendered at all — automatic moves are
   visually and semantically not commands. Widget test
   `renders an automatic follow-up as a banner, never as command` asserts
   the banner is present and no numpad string is on screen.

## 9. Traitement des fallbacks et inconnues

- `parse_status = "unparsed"` → `RtFallback(sourceRaw)`, rendered as a
  monospace orange-bordered chip; the accessible sentence carries the
  raw string preceded by "raw input:" / "entrée brute :".
- Unknown `expression.kind` or unknown `motion.shape` →
  `UnknownExpression(rawKind, rawJson)` → `RtUnknown(rawKind)` chip. The
  parser never produces silently-empty expressions (regression test:
  `unknown expression.kind becomes UnknownExpression, never silently empty`).
- Unknown `activation.kind`, `trigger.kind`, `requirement.kind`,
  `annotation.kind`, `follow_up.relation`, `notation_frame` → typed
  `.unknown` enum plus `rawKind` string. All UI and prose renderers
  degrade gracefully.
- Unknown top-level fields → preserved in `ProfileGold.unknownFields`
  so forward-compatible additions in Gold 1.1.x are not lost.

## 10. Provenance et attribution

`GoldProvenanceView` (widget) is fed straight from
`ProfileGold.attribution`. Rendering rules:
- `primary_source.name` in the card header.
- `role`, `license`, `version` shown as small pills; URL is tappable
  (`launchUrl(uri, mode: LaunchMode.externalApplication)`).
- `additional_sources` listed with role pills.
- **`display_text` shown verbatim** via `SelectableText`, so the
  CC BY-SA 4.0 attribution string demanded by StrategyWiki is copyable
  and unmodified.

Widget test confirms the verbatim `Licensed under CC BY-SA 4.0` string
is present.

## 11. Proposition d'intégration aux écrans actuels

Two integration paths are viable if we choose Go:

- **Path A (recommended for phase 1)** — add a "New format preview"
  card inside the existing `GameDetailScreen` that reads a Gold profile
  from Firestore or bundled assets and renders it via
  `GoldMoveCard` next to the current legacy list. Zero migration
  pressure, users see both, telemetry can compare.
- **Path B (phase 2)** — replace the legacy move rendering entirely for
  games that ship a Gold profile, keeping the current renderer only as
  a fallback for games still on `command.dat`.

Both paths only need:
1. A `MoveProfileSource` abstraction (Firestore doc or bundled asset).
2. A per-game preference: legacy vs Gold.
3. Reuse `GoldMoveCard` / `GoldProvenanceView` verbatim.

The four production `AppColors` used by category chips already cover
all 13 `MoveCategory` values, and the `ArcadePanel` style transfers
cleanly.

## 12. Défauts éventuels du contrat Gold v1.0.0

Real gaps found during the spike (candidates for Gold 1.0.1, listed by
severity):

1. **`rendering-samples.json` is under-specified for `icon_tokens`.**
   The `relative` flag is emitted only when `false`, but the schema
   does not say so. Please make it a normative rule: *"omit `relative`
   when `true` (default), emit `false` explicitly."* Currently
   discovered by trial-and-error.
2. **`RepeatExpr.count` semantics vs `mash: true`.** Schema allows
   `mash: true` with an integer `count`. The spec should clarify that
   `mash: true` implies "as fast as possible" and `count` is a hint,
   not a contract.
3. **`HoldExpr.duration_ms = null`** — unclear whether that means
   "hold until release" or "duration unknown". The KOF R-2 profile uses
   `null` for both. Suggest making the distinction explicit
   (`hold_kind: "until_release" | "unspecified"`).
4. **`ContextualExpr.requirements` typing.** `value` is
   `Object?`. A schema union `string | number | boolean` would make
   deserialisation more predictable across languages.
5. **`AdditionalSource.role`** — the schema enumerates `mirror`,
   `translation`, `secondary`, `derived`, `unknown` in §7, but the
   KOF R-2 bundle uses `mirror` and `frame_data_reference`, the second
   of which is not in the enum. Please either extend the enum or make
   the role a raw string.
6. **`applies_to.rom_ids`** — nullable? The KOF R-2 profile uses it
   but `minimal.profile.json` omits it. The schema is silent.
7. **`Motion.shape` set** — no `full_circle_forward`, no `dragon_punch_back`
   variants beyond `rdp`. Not blocking for KOF R-2 but will be for
   Marvel-style games.
8. **`Attribution.display_text` uniqueness.** Two sources with the same
   `display_text` are indistinguishable when combining profiles. A
   `id` field on `Source` would help downstream merging.

None of the above blocks integration. All are opinions for a 1.0.1
minor.

## 13. Différences entre `CONSUMER_SPEC.md` et l'implémentation

- The spec instructs consumers to preserve `source_raw` on **every**
  move; the KOF R-2 build already does so — nothing to change on our
  side, we only assert it in tests.
- The spec mentions `notation_frame = player_relative` as the default;
  we implement `.playerRelative` as the safe fallback for unknown
  frames while preserving `rawNotationFrame`. That is stricter than the
  spec (which is silent on unknown values) and matches HANDOFF.md §3.
- The spec does not mandate an order for `additional_sources`; we
  preserve editorial order.
- `rendering-samples.json` carries the notice *"outputs are reference,
  not contract"*. We enforce conformance in tests to catch regressions
  but treat it as a *guideline*, not a spec rule.

## 14. Impacts anticipés sur Firestore

If we publish Gold profiles to Firestore:

- Schema shape is close to Firestore idioms (nested maps, arrays of
  maps). No custom converters required if we keep JSON round-tripping.
- `attribution.display_text` is fully static per profile — safe to
  denormalise.
- `moves[]` reaches 289 entries for a single game; a single Firestore
  document is ~a few hundred KB — under the 1 MiB limit but close
  enough that we should consider one document per character (splitting
  `moves` by `character_id`), especially for future games with more
  moves.
- Reference integrity (`character_id`, `follow_ups`, `parent_move_id`)
  currently enforced by the parser. If we split per character we lose
  in-document integrity guarantees and must either (a) validate at
  publish time in a Cloud Function, or (b) accept eventual consistency
  and degrade gracefully.
- `strictReferences: true` requires the whole profile to be loaded at
  once. Splitting per character requires either
  `strictReferences: false` mode (already supported) or a two-pass
  load.
- Existing Firestore security rules are unaffected — the profile is
  read-only user data.

## 15. Coût et risques d'une intégration de production

Estimated work for Path A (preview card):
- Wire a `MoveProfileSource` abstraction: small.
- Move the spike out of `experimental/` and stabilise the public API:
  medium (mostly renaming and docstrings).
- Author profiles for the first 3-5 games: **large** and largely
  editorial, not code.
- Cover 6 renderers with golden tests for the top 30 movesets:
  medium.

Risks:
- Editorial effort of authoring Gold profiles is the dominant cost.
- Localisation currently in-code — a real l10n framework
  (`flutter_localizations` + ARB) would be a prerequisite before
  publishing FR to end users.
- No production screen change was made in this spike, so rollback is a
  single-commit revert.
- `phosphor_flutter` git override is a pre-existing risk unrelated to
  this spike.

## 16. Recommandation Go / No-Go

Distinct decisions per axis:

| Axis | Recommendation | Rationale |
|------|----------------|-----------|
| Intégration écrans production | **Go, phase 1 (preview card only)** | Zero risk, everything already validated, gives us telemetry on Gold rendering next to legacy. |
| Publication Firestore | **Go, but split per character** | Sizing headroom, better security rules granularity; add a Cloud Function to enforce ref integrity. |
| Migration premier lot de jeux | **Go, KOF R-2 first** | Data is already validated end-to-end (289/289 moves parsed, 100% renderable). Pick a second game before extrapolating. |
| Migration progressive des `command.dat` | **No-Go for now** | Requires editorial pipeline (Gold authoring UI) that does not exist yet; and Gold 1.0.1 clarifications on §12 items 2/3/5 should land first. Revisit after 2 games are in production. |
