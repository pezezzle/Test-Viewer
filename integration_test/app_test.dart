import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testmaster_viewer/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('The explicitly marked demo opens both Flutter screens', (tester) async {
    await tester.pumpWidget(const TestMasterApp(startInDemo: true));
    await tester.pumpAndSettle();
    expect(find.text('DEMOMODUS · ausschliesslich fiktive Daten'), findsOneWidget);
    await tester.ensureVisible(find.text('Geräte').first);
    await tester.tap(find.text('Geräte').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('device-search')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
