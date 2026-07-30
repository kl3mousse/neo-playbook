import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/domain/expression.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/domain/move.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_localization.dart';
import 'package:combofox/l10n/generated/app_localizations.dart';

Future<AppLocalizations> _localizations(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  late AppLocalizations captured;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) {
          captured = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('localizeCategory', () {
    testWidgets('English maps every known MoveCategory to a distinct label', (
      tester,
    ) async {
      final l = await _localizations(tester);
      // Each known category yields a non-empty localized label.
      for (final c in MoveCategory.values) {
        final label = localizeCategory(l, c, c.wire);
        expect(label, isNotEmpty);
      }
    });

    testWidgets('French uses "Coup spécial" for the special category', (
      tester,
    ) async {
      final l = await _localizations(tester, locale: const Locale('fr'));
      expect(
        localizeCategory(l, MoveCategory.special, 'special'),
        'Coup spécial',
      );
      expect(
        localizeCategory(l, MoveCategory.throwMove, 'throw'),
        'Projection',
      );
      expect(
        localizeCategory(l, MoveCategory.commandNormal, 'command_normal'),
        'Coup normal spécial',
      );
    });

    testWidgets('unknown category falls back to raw wire, not empty string', (
      tester,
    ) async {
      final l = await _localizations(tester);
      final label = localizeCategory(
        l,
        MoveCategory.unknown,
        'future_kind_9000',
      );
      expect(label, 'future_kind_9000');
    });
  });

  group('localizeRequirement', () {
    testWidgets('known (kind, value) pairs map to localized phrases', (
      tester,
    ) async {
      final l = await _localizations(tester);
      expect(
        localizeRequirement(
          l,
          const Requirement(
            kind: RequirementKind.spatial,
            rawKind: 'spatial',
            value: 'near_wall',
          ),
        ),
        'Near a wall',
      );
      expect(
        localizeRequirement(
          l,
          const Requirement(
            kind: RequirementKind.state,
            rawKind: 'state',
            value: 'airborne',
          ),
        ),
        'In the air',
      );
    });

    testWidgets('unknown requirement surfaces raw kind:value, not empty', (
      tester,
    ) async {
      final l = await _localizations(tester);
      final label = localizeRequirement(
        l,
        const Requirement(
          kind: RequirementKind.unknown,
          rawKind: 'future_ctx',
          value: 'meta',
        ),
      );
      // Must contain the raw wire — CONSUMER_SPEC §9.
      expect(label, contains('future_ctx'));
    });
  });

  group('labResultsCount uses moves / coups plural forms', () {
    testWidgets('English: uses "moves"', (tester) async {
      final l = await _localizations(tester);
      expect(l.labResultsCount(0), 'No moves');
      expect(l.labResultsCount(1), '1 move');
      expect(l.labResultsCount(12), '12 moves');
    });

    testWidgets('French: uses "coups"', (tester) async {
      final l = await _localizations(tester, locale: const Locale('fr'));
      expect(l.labResultsCount(0), 'Aucun coup');
      expect(l.labResultsCount(1), '1 coup');
      expect(l.labResultsCount(12), '12 coups');
    });
  });

  group('composed credit does not include license twice', () {
    testWidgets('English format is "Source — License"', (tester) async {
      final l = await _localizations(tester);
      final composed = l.labProvenanceComposedCredit(
        'StrategyWiki contributors',
        'CC BY-SA 4.0',
      );
      // Exactly one occurrence of "CC BY-SA 4.0" in the composed line.
      expect(RegExp('CC BY-SA 4.0').allMatches(composed).length, 1);
      expect(composed, contains('StrategyWiki'));
    });
  });
}
