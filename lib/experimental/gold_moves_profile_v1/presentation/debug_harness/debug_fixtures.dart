/// Debug-only fixture profiles inlined so the harness screen does not
/// need any Flutter asset entry or Firestore access.
///
/// The two example profiles are copies of the shipped Gold bundle
/// examples (SHA-256 verified in `checksum_test.dart`).
///
/// [kofR2ShowcaseProfileJson] is a hand-crafted, minimal profile that
/// re-uses 5 real KOF R-2 moves so the harness can demonstrate:
/// - a plain motion+button move (Aragami)
/// - a contextual throw with alternative options (Hatsugane)
/// - a charge with a hold on the release button (Musasabi no Mai)
/// - two automatic follow-ups linked to Kyo's Nue Tumi (Arashin,
///   Migiri Ugachi low)
/// - the parent Nue Tumi so the follow-up links resolve
library;

const String minimalProfileJson = r'''
{
  "gold_schema_version": "1.0.0",
  "silver_schema_version": "0.2.0",
  "id": "ngpc-kofr2-v2.example-minimal",
  "profile_revision": 1,
  "applies_to": {
    "game_id": "ngpc-kofr2",
    "platform": "neogeo_pocket_color",
    "region": "world",
    "rom_ids": ["kofr2", "kofr2d", "kofr2d2"],
    "notation_frame": "player_relative"
  },
  "attribution": {
    "primary_source": {
      "name": "strategywiki-kofr2-moves",
      "url": "https://strategywiki.org/wiki/King_of_Fighters_R-2/Moves",
      "version": "2024-10-11",
      "license": "CC BY-SA 4.0",
      "notes": "Sole factual source."
    },
    "additional_sources": [],
    "display_text": "Move data from strategywiki-kofr2-moves. Licensed under CC BY-SA 4.0."
  },
  "buttons": [
    { "symbol": "A", "label": "Weak Punch" },
    { "symbol": "B", "label": "Weak Kick" },
    { "symbol": "C", "label": "Strong Punch" },
    { "symbol": "D", "label": "Strong Kick" }
  ],
  "button_groups": [
    { "symbol": "P", "label": "Any Punch", "members": ["A", "C"] },
    { "symbol": "K", "label": "Any Kick", "members": ["B", "D"] }
  ],
  "characters": [
    { "id": "ngpc-kofr2-kyo", "name": "Kyo Kusanagi" }
  ],
  "moves": [
    {
      "id": "ngpc-kofr2-kyo-throw-hatsugane",
      "name": "Hatsugane",
      "category": "throw",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "(close) Left or Right + Punch",
      "activation": { "kind": "by_player_input" },
      "input_expressions": [
        {
          "parse_status": "parsed",
          "expression": {
            "kind": "contextual",
            "requirements": [{ "kind": "spatial", "value": "near_opponent" }],
            "input": {
              "kind": "alternative",
              "options": [
                { "kind": "sequence", "steps": [
                  { "kind": "direction", "direction": "back", "relative": true },
                  { "kind": "button", "symbol": "P" }
                ]},
                { "kind": "sequence", "steps": [
                  { "kind": "direction", "direction": "forward", "relative": true },
                  { "kind": "button", "symbol": "P" }
                ]}
              ]
            }
          }
        }
      ]
    }
  ]
}
''';

