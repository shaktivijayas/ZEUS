import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dark_mockup_palette.dart';
import '../../models/exercise_target.dart';
import '../../models/split_day.dart';

InputDecoration _darkFieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: DarkMockupPalette.mutedText),
  filled: true,
  fillColor: DarkMockupPalette.card,
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: 16,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: DarkMockupPalette.accent, width: 1.5),
  ),
);

Widget _fieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
);

class SplitDayDetailScreen extends StatefulWidget {
  const SplitDayDetailScreen({
    super.key,
    required this.splitRepo,
    required this.dayId,
    required this.weekdayLabel,
  });

  final SplitRepository splitRepo;
  final String dayId;
  final String weekdayLabel;

  @override
  State<SplitDayDetailScreen> createState() => _SplitDayDetailScreenState();
}

class _SplitDayDetailScreenState extends State<SplitDayDetailScreen> {
  final _labelController = TextEditingController();
  bool _controllerSeeded = false;
  String? _labelError;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveLabel(SplitDay? existing, String label) async {
    if (label.isEmpty) {
      setState(() => _labelError = 'Enter a day label.');
      return;
    }
    setState(() => _labelError = null);
    await widget.splitRepo.saveSplitDay(
      SplitDay(
        id: widget.dayId,
        label: label,
        order: existing?.order ?? 0,
        exercises: existing?.exercises ?? const [],
      ),
    );
  }

  Future<void> _clearDay() async {
    await widget.splitRepo.deleteSplitDay(widget.dayId);
  }

  Future<void> _addExercise(SplitDay day) async {
    final values = await showDialog<_NewExerciseValues>(
      context: context,
      builder: (context) => const _AddExerciseDialog(),
    );

    if (values == null) return;

    final newExercise = ExerciseTarget(
      name: values.name.trim(),
      targetSets: int.tryParse(values.sets) ?? 3,
      targetReps: int.tryParse(values.reps) ?? 10,
      targetWeight: double.tryParse(values.weight) ?? 0,
      order: day.exercises.length,
    );

    await widget.splitRepo.saveSplitDay(
      day.copyWith(exercises: [...day.exercises, newExercise]),
    );
  }

  Future<void> _deleteExercise(SplitDay day, int index) async {
    final updated = [...day.exercises]..removeAt(index);
    await widget.splitRepo.saveSplitDay(day.copyWith(exercises: updated));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkMockupPalette.background,
      appBar: AppBar(
        backgroundColor: DarkMockupPalette.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.weekdayLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<SplitDay>>(
        stream: widget.splitRepo.watchSplitDays(),
        builder: (context, snapshot) {
          final days = snapshot.data ?? const <SplitDay>[];
          SplitDay? day;
          for (final d in days) {
            if (d.id == widget.dayId) day = d;
          }

          if (!_controllerSeeded && day != null) {
            _labelController.text = day.label;
            _controllerSeeded = true;
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Day label'),
                TextField(
                  key: const Key('split_day_label_field'),
                  controller: _labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _darkFieldDecoration('e.g. Chest & Shoulders'),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_labelError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      _labelError!,
                      key: const Key('split_day_label_error_text'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    key: const Key('split_day_save_label_button'),
                    onPressed: () =>
                        _saveLabel(day, _labelController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DarkMockupPalette.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save label',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Text(
                      'Exercises',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: DarkMockupPalette.accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('add_exercise_button'),
                        customBorder: const CircleBorder(),
                        onTap: day == null ? null : () => _addExercise(day!),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.add, color: Colors.black, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < (day?.exercises.length ?? 0); i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Container(
                            decoration: BoxDecoration(
                              color: DarkMockupPalette.card,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center,
                                  color: DarkMockupPalette.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day!.exercises[i].name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${day.exercises[i].targetSets}x${day.exercises[i].targetReps} @ ${day.exercises[i].targetWeight}kg',
                                        style: const TextStyle(
                                          color: DarkMockupPalette.mutedText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: Key('delete_exercise_$i'),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: DarkMockupPalette.mutedText,
                                  ),
                                  onPressed: () => _deleteExercise(day!, i),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (day != null) ...[
                  TextButton(
                    key: const Key('view_history_button'),
                    onPressed: () => context.push(
                      '/split-history/${widget.dayId}?label=${Uri.encodeComponent(widget.weekdayLabel)}',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: DarkMockupPalette.accent,
                    ),
                    child: const Text('View history'),
                  ),
                  TextButton(
                    key: const Key('clear_day_button'),
                    onPressed: _clearDay,
                    style: TextButton.styleFrom(
                      foregroundColor: DarkMockupPalette.mutedText,
                    ),
                    child: const Text('Clear this day (mark as rest day)'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Raw field values entered in [_AddExerciseDialog]; parsed by the caller
/// once the dialog (and its controllers) have been popped.
class _NewExerciseValues {
  const _NewExerciseValues({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  final String name;
  final String sets;
  final String reps;
  final String weight;
}

/// Owns its own TextEditingControllers so Flutter disposes them via the
/// framework's normal State lifecycle — only once this dialog's Element is
/// actually unmounted, which happens after the dialog's exit transition
/// completes. Disposing controllers manually right after `showDialog`
/// resolves races that transition (the popped route's Future completes
/// before its widgets are removed), so ownership lives here instead.
class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '0');
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Enter an exercise name.');
      return;
    }
    Navigator.of(context).pop(
      _NewExerciseValues(
        name: _nameController.text,
        sets: _setsController.text,
        reps: _repsController.text,
        weight: _weightController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DarkMockupPalette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'New Exercise',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Name'),
            TextField(
              key: const Key('exercise_name_field'),
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _darkFieldDecoration('Name'),
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _nameError!,
                  key: const Key('exercise_name_error_text'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _fieldLabel('Sets'),
            TextField(
              key: const Key('exercise_sets_field'),
              controller: _setsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _darkFieldDecoration('Sets'),
            ),
            const SizedBox(height: AppSpacing.md),
            _fieldLabel('Reps'),
            TextField(
              key: const Key('exercise_reps_field'),
              controller: _repsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _darkFieldDecoration('Reps'),
            ),
            const SizedBox(height: AppSpacing.md),
            _fieldLabel('Weight (kg)'),
            TextField(
              key: const Key('exercise_weight_field'),
              controller: _weightController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _darkFieldDecoration('Weight (kg)'),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            key: const Key('add_exercise_confirm_button'),
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkMockupPalette.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
