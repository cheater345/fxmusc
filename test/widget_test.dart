import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fxmusc/main.dart';

void main() {
  testWidgets('App builds and shows navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const FxmMusicApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
