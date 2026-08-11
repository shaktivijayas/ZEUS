import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dark_mockup_palette.dart';
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

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkMockupPalette.background,
      appBar: AppBar(
        backgroundColor: DarkMockupPalette.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Set up your first split day', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Before you start tracking, set up at least one weekly split day. You can configure the rest — and add exercises — later in the Split Editor.',
              style: TextStyle(color: DarkMockupPalette.mutedText),
            ),
            const SizedBox(height: AppSpacing.xl),
            _fieldLabel('Weekday'),
            Container(
              decoration: BoxDecoration(color: DarkMockupPalette.card, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('onboarding_weekday_dropdown'),
                  value: _selectedWeekday,
                  isExpanded: true,
                  dropdownColor: DarkMockupPalette.card,
                  iconEnabledColor: DarkMockupPalette.mutedText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: [
                    for (final w in _weekdays) DropdownMenuItem(value: w.$1, child: Text(w.$2)),
                  ],
                  onChanged: (value) => setState(() => _selectedWeekday = value!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _fieldLabel('Split day name'),
            TextField(
              key: const Key('onboarding_day_label_field'),
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Chest & Shoulders',
                hintStyle: const TextStyle(color: DarkMockupPalette.mutedText),
                filled: true,
                fillColor: DarkMockupPalette.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DarkMockupPalette.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  _error!,
                  key: const Key('onboarding_label_error_text'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                key: const Key('onboarding_save_button'),
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkMockupPalette.accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF3A3A3A),
                  disabledForegroundColor: DarkMockupPalette.mutedText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Save and continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
