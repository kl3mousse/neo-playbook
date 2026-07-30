import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/gold_move_lab_screen.dart';
import 'package:combofox/l10n/generated/app_localizations.dart';

import '../utils/fixture_loader.dart';

Widget _wrap({
  required Future<ProfileGold> Function() loader,
  Locale locale = const Locale('en'),
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
    home: GoldMoveLabScreen(loader: loader),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Sources tab shows the license only once in the collapsed default view',
    (tester) async {
      final profile = parseBundleProfile('profile.json');
      await tester.pumpWidget(_wrap(loader: () async => profile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sources'));
      await tester.pumpAndSettle();

      // Count "CC BY-SA 4.0" occurrences in the visible Sources tab.
      // Before the fix the license appeared twice (composed credit
      // pill + a "License:" pill on the source tile). It must now
      // appear exactly once when the verbatim ExpansionTile is
      // collapsed.
      final matches = find.textContaining('CC BY-SA 4.0');
      expect(matches, findsOneWidget);
    },
  );

  testWidgets(
    'Verbatim attribution is still available behind an expansion tile',
    (tester) async {
      final profile = parseBundleProfile('profile.json');
      await tester.pumpWidget(_wrap(loader: () async => profile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sources'));
      await tester.pumpAndSettle();

      // The verbatim ExpansionTile lives at the bottom of the
      // Sources tab list. Drag the tab-body ListView until the
      // header is on screen, then tap it.
      final verbatimHeader = find.text('Verbatim attribution text');
      final tabBody = find.byType(ListView).last;
      for (var i = 0; verbatimHeader.evaluate().isEmpty && i < 15; i++) {
        await tester.drag(tabBody, const Offset(0, -240));
        await tester.pump();
      }
      expect(verbatimHeader, findsOneWidget);
      await tester.tap(verbatimHeader);
      await tester.pumpAndSettle();

      // After expanding, the verbatim display_text carries at least
      // one "CC BY-SA 4.0" mention and the "StrategyWiki
      // contributors" attribution string, preserving CONSUMER_SPEC
      // §5 on-demand.
      expect(find.textContaining('CC BY-SA 4.0'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('StrategyWiki contributors'),
        findsAtLeastNWidgets(1),
      );
    },
  );
}
