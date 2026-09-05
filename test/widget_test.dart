import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testmaster_viewer/data/demo_store.dart';
import 'package:testmaster_viewer/domain/calendar_day.dart';
import 'package:testmaster_viewer/main.dart';

void main() {
  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('Dashboard and device page render at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        TestMasterApp(
          store: DemoViewerStore(reference: const CalendarDay(2026, 9, 5)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byKey(const ValueKey('customer-heading')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-logo')), findsOneWidget);
      expect(find.textContaining('Test-Master'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Devices').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('device-search')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Reference date can be changed and reset', (tester) async {
    await tester.pumpWidget(TestMasterApp(store: DemoViewerStore()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reference-date-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reference-date-input')),
      '2027-01-15',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Apply'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.text('15.01.2027'), findsOneWidget);
    expect(find.text('REFERENCE DATE · MANUAL'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reference-date-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Today · automatic'));
    await tester.tap(find.text('Today · automatic'));
    await tester.pumpAndSettle();
    expect(find.text('REFERENCE DATE · AUTO'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final save in [false, true]) {
    testWidgets(
      'Source settings safely ${save ? "save" : "close"} with a focused input',
      (tester) async {
        await tester.pumpWidget(TestMasterApp(store: DemoViewerStore()));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Database'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('database-path')),
          'example.sqlite3',
        );
        final action = save
            ? find.widgetWithText(FilledButton, 'Save path & load')
            : find.widgetWithText(OutlinedButton, 'Close');
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('database-path')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('Location search allows multiple checked results', (
    tester,
  ) async {
    await tester.pumpWidget(TestMasterApp(store: DemoViewerStore()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'All locations'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('location-search')),
      'Room',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select results'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.text('2 locations selected'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
