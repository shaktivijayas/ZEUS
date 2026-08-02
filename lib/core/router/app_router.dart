import 'package:go_router/go_router.dart';
import '../../features/auth/auth_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
  ],
);
