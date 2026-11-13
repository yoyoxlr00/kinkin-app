import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinkin/main.dart';

void main() {
  testWidgets('demo loads and cuisine filter limits the list', (tester) async {
    await tester.pumpWidget(const KinkinApp());
    await tester.pumpAndSettle();
    expect(find.text('kinkin'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '🍣 ญี่ปุ่น'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sakura Table'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Sakura Table'), findsOneWidget);
    expect(find.text('ครัวอิ่มใจ'), findsNothing);
  });
}
