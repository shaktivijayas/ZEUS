import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('saving the first split day marks the user onboarded', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final userRepo = UserRepository(firestore, 'uid-1');
    final splitRepo = SplitRepository(firestore, 'uid-1');
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(userRepo: userRepo, splitRepo: splitRepo),
      ),
    );

    await tester.enterText(find.byKey(const Key('onboarding_day_label_field')), 'Chest & Shoulders');
    await tester.tap(find.byKey(const Key('onboarding_save_button')));
    await tester.pumpAndSettle();

    final user = await userRepo.getUser();
    expect(user!.onboarded, isTrue);

    final days = await splitRepo.watchSplitDays().first;
    expect(days, hasLength(1));
    expect(days.single.label, 'Chest & Shoulders');
  });
}
