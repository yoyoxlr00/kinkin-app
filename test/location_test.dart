import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinkin/main.dart';
import 'package:kinkin/location_picker.dart';

void main() {
  testWidgets('location button opens choices; DPU updates search area',
      (tester) async {
    await tester.pumpWidget(const KinkinApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('สยาม กรุงเทพฯ'));
    await tester.pumpAndSettle();
    expect(find.text('ใช้ตำแหน่งของฉัน'), findsOneWidget);
    expect(find.text('ค้นหาสถานที่'), findsOneWidget);
    expect(find.text('ปักหมุดบนแผนที่'), findsOneWidget);
    await tester.tap(find.text('มหาวิทยาลัยธุรกิจบัณฑิตย์'));
    await tester.pumpAndSettle();
    expect(find.text('มหาวิทยาลัยธุรกิจบัณฑิตย์'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ยังไม่เจอร้านที่ใช่'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('ยังไม่เจอร้านที่ใช่'), findsOneWidget);
  });

  testWidgets(
      'search displays results after submitting and returns selected place',
      (tester) async {
    SearchLocation? selected;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      selected = await Navigator.push<SearchLocation>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LocationSearchPage(
                                  lookup: (q) async => [
                                        SearchLocation(q, 18, 99, 'เชียงใหม่')
                                      ])));
                    },
                    child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'สถานที่ทดสอบ');
    await tester.tap(find.byTooltip('ค้นหา'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'สถานที่ทดสอบ'));
    await tester.pumpAndSettle();
    expect(selected?.lat, 18);
    expect(selected?.name, 'สถานที่ทดสอบ');
  });
}
