import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const _StubScreen(label: 'Auth'),
    ),
  ],
);

/// Temporary placeholder so the router is valid before Task 6 adds the real
/// AuthScreen. Deleted in Task 6 once AuthScreen exists.
class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
