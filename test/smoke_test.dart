import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus/main.dart';

void main() {
  // The app's router redirect gate (Task 9) reads FirebaseAuth.instance,
  // which requires a default Firebase app to exist. Set up the official
  // FlutterFire test mocks so Firebase.initializeApp() succeeds without a
  // real backend; FirebaseAuth.instance.currentUser then resolves to null
  // (unauthenticated), same as an unauthenticated real user.
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('app boots and shows the auth screen', (tester) async {
    await tester.pumpWidget(ProviderScope(child: ZeusApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_submit_button')), findsOneWidget);
  });
}
