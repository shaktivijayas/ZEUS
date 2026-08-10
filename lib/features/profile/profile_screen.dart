import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/app_user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userRepo, required this.authRepo});

  final UserRepository userRepo;
  final AuthRepository authRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<AppUser?>(
        stream: userRepo.watchUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Longest streak: ${user.longestStreak}'),
                Text('Freezes remaining: ${user.freezesRemaining}'),
                Text('Freezes reset: ${user.freezesResetDate.toIso8601String().split('T').first}'),
                const SizedBox(height: AppSpacing.lg),
                if (user.calorieGoal != null) Text('Calorie goal: ${user.calorieGoal} kcal'),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  key: const Key('profile_calorie_goal_button'),
                  onPressed: () => context.push('/profile/calorie-goal'),
                  child: Text(user.calorieGoal == null ? 'Set calorie goal' : 'Edit calorie goal'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  key: const Key('profile_log_out_button'),
                  onPressed: () => authRepo.signOut(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
