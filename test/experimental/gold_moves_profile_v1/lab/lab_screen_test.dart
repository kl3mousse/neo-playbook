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

  testWidgets('renders provenance verbatim (StrategyWiki + CC BY-SA 4.0)', (
    tester,
  ) async {
    final profile = parseBundleProfile('profile.json');
    await tester.pumpWidget(_wrap(loader: () async => profile));
    await tester.pumpAndSettle();

    // Move to the Sources tab.
    await tester.tap(find.text('Sources'));
    await tester.pumpAndSettle();

    // The primary source name must be present verbatim.
    expect(find.text(profile.attribution.primarySource.name), findsWidgets);
    // The full displayText must contain the CC BY-SA 4.0 clause.
    expect(
      find.textContaining('CC BY-SA 4.0'),
      findsWidgets,
      reason: 'attribution displayText must render the license verbatim',
    );
  });

  testWidgets('shows a retry UI when loading fails', (tester) async {
    await tester.pumpWidget(
      _wrap(loader: () async => throw StateError('boom')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Could not load'), findsOneWidget);
  });
}
