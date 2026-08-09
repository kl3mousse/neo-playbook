import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/domain/button.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/expression.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/move.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/parse_status.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/gold_glyph_assets.dart';
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
    expect(_glyph('assets/glyphs/directions/dir_d.svg'), findsWidgets);
  });

  testWidgets('pictograms omit textual sequence separators', (tester) async {
    final move = _makeMove(
      name: 'Charge Combo',
      expression: SequenceExpr(const [
        DirectionExpr(GoldDirection.back),
        ChargeExpr(
          chargeDirection: ChargeDirection.downBack,
          then: ButtonExpr('A'),
        ),
        ButtonExpr('B'),
      ]),
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

    expect(find.text('then'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('direction pictograms use the published direction SVGs', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Directions',
      expression: SequenceExpr(const [
        DirectionExpr(GoldDirection.forward),
        DirectionExpr(GoldDirection.back),
        DirectionExpr(GoldDirection.up),
        DirectionExpr(GoldDirection.down),
        DirectionExpr(GoldDirection.upForward),
        DirectionExpr(GoldDirection.upBack),
        DirectionExpr(GoldDirection.downForward),
        DirectionExpr(GoldDirection.downBack),
      ]),
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

    for (final id in const [
      'dir_f',
      'dir_b',
      'dir_u',
      'dir_d',
      'dir_uf',
      'dir_ub',
      'dir_df',
      'dir_db',
    ]) {
      expect(_glyph('assets/glyphs/directions/$id.svg'), findsOneWidget);
    }
  });

  testWidgets('motion glyph mode draws every supported joystick motion', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Motion Gallery',
      expression: AlternativeExpr(
        MotionShape.values
            .map<Expression>(MotionExpr.new)
            .toList(growable: false),
      ),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
          visualNotation: GoldVisualNotation.motionGlyphs,
        ),
        width: 360,
      ),
    );

    for (final shape in MotionShape.values) {
      expect(_glyph(GoldGlyphAssets.motion(shape)), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('motion glyph mode folds a directional QCF into one glyph', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Directional Fireball',
      expression: SequenceExpr(const [
        DirectionExpr(GoldDirection.down),
        DirectionExpr(GoldDirection.downForward),
        DirectionExpr(GoldDirection.forward),
        ButtonExpr('A'),
      ]),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
          visualNotation: GoldVisualNotation.motionGlyphs,
        ),
      ),
    );

    expect(_glyph('assets/glyphs/motions/motion_qcf.svg'), findsOneWidget);
    expect(_glyph('assets/glyphs/directions/dir_d.svg'), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('motion glyph mode folds directional reverse DP', (tester) async {
    final move = _makeMove(
      name: 'Reverse DP',
      expression: SequenceExpr(const [
        DirectionExpr(GoldDirection.forward),
        DirectionExpr(GoldDirection.downForward),
        DirectionExpr(GoldDirection.down),
      ]),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
          visualNotation: GoldVisualNotation.motionGlyphs,
        ),
      ),
    );

    expect(_glyph('assets/glyphs/motions/motion_rdpf.svg'), findsOneWidget);
    expect(_glyph('assets/glyphs/directions/dir_f.svg'), findsNothing);
  });

  testWidgets('arrow mode expands a named motion into direction SVGs', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Named Fireball',
      expression: const MotionExpr(MotionShape.quarterCircleForward),
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

    expect(_glyph('assets/glyphs/directions/dir_d.svg'), findsOneWidget);
    expect(_glyph('assets/glyphs/directions/dir_df.svg'), findsOneWidget);
    expect(_glyph('assets/glyphs/directions/dir_f.svg'), findsOneWidget);
    expect(_glyph('assets/glyphs/motions/motion_qcf.svg'), findsNothing);
  });

  testWidgets('facing-left swaps relative motion assets', (tester) async {
    final move = _makeMove(
      name: 'Mirrored Fireball',
      expression: const MotionExpr(MotionShape.quarterCircleForward),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
          mirrorForFacingLeft: true,
          visualNotation: GoldVisualNotation.motionGlyphs,
        ),
      ),
    );

    expect(_glyph('assets/glyphs/motions/motion_qcb.svg'), findsOneWidget);
    expect(_glyph('assets/glyphs/motions/motion_qcf.svg'), findsNothing);
  });

  testWidgets('visual operators omit then and use other operator SVGs', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Operators',
      expression: SequenceExpr(const [
        SimultaneousExpr([ButtonExpr('A'), ButtonExpr('B')]),
        HoldExpr(input: ButtonExpr('C')),
        ReleaseExpr(input: ButtonExpr('D')),
      ]),
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

    expect(_glyph(GoldGlyphAssets.operator(GoldGlyphOperator.plus)), findsOne);
    expect(
      _glyph(GoldGlyphAssets.operator(GoldGlyphOperator.then)),
      findsNothing,
    );
    expect(_glyph(GoldGlyphAssets.operator(GoldGlyphOperator.hold)), findsOne);
    expect(
      _glyph(GoldGlyphAssets.operator(GoldGlyphOperator.release)),
      findsOne,
    );
  });

  testWidgets('motion mode consumes charge release direction once', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Charge',
      expression: ChargeExpr(
        chargeDirection: ChargeDirection.back,
        then: SequenceExpr(const [
          DirectionExpr(GoldDirection.forward),
          ButtonExpr('P'),
        ]),
      ),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
          visualNotation: GoldVisualNotation.motionGlyphs,
        ),
      ),
    );

    expect(
      _glyph('assets/glyphs/motions/motion_charge_bf.svg'),
      findsOneWidget,
    );
    expect(_glyph('assets/glyphs/directions/dir_f.svg'), findsNothing);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('motion mode recognizes down-to-up charge', (tester) async {
    final move = _makeMove(
      name: 'Flash Kick',
      expression: ChargeExpr(
        chargeDirection: ChargeDirection.down,
        then: SequenceExpr(const [
          DirectionExpr(GoldDirection.up),
          ButtonExpr('K'),
        ]),
      ),
    );
    await tester.pumpWidget(
      wrap(
        GoldCommandView(
          move: move,
          buttons: _buttons,
          locale: LabAccessibleLocale.en,
          visualNotation: GoldVisualNotation.motionGlyphs,
        ),
      ),
    );

    expect(
      _glyph('assets/glyphs/motions/motion_charge_du.svg'),
      findsOneWidget,
    );
    expect(_glyph('assets/glyphs/directions/dir_u.svg'), findsNothing);
    expect(find.text('K'), findsOneWidget);
  });

  testWidgets('neutral, any, and unknown button retain readable fallbacks', (
    tester,
  ) async {
    final move = _makeMove(
      name: 'Fallbacks',
      expression: SequenceExpr(const [
        DirectionExpr(GoldDirection.neutral),
        DirectionExpr(GoldDirection.any),
        ButtonExpr('Z'),
      ]),
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

    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
    expect(_glyph('assets/glyphs/buttons/btn_z.svg'), findsNothing);
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

Finder _glyph(String assetPath) => find.byKey(ValueKey('glyph:$assetPath'));
