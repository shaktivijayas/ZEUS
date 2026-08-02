import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../firestore/split_repository.dart';
import '../firestore/user_repository.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  redirect: (context, state) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final onAuthRoute = state.matchedLocation == '/auth';

    if (uid == null) {
      return onAuthRoute ? null : '/auth';
    }

    final userRepo = UserRepository(FirebaseFirestore.instance, uid);
    final user = await userRepo.getUser();
    final onboarded = user?.onboarded ?? false;

    if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
    if (onboarded && (onAuthRoute || state.matchedLocation == '/onboarding')) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        userRepo: UserRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
        splitRepo: SplitRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const _HomeStub(),
    ),
  ],
);

/// Replaced by the real HomeScreen in Task 11.
class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home')));
}