const String activationAutomaticProfileJson = r'''
{
  "gold_schema_version": "1.0.0",
  "silver_schema_version": "0.2.0",
  "id": "ngpc-kofr2-v2.example-activation",
  "profile_revision": 1,
  "applies_to": {
    "game_id": "ngpc-kofr2",
    "platform": "neogeo_pocket_color",
    "region": "world",
    "rom_ids": ["kofr2"],
    "notation_frame": "player_relative"
  },
  "attribution": {
    "primary_source": {
      "name": "strategywiki-kofr2-moves",
      "url": "https://strategywiki.org/wiki/King_of_Fighters_R-2/Moves",
      "license": "CC BY-SA 4.0"
    },
    "display_text": "Move data from strategywiki-kofr2-moves. Licensed under CC BY-SA 4.0."
  },
  "buttons": [
    { "symbol": "A", "label": "Weak Punch" },
    { "symbol": "B", "label": "Weak Kick" },
    { "symbol": "C", "label": "Strong Punch" },
    { "symbol": "D", "label": "Strong Kick" }
  ],
  "button_groups": [
    { "symbol": "P", "label": "Any Punch", "members": ["A", "C"] }
  ],
  "characters": [
    { "id": "ngpc-kofr2-kyo", "name": "Kyo Kusanagi" }
  ],
  "moves": [
    {
      "id": "ngpc-kofr2-kyo-spc-nue-tumi",
      "name": "910 Shiki: Nue Tumi",
      "category": "special",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "QCB + P",
      "activation": { "kind": "by_player_input" },
      "input_expressions": [
        {
          "parse_status": "parsed",
          "expression": {
            "kind": "sequence",
            "steps": [
              { "kind": "motion", "shape": "quarter_circle_back" },
              { "kind": "button", "symbol": "P" }
            ]
          }
        }
      ],
      "follow_ups": [
        { "move_id": "ngpc-kofr2-kyo-spc-arashin", "relation": "follow_up" }
      ]
    },
    {
      "id": "ngpc-kofr2-kyo-spc-arashin",
      "name": "Arashin",
      "category": "special",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "(Mid Hit — automatic)",
      "activation": {
        "kind": "automatic_after_move",
        "trigger": {
          "kind": "on_mid_hit",
          "description": "(Mid Hit — automatic)",
          "parent_move_id": "ngpc-kofr2-kyo-spc-nue-tumi"
        }
      }
    }
  ]
}
''';

