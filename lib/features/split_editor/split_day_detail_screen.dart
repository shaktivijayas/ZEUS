import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
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
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: '0');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(key: const Key('exercise_name_field'), controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(key: const Key('exercise_sets_field'), controller: setsController, decoration: const InputDecoration(labelText: 'Sets'), keyboardType: TextInputType.number),
            TextField(key: const Key('exercise_reps_field'), controller: repsController, decoration: const InputDecoration(labelText: 'Reps'), keyboardType: TextInputType.number),
            TextField(key: const Key('exercise_weight_field'), controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('add_exercise_confirm_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;

    final newExercise = ExerciseTarget(
      name: nameController.text.trim(),
      targetSets: int.tryParse(setsController.text) ?? 3,
      targetReps: int.tryParse(repsController.text) ?? 10,
      targetWeight: double.tryParse(weightController.text) ?? 0,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('split_day_label_field'),
                  controller: _labelController,
                  decoration: const InputDecoration(labelText: 'Day label (e.g. Chest & Shoulders)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const Key('split_day_save_label_button'),
                  onPressed: () => _saveLabel(day, _labelController.text.trim()),
                  child: const Text('Save label'),
                ),
                const SizedBox(height: 16),
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
