import 'package:assoc_format_perfect_gest_col/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens the equipment workflow and saves a local record', (
    tester,
  ) async {
    await tester.pumpWidget(const OperationsApp());
    await tester.pumpAndSettle();

    expect(find.text('Operations control'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab_equipment')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('new_equipment')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('record_title')),
      'Cable tester CT-9',
    );
    await tester.enterText(
      find.byKey(const ValueKey('record_owner')),
      'Audit team',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('record_notes')));
    await tester.enterText(
      find.byKey(const ValueKey('record_notes')),
      'Assigned for the morning inspection route.',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save_record')));
    await tester.tap(find.byKey(const ValueKey('save_record')));
    await tester.pumpAndSettle();

    expect(find.text('Cable tester CT-9'), findsOneWidget);
    expect(find.text('Audit team'), findsOneWidget);
  });
}
