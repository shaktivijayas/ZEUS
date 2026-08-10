import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/exercise_target.dart';
import '../../models/split_day.dart';

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

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveLabel(SplitDay? existing, String label) async {
    if (label.isEmpty) return;
    await widget.splitRepo.saveSplitDay(SplitDay(
      id: widget.dayId,
      label: label,
      order: existing?.order ?? 0,
      exercises: existing?.exercises ?? const [],
    ));
  }

  Future<void> _clearDay() async {
    await widget.splitRepo.deleteSplitDay(widget.dayId);
  }

  Future<void> _addExercise(SplitDay day) async {
    final values = await showDialog<_NewExerciseValues>(
      context: context,
      builder: (context) => const _AddExerciseDialog(),
    );

    if (values == null || values.name.trim().isEmpty) return;

    final newExercise = ExerciseTarget(
      name: values.name.trim(),
      targetSets: int.tryParse(values.sets) ?? 3,
      targetReps: int.tryParse(values.reps) ?? 10,
      targetWeight: double.tryParse(values.weight) ?? 0,
      order: day.exercises.length,
    );

    await widget.splitRepo.saveSplitDay(day.copyWith(exercises: [...day.exercises, newExercise]));
  }

  Future<void> _deleteExercise(SplitDay day, int index) async {
    final updated = [...day.exercises]..removeAt(index);
    await widget.splitRepo.saveSplitDay(day.copyWith(exercises: updated));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.weekdayLabel)),
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
                TextField(
                  key: const Key('split_day_label_field'),
                  controller: _labelController,
                  decoration: const InputDecoration(labelText: 'Day label (e.g. Chest & Shoulders)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  key: const Key('split_day_save_label_button'),
                  onPressed: () => _saveLabel(day, _labelController.text.trim()),
                  child: const Text('Save label'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Text('Exercises', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      key: const Key('add_exercise_button'),
                      icon: const Icon(Icons.add),
                      onPressed: day == null ? null : () => _addExercise(day!),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < (day?.exercises.length ?? 0); i++)
                        ListTile(
                          title: Text(day!.exercises[i].name),
                          subtitle: Text('${day.exercises[i].targetSets}x${day.exercises[i].targetReps} @ ${day.exercises[i].targetWeight}kg'),
                          trailing: IconButton(
                            key: Key('delete_exercise_$i'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteExercise(day!, i),
                          ),
                        ),
                    ],
                  ),
                ),
                if (day != null) ...[
                  TextButton(
                    key: const Key('view_history_button'),
                    onPressed: () => context.push('/split-history/${widget.dayId}?label=${Uri.encodeComponent(widget.weekdayLabel)}'),
                    child: const Text('View history'),
                  ),
                  TextButton(
                    key: const Key('clear_day_button'),
                    onPressed: _clearDay,
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

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New exercise'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(key: const Key('exercise_name_field'), controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          TextField(key: const Key('exercise_sets_field'), controller: _setsController, decoration: const InputDecoration(labelText: 'Sets'), keyboardType: TextInputType.number),
          TextField(key: const Key('exercise_reps_field'), controller: _repsController, decoration: const InputDecoration(labelText: 'Reps'), keyboardType: TextInputType.number),
          TextField(key: const Key('exercise_weight_field'), controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('add_exercise_confirm_button'),
          onPressed: () => Navigator.of(context).pop(_NewExerciseValues(
            name: _nameController.text,
            sets: _setsController.text,
            reps: _repsController.text,
            weight: _weightController.text,
          )),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
