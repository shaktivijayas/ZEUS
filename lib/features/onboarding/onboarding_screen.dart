import 'package:flutter/material.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../models/split_day.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.userRepo, required this.splitRepo});

  final UserRepository userRepo;
  final SplitRepository splitRepo;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _labelController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_labelController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    await widget.splitRepo.saveSplitDay(SplitDay(
      id: 'day-${DateTime.now().microsecondsSinceEpoch}',
      label: _labelController.text.trim(),
      order: 0,
      exercises: const [],
    ));
    await widget.userRepo.setOnboarded();

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your first split day')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Before you start tracking, add at least one split day. You can add exercises and more days later.'),
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding_day_label_field'),
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Split day name (e.g. Chest & Shoulders)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('onboarding_save_button'),
              onPressed: _saving ? null : _save,
              child: const Text('Save and continue'),
            ),
          ],
        ),
      ),
    );
  }
}
