// Minimal smoke test to ensure the app builds and mounts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storytots/app.dart';

void main() {
  testWidgets('StoryTotsApp builds MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const StoryTotsApp());
    // Allow initial frames to settle
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
