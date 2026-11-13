import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinkin/main.dart';

void main() {
  testWidgets('map tab explains configuration in demo mode', (tester) async {
    await tester.pumpWidget(const KinkinApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('แผนที่'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('แผนที่พร้อมเมื่อเชื่อม Google Maps'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('แผนที่พร้อมเมื่อเชื่อม Google Maps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
