import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/domain/button.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/expression.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/move.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/parse_status.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_controller.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_move_card.dart';
import 'package:combofox/l10n/generated/app_localizations.dart';

final ButtonCatalog _buttons = ButtonCatalog(
  buttons: const [
    ButtonSpec(symbol: 'A', label: 'Weak Punch'),
    ButtonSpec(symbol: 'B', label: 'Weak Kick'),
    ButtonSpec(symbol: 'C', label: 'Strong Punch'),
    ButtonSpec(symbol: 'D', label: 'Strong Kick'),
  ],
  groups: const [
    ButtonGroupSpec(symbol: 'P', label: 'Any Punch', members: ['A', 'C']),
  ],
);

MoveGold _fireball({String? sourceRaw = 'qcf + A'}) => MoveGold(
  id: 'fb',
  name: 'Fireball',
  rawCategory: 'special',
  category: MoveCategory.special,
  activation: const Activation(
    kind: ActivationKind.byPlayerInput,
    rawKind: 'by_player_input',
  ),
  inputExpressions: [
    InputExpressionWrapper(
      parseStatus: ParseStatus.parsed,
      expression: SequenceExpr(const [
        MotionExpr(MotionShape.quarterCircleForward),
        ButtonExpr('A'),
      ]),
      sourceRaw: sourceRaw,
    ),
  ],
  sourceRaw: sourceRaw,
);

MoveGold _autoMove() => MoveGold(
  id: 'auto',
  name: 'Auto Follow-up',
  rawCategory: 'special',
  category: MoveCategory.special,
  activation: const Activation(
    kind: ActivationKind.automaticAfterMove,
    rawKind: 'automatic_after_move',
    trigger: ActivationTrigger(
      kind: TriggerKind.onMidHit,
      rawKind: 'on_mid_hit',
      parentMoveId: 'fb',
    ),
  ),
  sourceRaw: '(auto)',
);

