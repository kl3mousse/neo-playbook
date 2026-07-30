import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_controller.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_gallery.dart';
import 'package:combofox/l10n/generated/app_localizations.dart';

import '../utils/fixture_loader.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProfileGold profile;

  setUpAll(() {
    profile = parseBundleProfile('profile.json');
  });

  testWidgets('gallery lists the 16 representative expression kinds', (
    tester,
  ) async {
    // The list of samples exposed by the gallery is exhaustive.
    expect(buildGallerySamples().length, 16);
    // Every ARB label key resolves to a non-empty English string.
    // Simulate the resolution via a small pump with English locale.
    final controller = LabController(profile);
    await tester.pumpWidget(
      _wrap(
        SizedBox(height: 12000, child: LabGalleryView(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    // "Simple command" is at the very top and must be visible.
    expect(find.text('Simple command'), findsWidgets);
    // The synthetic badge is uppercased for accessibility. With the
    // comparison + visual review sections now above the samples list,
    // the badge lives further down: drag the ListView until at least
    // one badge is on screen before asserting.
    final scrollable = find.descendant(
      of: find.byType(LabGalleryView),
      matching: find.byType(Scrollable),
    );
    while (find.textContaining('SYNTHETIC EXAMPLE').evaluate().isEmpty) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump();
    }
    expect(find.textContaining('SYNTHETIC EXAMPLE'), findsWidgets);
  });
}
