import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/gold_move_card.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/gold_provenance_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double textScaleFactor = 1.0}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    ),
  );
}

MoveGold _findMove(ProfileGold p, String id) => p.move(id)!;

void main() {
  const parser = ProfileParser();
  late ProfileGold profile;

  setUpAll(() {
    // Uses the debug harness fixtures — no filesystem access.
    profile = parser.parseString(_showcase);
  });

  testWidgets('renders a simple motion+button move', (tester) async {
    final move = _findMove(profile, 'ngpc-kofr2-kyo-spc-aragami');
    await tester.pumpWidget(
      _wrap(GoldMoveCard(move: move, buttons: profile.buttons)),
    );
    expect(find.text('114 Shiki: Aragami'), findsOneWidget);
    // Accessible sentence attached via Semantics.
    expect(find.text('QCF'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('236 A'), findsOneWidget);
  });

  testWidgets('renders a contextual alternative throw with prefix', (
    tester,
  ) async {
    final move = _findMove(profile, 'ngpc-kofr2-kyo-throw-hatsugane');
    await tester.pumpWidget(
      _wrap(GoldMoveCard(move: move, buttons: profile.buttons)),
    );
    expect(find.text('Hatsugane'), findsOneWidget);
    // Numpad output includes the alternative pipe.
    expect(find.text('4 P | 6 P'), findsOneWidget);
    // Requirement chip surfaces the near_opponent constraint.
    expect(find.text('near_opponent'), findsOneWidget);
  });

  testWidgets('renders a charge+hold move (Musasabi)', (tester) async {
    final move = _findMove(
      profile,
      'ngpc-kofr2-mai-spc-musasabi-no-mai-chijou',
    );
    await tester.pumpWidget(
      _wrap(GoldMoveCard(move: move, buttons: profile.buttons)),
    );
    expect(find.text('Musasabi no Mai (Chijou)'), findsOneWidget);
    expect(find.text('[2]~8 P (hold)'), findsOneWidget);
  });

  testWidgets('renders an automatic follow-up as a banner, never as command', (
    tester,
  ) async {
    final move = _findMove(profile, 'ngpc-kofr2-kyo-spc-arashin');
    await tester.pumpWidget(
      _wrap(GoldMoveCard(move: move, buttons: profile.buttons)),
    );
    expect(find.text('Arashin'), findsOneWidget);
    expect(find.byIcon(Icons.autorenew), findsOneWidget);
    expect(
      find.textContaining("follow-up of 'ngpc-kofr2-kyo-spc-nue-tumi'"),
      findsOneWidget,
    );
    // Ensure no numpad-styled input is shown for a non-input move.
    expect(find.text('236 A'), findsNothing);
  });

  testWidgets('renders provenance verbatim with license pill', (tester) async {
    await tester.pumpWidget(
      _wrap(GoldProvenanceView(attribution: profile.attribution)),
    );
    expect(find.text('Attribution & Sources'), findsOneWidget);
    // §5 mandates verbatim display_text.
    expect(find.textContaining('Licensed under CC BY-SA 4.0'), findsOneWidget);
    expect(find.text('license: CC BY-SA 4.0'), findsOneWidget);
  });

  testWidgets('remains laid-out at a high text scale', (tester) async {
    final move = _findMove(profile, 'ngpc-kofr2-kyo-spc-aragami');
    await tester.pumpWidget(
      _wrap(
        GoldMoveCard(move: move, buttons: profile.buttons),
        textScaleFactor: 2.0,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('114 Shiki: Aragami'), findsOneWidget);
  });

  testWidgets('accessible sentence is exposed on the input row', (
    tester,
  ) async {
    final move = _findMove(profile, 'ngpc-kofr2-kyo-spc-aragami');
    await tester.pumpWidget(
      _wrap(GoldMoveCard(move: move, buttons: profile.buttons)),
    );
    expect(
      find.bySemanticsLabel(RegExp('quarter circle forward')),
      findsOneWidget,
      reason: 'Accessible EN sentence should be reachable via Semantics.',
    );
  });

  testWidgets('French locale surfaces French sentence', (tester) async {
    final move = _findMove(profile, 'ngpc-kofr2-kyo-spc-aragami');
    await tester.pumpWidget(
      _wrap(
        GoldMoveCard(
          move: move,
          buttons: profile.buttons,
          locale: GoldLocale.fr,
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('quart de cercle avant')),
      findsOneWidget,
    );
  });
}

// Inline showcase JSON so widget tests don't touch the filesystem.
const _showcase = r'''
{
  "gold_schema_version": "1.0.0","silver_schema_version": "0.2.0",
  "id": "x","profile_revision": 1,
  "applies_to": {"platform":"ngpc","notation_frame":"player_relative"},
  "attribution": {
    "primary_source":{"name":"StrategyWiki","license":"CC BY-SA 4.0",
      "url":"https://strategywiki.org/wiki/King_of_Fighters_R-2/Moves"},
    "display_text":"Move data from StrategyWiki. Licensed under CC BY-SA 4.0. Attribution: StrategyWiki contributors."
  },
  "buttons":[
    {"symbol":"A","label":"Weak Punch"},
    {"symbol":"B","label":"Weak Kick"},
    {"symbol":"C","label":"Strong Punch"},
    {"symbol":"D","label":"Strong Kick"}
  ],
  "button_groups":[
    {"symbol":"P","label":"Any Punch","members":["A","C"]}
  ],
  "characters":[
    {"id":"ngpc-kofr2-kyo","name":"Kyo Kusanagi"},
    {"id":"ngpc-kofr2-mai","name":"Mai Shiranui"}
  ],
  "moves":[
    {"id":"ngpc-kofr2-kyo-spc-aragami","name":"114 Shiki: Aragami","category":"special","character_id":"ngpc-kofr2-kyo",
      "source_raw":"QCF + A",
      "activation":{"kind":"by_player_input"},
      "input_expressions":[{"parse_status":"parsed","expression":{
        "kind":"sequence","steps":[
          {"kind":"motion","shape":"quarter_circle_forward"},
          {"kind":"button","symbol":"A"}
        ]
      }}]
    },
    {"id":"ngpc-kofr2-kyo-throw-hatsugane","name":"Hatsugane","category":"throw","character_id":"ngpc-kofr2-kyo",
      "source_raw":"(close) Left or Right + P",
      "activation":{"kind":"by_player_input"},
      "input_expressions":[{"parse_status":"parsed","expression":{
        "kind":"contextual","requirements":[{"kind":"spatial","value":"near_opponent"}],
        "input":{"kind":"alternative","options":[
          {"kind":"sequence","steps":[{"kind":"direction","direction":"back","relative":true},{"kind":"button","symbol":"P"}]},
          {"kind":"sequence","steps":[{"kind":"direction","direction":"forward","relative":true},{"kind":"button","symbol":"P"}]}
        ]}
      }}]
    },
    {"id":"ngpc-kofr2-mai-spc-musasabi-no-mai-chijou","name":"Musasabi no Mai (Chijou)","category":"special","character_id":"ngpc-kofr2-mai",
      "source_raw":"charge d, u + P (hold)",
      "activation":{"kind":"by_player_input"},
      "input_expressions":[{"parse_status":"parsed","expression":{
        "kind":"charge","charge_direction":"down","duration_ms":null,
        "then":{"kind":"sequence","steps":[
          {"kind":"direction","direction":"up","relative":true},
          {"kind":"hold","input":{"kind":"button","symbol":"P"},"duration_ms":null}
        ]}
      }}]
    },
    {"id":"ngpc-kofr2-kyo-spc-nue-tumi","name":"910 Shiki: Nue Tumi","category":"special","character_id":"ngpc-kofr2-kyo",
      "source_raw":"QCB + P",
      "activation":{"kind":"by_player_input"},
      "input_expressions":[{"parse_status":"parsed","expression":{
        "kind":"sequence","steps":[
          {"kind":"motion","shape":"quarter_circle_back"},
          {"kind":"button","symbol":"P"}
        ]
      }}],
      "follow_ups":[{"move_id":"ngpc-kofr2-kyo-spc-arashin","relation":"follow_up"}]
    },
    {"id":"ngpc-kofr2-kyo-spc-arashin","name":"Arashin","category":"special","character_id":"ngpc-kofr2-kyo",
      "source_raw":"(Mid Hit — automatic)",
      "activation":{"kind":"automatic_after_move",
        "trigger":{"kind":"on_mid_hit","description":"(Mid Hit — automatic)","parent_move_id":"ngpc-kofr2-kyo-spc-nue-tumi"}}
    }
  ]
}
''';