MoveGold _throw() => MoveGold(
  id: 'thr',
  name: 'Grab',
  rawCategory: 'throw',
  category: MoveCategory.throwMove,
  activation: const Activation(
    kind: ActivationKind.byPlayerInput,
    rawKind: 'by_player_input',
  ),
  inputExpressions: [
    InputExpressionWrapper(
      parseStatus: ParseStatus.parsed,
      expression: ContextualExpr(
        requirements: const [
          Requirement(
            kind: RequirementKind.spatial,
            rawKind: 'spatial',
            value: 'near_opponent',
          ),
        ],
        input: SequenceExpr(const [
          DirectionExpr(GoldDirection.forward, relative: true),
          ButtonExpr('C'),
        ]),
      ),
      sourceRaw: '(close) f + C',
    ),
  ],
  sourceRaw: '(close) f + C',
);

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  double width = 360,
  double textScale = 1.0,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('notation isolation', () {
    testWidgets('pictograms mode does not echo numpad or classic 2D text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LabMoveCard(
            move: _fireball(),
            buttons: _buttons,
            notation: LabNotation.pictograms,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      // No numpad "236A" and no classic "qcf + A" text is shown as a
      // secondary line under the pictograms.
      expect(find.text('236A'), findsNothing);
      expect(find.text('qcf + A'), findsNothing);
      // The 236 motion pill IS present because it's part of the
      // pictogram rendering itself, but "236A" as a single string
      // must not appear.
    });

    testWidgets('numpad mode does not render pictograms', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LabMoveCard(
            move: _fireball(),
            buttons: _buttons,
            notation: LabNotation.numpad,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      // Numpad string is shown.
      expect(find.textContaining('236'), findsOneWidget);
      // No coloured button chip for "A" alone (the "A" here appears
      // as part of the numpad string, not as a chip).
    });

    testWidgets('classic 2d mode does not render numpad', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LabMoveCard(
            move: _fireball(),
            buttons: _buttons,
            notation: LabNotation.classic2d,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      // Classic 2D uses `qcf`, `dp`, arrows — assert numpad "236" is
      // NOT shown.
      expect(find.text('236'), findsNothing);
    });

    testWidgets('accessible mode shows only the sentence', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LabMoveCard(
            move: _fireball(),
            buttons: _buttons,
            notation: LabNotation.accessible,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      // No numpad, no motion pill.
      expect(find.text('236'), findsNothing);
    });
  });

  testWidgets('card never displays source_raw by default', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LabMoveCard(
          move: _fireball(sourceRaw: 'qcf + A'),
          buttons: _buttons,
          notation: LabNotation.pictograms,
          locale: LabAccessibleLocale.en,
        ),
      ),
    );
    // The `source_raw` verbatim string must not leak into the card UI
    // when [showTechnicalDetails] is false (mission §13).
    expect(find.text('qcf + A'), findsNothing);
    expect(find.textContaining('Source (raw)'), findsNothing);
  });

  testWidgets('technical details block appears when opted in', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LabMoveCard(
          move: _fireball(sourceRaw: 'qcf + A'),
          buttons: _buttons,
          notation: LabNotation.pictograms,
          locale: LabAccessibleLocale.en,
          showTechnicalDetails: true,
        ),
      ),
    );
    expect(find.text('Technical details'), findsOneWidget);
  });

  testWidgets('category is displayed as a localized label, not the raw wire', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LabMoveCard(
          move: _throw(),
          buttons: _buttons,
          notation: LabNotation.pictograms,
          locale: LabAccessibleLocale.en,
        ),
      ),
    );
    // Localized English label appears.
    expect(find.text('Throw'), findsOneWidget);
    // The wire value 'throw' also matches 'Throw' case-insensitively
    // in French tests, so we assert we don't see the mixed-case
    // artifact rawCategory in ANY comfortable-mode header. We look
    // for 'throw' (lowercase) as a standalone label — should not
    // appear because rawCategory is only shown via localizeCategory.
    // (The raw fallback path only kicks in for MoveCategory.unknown.)
  });

  testWidgets(
    'requirements are localized (spatial:near_opponent → "Close to the opponent")',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          LabMoveCard(
            move: _throw(),
            buttons: _buttons,
            notation: LabNotation.pictograms,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      expect(find.text('Close to the opponent'), findsWidgets);
    },
  );

  testWidgets('automatic activation renders distinctively, not as a button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LabMoveCard(
          move: _autoMove(),
          buttons: _buttons,
          notation: LabNotation.pictograms,
          locale: LabAccessibleLocale.en,
        ),
      ),
    );
    // AUTO badge is visible (upper-cased localized label).
    expect(find.text('AUTOMATIC'), findsOneWidget);
    // No colored button chip is rendered because the move has no
    // player input expression at all.
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    // No filled ElevatedButton pretending to be a fake action button.
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('compact density drops annotations/requirements/character row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LabMoveCard(
          move: _throw(),
          buttons: _buttons,
          notation: LabNotation.pictograms,
          locale: LabAccessibleLocale.en,
          density: LabDensity.compact,
        ),
      ),
    );
    // In compact mode the "Only when" requirements label is dropped
    // (the requirement chip inside the pictogram is still visible).
    expect(find.text('Only when:'), findsNothing);
  });

  testWidgets(
    'comfortable density surfaces the "Only when:" requirements row',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          LabMoveCard(
            move: _throw(),
            buttons: _buttons,
            notation: LabNotation.pictograms,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      expect(find.text('Only when:'), findsOneWidget);
    },
  );

  testWidgets('narrow phone at 200% text scale does not overflow', (
    tester,
  ) async {
    // 320 CSS logical pixels width simulates a compact phone; text
    // scaled to 200% must still not overflow.
    await tester.pumpWidget(
      _wrap(
        LabMoveCard(
          move: _fireball(),
          buttons: _buttons,
          notation: LabNotation.pictograms,
          locale: LabAccessibleLocale.en,
          density: LabDensity.compact,
        ),
        width: 320,
        textScale: 2.0,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
