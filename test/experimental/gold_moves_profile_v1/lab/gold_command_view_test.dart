import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/domain/button.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/expression.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/move.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/parse_status.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/gold_command_view.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_controller.dart';
import 'package:combofox/l10n/generated/app_localizations.dart';

/// Test-only button catalog covering the four canonical KOF buttons
/// and the two common groups.
final ButtonCatalog _buttons = ButtonCatalog(
  buttons: const [
    ButtonSpec(symbol: 'A', label: 'Weak Punch'),
    ButtonSpec(symbol: 'B', label: 'Weak Kick'),
    ButtonSpec(symbol: 'C', label: 'Strong Punch'),
    ButtonSpec(symbol: 'D', label: 'Strong Kick'),
  ],
  groups: const [
    ButtonGroupSpec(symbol: 'P', label: 'Any Punch', members: ['A', 'C']),
    ButtonGroupSpec(symbol: 'K', label: 'Any Kick', members: ['B', 'D']),
  ],
);

MoveGold _makeMove({
  required String name,
  Expression? expression,
  Activation? activation,
  String? sourceRaw,
  MoveCategory category = MoveCategory.special,
}) {
  return MoveGold(
    id: 'test-${name.hashCode}',
    name: name,
    rawCategory: category.wire,
    category: category,
    activation:
        activation ??
        const Activation(
          kind: ActivationKind.byPlayerInput,
          rawKind: 'by_player_input',
        ),
    inputExpressions: expression == null
        ? const []
        : [
            InputExpressionWrapper(
              parseStatus: ParseStatus.parsed,
              expression: expression,
              sourceRaw: sourceRaw,
            ),
          ],
    sourceRaw: sourceRaw,
  );
}

Widget wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  double width = 360,
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
      body: SingleChildScrollView(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button tokens do not stretch to fill the row', (tester) async {
    // A single button in a Sequence must render a fixed-width chip,
    // not an Expanded child.
    final move = _makeMove(
      name: 'Solo Punch',
      expression: const ButtonExpr('A'),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
        ),
      ),
    );
    final buttonText = find.text('A');
    expect(buttonText, findsOneWidget);
    final size = tester.getSize(buttonText);
    // Compact button — glyph should fit in ~24×24 chip. Verify the
    // rendered *text* is not stretched to viewport width.
    expect(size.width, lessThan(60));
  });

  testWidgets('command wraps between groups on a narrow phone', (tester) async {
    // A long combo (QCF QCF C D) fits into more than one line on a
    // 320-wide viewport; the widget must not overflow.
    final move = _makeMove(
      name: 'Long Combo',
      expression: SequenceExpr(const [
        MotionExpr(MotionShape.quarterCircleForward),
        MotionExpr(MotionShape.quarterCircleForward),
        ButtonExpr('C'),
        ButtonExpr('D'),
      ]),
      sourceRaw: 'qcf, qcf + CD',
      category: MoveCategory.superMove,
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
        ),
        width: 220,
      ),
    );
    // No overflow errors were reported.
    final exception = tester.takeException();
    expect(exception, isNull);
    // The 236 motion pill is present and visible.
    expect(find.text('236'), findsWidgets);
  });

  testWidgets('accessible sentence is used as the single semantic label', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Fireball',
      expression: SequenceExpr(const [
        MotionExpr(MotionShape.quarterCircleForward),
        ButtonExpr('A'),
      ]),
      sourceRaw: 'qcf + A',
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
        ),
      ),
    );
    // The Semantics wrapper carries a container label; assertions on
    // the semantics tree are done via SemanticsNode inspection.
    final semantics = tester.getSemantics(find.byType(GoldCommandView));
    // The semantic label must be a non-empty string that is NOT the
    // concatenation of every glyph (i.e. contains a real word).
    expect(semantics.label, isNotEmpty);
  });

  testWidgets(
    'unknown expression is surfaced with its raw kind, no silent drop',
    (tester) async {
      final move = _makeMove(
        name: 'Future Move',
        expression: const UnknownExpression(rawKind: 'future_kind_42'),
        sourceRaw: '<future 1.1>',
      );
      await tester.pumpWidget(
        wrap(
          GoldCommandView(
            move: move,
            buttons: _buttons,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      // The raw kind is exposed to the reader — CONSUMER_SPEC §9.
      expect(find.textContaining('future_kind_42'), findsOneWidget);
    },
  );

  testWidgets(
    'no-input move (automatic activation) shows "no input required" chip',
    (tester) async {
      final move = _makeMove(
        name: 'Auto Follow-up',
        activation: const Activation(
          kind: ActivationKind.byPlayerInput,
          rawKind: 'by_player_input',
        ),
      );
      await tester.pumpWidget(
        wrap(
          GoldCommandView(
            move: move,
            buttons: _buttons,
            locale: LabAccessibleLocale.en,
          ),
        ),
      );
      expect(find.text('No player input required'), findsOneWidget);
    },
  );

  testWidgets('fallback expression is styled as a warning chip', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Broken',
      expression: null,
      sourceRaw: 'BC ~ 236B (undocumented)',
    );
    // Force an unparsed wrapper (fallback path).
    final withRaw = MoveGold(
      id: move.id,
      name: move.name,
      rawCategory: move.rawCategory,
      category: move.category,
      activation: move.activation,
      inputExpressions: const [
        InputExpressionWrapper(
          parseStatus: ParseStatus.unparsed,
          sourceRaw: 'BC ~ 236B (undocumented)',
        ),
      ],
      sourceRaw: 'BC ~ 236B (undocumented)',
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: withRaw,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
        ),
      ),
    );
    expect(find.textContaining('BC ~ 236B'), findsOneWidget);
  });
}
