import 'package:flutter/material.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/firestore/user_repository.dart';
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Longest streak: ${user.longestStreak}'),
                Text('Freezes remaining: ${user.freezesRemaining}'),
                Text('Freezes reset: ${user.freezesResetDate.toIso8601String().split('T').first}'),
                const SizedBox(height: 24),
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