/// Hand-picked showcase using real KOF R-2 move data structures (5 moves).
///
/// This is a synthetic profile: only the essential shapes needed for
/// the harness are included. The full KOF R-2 profile stays in the
/// test fixtures folder.
const String kofR2ShowcaseProfileJson = r'''
{
  "gold_schema_version": "1.0.0",
  "silver_schema_version": "0.2.0",
  "id": "ngpc-kofr2-v2.debug-showcase",
  "profile_revision": 1,
  "applies_to": {
    "game_id": "ngpc-kofr2",
    "platform": "neogeo_pocket_color",
    "region": "world",
    "rom_ids": ["kofr2"],
    "notation_frame": "player_relative"
  },
  "attribution": {
    "primary_source": {
      "name": "strategywiki-kofr2-moves",
      "url": "https://strategywiki.org/wiki/King_of_Fighters_R-2/Moves",
      "license": "CC BY-SA 4.0",
      "notes": "StrategyWiki contributors."
    },
    "additional_sources": [
      { "name": "snk-wiki-kofr2", "url": null, "role": "context_only" }
    ],
    "display_text": "Move data from StrategyWiki (King of Fighters R-2/Moves). Licensed under CC BY-SA 4.0. Attribution: StrategyWiki contributors."
  },
  "buttons": [
    { "symbol": "A", "label": "Weak Punch (A)" },
    { "symbol": "B", "label": "Weak Kick (B)" },
    { "symbol": "C", "label": "Strong Punch (C)" },
    { "symbol": "D", "label": "Strong Kick (D)" }
  ],
  "button_groups": [
    { "symbol": "P", "label": "Any Punch", "members": ["A", "C"] },
    { "symbol": "K", "label": "Any Kick", "members": ["B", "D"] }
  ],
  "characters": [
    { "id": "ngpc-kofr2-kyo", "name": "Kyo Kusanagi" },
    { "id": "ngpc-kofr2-mai", "name": "Mai Shiranui" }
  ],
  "moves": [
    {
      "id": "ngpc-kofr2-kyo-spc-aragami",
      "name": "114 Shiki: Aragami",
      "category": "special",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "QCF + A",
      "activation": { "kind": "by_player_input" },
      "input_expressions": [
        {
          "parse_status": "parsed",
          "expression": {
            "kind": "sequence",
            "steps": [
              { "kind": "motion", "shape": "quarter_circle_forward" },
              { "kind": "button", "symbol": "A" }
            ]
          }
        }
      ]
    },
    {
      "id": "ngpc-kofr2-kyo-throw-hatsugane",
      "name": "Hatsugane",
      "category": "throw",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "(close) Left or Right + P",
      "activation": { "kind": "by_player_input" },
      "input_expressions": [
        {
          "parse_status": "parsed",
          "expression": {
            "kind": "contextual",
            "requirements": [{ "kind": "spatial", "value": "near_opponent" }],
            "input": {
              "kind": "alternative",
              "options": [
                { "kind": "sequence", "steps": [
                  { "kind": "direction", "direction": "back", "relative": true },
                  { "kind": "button", "symbol": "P" }
                ]},
                { "kind": "sequence", "steps": [
                  { "kind": "direction", "direction": "forward", "relative": true },
                  { "kind": "button", "symbol": "P" }
                ]}
              ]
            }
          }
        }
      ]
    },
    {
      "id": "ngpc-kofr2-mai-spc-musasabi-no-mai-chijou",
      "name": "Musasabi no Mai (Chijou)",
      "category": "special",
      "character_id": "ngpc-kofr2-mai",
      "source_raw": "charge d, u + P (hold)",
      "activation": { "kind": "by_player_input" },
      "input_expressions": [
        {
          "parse_status": "parsed",
          "expression": {
            "kind": "charge",
            "charge_direction": "down",
            "duration_ms": null,
            "then": {
              "kind": "sequence",
              "steps": [
                { "kind": "direction", "direction": "up", "relative": true },
                { "kind": "hold", "input": { "kind": "button", "symbol": "P" }, "duration_ms": null }
              ]
            }
          }
        }
      ]
    },
    {
      "id": "ngpc-kofr2-kyo-spc-nue-tumi",
      "name": "910 Shiki: Nue Tumi",
      "category": "special",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "QCB + P",
      "activation": { "kind": "by_player_input" },
      "input_expressions": [
        {
          "parse_status": "parsed",
          "expression": {
            "kind": "sequence",
            "steps": [
              { "kind": "motion", "shape": "quarter_circle_back" },
              { "kind": "button", "symbol": "P" }
            ]
          }
        }
      ],
      "follow_ups": [
        { "move_id": "ngpc-kofr2-kyo-spc-arashin", "relation": "follow_up" },
        { "move_id": "ngpc-kofr2-kyo-spc-migiri-ugachi-low", "relation": "follow_up" }
      ]
    },
    {
      "id": "ngpc-kofr2-kyo-spc-arashin",
      "name": "Arashin",
      "category": "special",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "(Mid Hit — automatic)",
      "activation": {
        "kind": "automatic_after_move",
        "trigger": {
          "kind": "on_mid_hit",
          "description": "(Mid Hit — automatic)",
          "parent_move_id": "ngpc-kofr2-kyo-spc-nue-tumi"
        }
      }
    },
    {
      "id": "ngpc-kofr2-kyo-spc-migiri-ugachi-low",
      "name": "Ge-Shiki: Migiri Ugachi (low)",
      "category": "special",
      "character_id": "ngpc-kofr2-kyo",
      "source_raw": "(Low Hit — automatic)",
      "activation": {
        "kind": "automatic_after_move",
        "trigger": {
          "kind": "on_low_hit",
          "description": "(Low Hit — automatic)",
          "parent_move_id": "ngpc-kofr2-kyo-spc-nue-tumi"
        }
      }
    }
  ]
}
''';
