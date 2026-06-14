import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunk/app.dart';

void main() {
  testWidgets('bottom navigation switches between shell screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HunkApp());

    expect(find.text('AI fitness coach'), findsOneWidget);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    expect(find.text('Health data sources'), findsOneWidget);

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    expect(find.text('AI coach chat'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('API keys'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Daily snapshot'), findsOneWidget);
  });
}
