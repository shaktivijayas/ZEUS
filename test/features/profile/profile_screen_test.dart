import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/auth/auth_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/features/profile/profile_screen.dart';

void main() {
  testWidgets('shows longest streak and freezes remaining, logs out on tap', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final userRepo = UserRepository(firestore, 'uid-1');
    final authRepo = AuthRepository(auth, (uid) => UserRepository(firestore, uid));
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');
    await userRepo.updateStreakAndFreezes(currentStreak: 3, longestStreak: 7, freezesRemaining: 1, freezesResetDate: DateTime.utc(2026, 9, 1));

    await tester.pumpWidget(MaterialApp(home: ProfileScreen(userRepo: userRepo, authRepo: authRepo)));
    await tester.pumpAndSettle();

    // Note: find.textContaining('1') from the original brief is ambiguous here —
    // it also matches the "01" in the rendered freezesResetDate ("2026-09-01").
    // Using exact text matches instead to unambiguously assert on the two fields.
    expect(find.text('Longest streak: 7'), findsOneWidget);
    expect(find.text('Freezes remaining: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_log_out_button')));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
  });
}
