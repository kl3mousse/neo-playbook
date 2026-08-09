import 'package:combofox/experimental/glyph_studio/presentation/glyph_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows live size validation and grouped gallery', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GlyphStudioScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Glyph Studio'), findsOneWidget);
    expect(find.text('Size validation'), findsOneWidget);
    expect(find.text('24px'), findsOneWidget);
    expect(find.text('Neutral point radius'), findsOneWidget);
    expect(find.text('All motions at 24px'), findsOneWidget);
    expect(find.text('DIRECTIONS'), findsOneWidget);
    expect(find.text('MOTIONS'), findsOneWidget);
    expect(find.text('BUTTONS'), findsOneWidget);
    expect(find.text('OPERATORS'), findsOneWidget);
    expect(find.text('motion_qcf'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
  });
}
