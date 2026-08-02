import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/auth/auth_providers.dart';
import 'package:zeus/core/auth/auth_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/features/auth/auth_screen.dart';

void main() {
  testWidgets('signing up calls AuthRepository.signUp with the entered fields', (tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(auth, (uid) => UserRepository(firestore, uid)),
          ),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    await tester.enterText(find.byKey(const Key('auth_name_field')), 'Vani');
    await tester.enterText(find.byKey(const Key('auth_email_field')), 'vani@example.com');
    await tester.enterText(find.byKey(const Key('auth_password_field')), 'hunter22');
    await tester.tap(find.byKey(const Key('auth_submit_button')));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    expect(auth.currentUser!.email, 'vani@example.com');
  });

  testWidgets('toggling to sign-in mode hides the name field', (tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(auth, (uid) => UserRepository(firestore, uid)),
          ),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    expect(find.byKey(const Key('auth_name_field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth_toggle_mode_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_name_field')), findsNothing);
  });
}
