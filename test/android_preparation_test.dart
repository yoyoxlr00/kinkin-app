import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinkin/main.dart';
import 'package:kinkin/storage_migration.dart';

void main() {
  test('old web JSON survives migration and repeated startup', () {
    for (final raw in [
      '{"restaurant":{"id":"one"}}',
      '[{"id":"one"}]',
      '12',
      'broken'
    ]) {
      final migrated = normalizeLegacyStorage(raw);
      expect(jsonDecode(migrated), raw);
      expect(normalizeLegacyStorage(migrated), migrated);
    }
  });

  testWidgets('welcome screen scrolls to start on a short phone screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const KinkinApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('เริ่มใช้งาน kinkin'));
    await tester.pumpAndSettle();
    expect(find.text('เริ่มใช้งาน kinkin').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
