// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:bananagrams/main.dart';

void main() {
  testWidgets('Play opens the game page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('BANANAGRAMS'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('Available tiles'), findsOneWidget);
    expect(find.text('Remaining tiles'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.tap(find.text('START GAME'));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('END GAME'), findsOneWidget);
    expect(find.text('00:01'), findsOneWidget);

    await tester.tap(find.text('END GAME'));
    await tester.pump();

    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('STATS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Statistics page content goes here.'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('SETTINGS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Settings page content goes here.'), findsOneWidget);
  });
}
