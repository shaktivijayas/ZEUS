import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/home/home_sync_gate.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/split_editor/split_day_detail_screen.dart';
import '../../features/split_editor/split_editor_screen.dart';
import '../../features/split_history/split_day_history_screen.dart';
import '../auth/auth_repository.dart';
import '../checkin/checkin_service.dart';
import '../firestore/checkin_repository.dart';
import '../firestore/split_repository.dart';
import '../firestore/user_repository.dart';
import '../firestore/workout_log_repository.dart';
import '../sync/app_open_sync_service.dart';
import 'go_router_refresh_stream.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
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
      builder: (context, state) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final firestore = FirebaseFirestore.instance;
        final userRepo = UserRepository(firestore, uid);
        final splitRepo = SplitRepository(firestore, uid);
        final checkInRepo = CheckInRepository(firestore, uid);
        final workoutLogRepo = WorkoutLogRepository(firestore, uid);
        return HomeSyncGate(
          userRepo: userRepo,
          splitRepo: splitRepo,
          checkInRepo: checkInRepo,
          workoutLogRepo: workoutLogRepo,
          checkInService: CheckInService(checkInRepo, userRepo),
          syncService: AppOpenSyncService(checkInRepo, userRepo),
        );
      },
    ),
    GoRoute(
      path: '/split-editor',
      builder: (context, state) => SplitEditorScreen(
        splitRepo: SplitRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
      ),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => CalendarScreen(
        checkInRepo: CheckInRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
        initialMonth: DateTime.now().toUtc(),
      ),
    ),
    GoRoute(
      path: '/split-history/:dayId',
      builder: (context, state) => SplitDayHistoryScreen(
        workoutLogRepo: WorkoutLogRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
        splitDayId: state.pathParameters['dayId']!,
        splitDayLabel: state.uri.queryParameters['label'] ?? state.pathParameters['dayId']!,
      ),
    ),
    GoRoute(
      path: '/split-editor/:dayId',
      builder: (context, state) => SplitDayDetailScreen(
        splitRepo: SplitRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
        dayId: state.pathParameters['dayId']!,
        weekdayLabel: state.extra as String? ?? state.pathParameters['dayId']!,
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final firestore = FirebaseFirestore.instance;
        return ProfileScreen(
          userRepo: UserRepository(firestore, uid),
          authRepo: AuthRepository(FirebaseAuth.instance, (uid) => UserRepository(firestore, uid)),
        );
      },
    ),
  ],
);
