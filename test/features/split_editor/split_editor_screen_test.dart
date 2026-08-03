import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/features/split_editor/split_editor_screen.dart';
import 'package:zeus/models/split_day.dart';

void main() {
  testWidgets('adding a day shows it in the list', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');

    await tester.pumpWidget(MaterialApp(home: SplitEditorScreen(splitRepo: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('split_editor_add_day_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add_day_label_field')), 'Legs');
    await tester.tap(find.byKey(const Key('add_day_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Legs'), findsOneWidget);
  });

  testWidgets('deleting a day removes it from the list', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');
    await repo.saveSplitDay(const SplitDay(id: 'legs', label: 'Legs', order: 0, exercises: []));

    await tester.pumpWidget(MaterialApp(home: SplitEditorScreen(splitRepo: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Legs'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_day_legs')));
    await tester.pumpAndSettle();

    expect(find.text('Legs'), findsNothing);
  });
}
