import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/split_day.dart';

const _weekdays = [
  ('monday', 'Monday'),
  ('tuesday', 'Tuesday'),
  ('wednesday', 'Wednesday'),
  ('thursday', 'Thursday'),
  ('friday', 'Friday'),
  ('saturday', 'Saturday'),
  ('sunday', 'Sunday'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.userRepo, required this.splitRepo});

  final UserRepository userRepo;
  final SplitRepository splitRepo;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _labelController = TextEditingController();
  String _selectedWeekday = _weekdays.first.$1;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_labelController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a split day name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.splitRepo.saveSplitDay(SplitDay(
        id: _selectedWeekday,
        label: _labelController.text.trim(),
        order: _weekdays.indexWhere((w) => w.$1 == _selectedWeekday),
        exercises: const [],
      ));
      await widget.userRepo.setOnboarded();
      if (mounted) GoRouter.maybeOf(context)?.refresh();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your first split day')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Text('Before you start tracking, set up at least one weekly split day. You can configure the rest — and add exercises — later in the Split Editor.'),
            const SizedBox(height: AppSpacing.md),
            DropdownButton<String>(
              key: const Key('onboarding_weekday_dropdown'),
              value: _selectedWeekday,
              items: [
                for (final w in _weekdays) DropdownMenuItem(value: w.$1, child: Text(w.$2)),
              ],
              onChanged: (value) => setState(() => _selectedWeekday = value!),
            ),
            TextField(
              key: const Key('onboarding_day_label_field'),
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Split day name (e.g. Chest & Shoulders)'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              Text(
                _error!,
                key: const Key('onboarding_label_error_text'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
