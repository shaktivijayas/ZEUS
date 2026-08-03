import 'package:flutter/material.dart';
import '../../core/firestore/split_repository.dart';
import '../../models/split_day.dart';

class SplitEditorScreen extends StatelessWidget {
  const SplitEditorScreen({super.key, required this.splitRepo});

  final SplitRepository splitRepo;

  Future<void> _addDay(BuildContext context) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New split day'),
        content: TextField(key: const Key('add_day_label_field'), controller: controller),
        actions: [
          TextButton(
            key: const Key('add_day_confirm_button'),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;

    final days = await splitRepo.watchSplitDays().first;
    await splitRepo.saveSplitDay(SplitDay(
      id: 'day-${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      order: days.length,
      exercises: const [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Editor'),
        actions: [
          IconButton(
            key: const Key('split_editor_add_day_button'),
            icon: const Icon(Icons.add),
            onPressed: () => _addDay(context),
          ),
        ],
      ),
      body: StreamBuilder<List<SplitDay>>(
        stream: splitRepo.watchSplitDays(),
        builder: (context, snapshot) {
          final days = snapshot.data ?? const [];
          return ListView(
            children: [
              for (final day in days)
                ListTile(
                  title: Text(day.label),
                  subtitle: Text('${day.exercises.length} exercises'),
                  trailing: IconButton(
                    key: Key('delete_day_${day.id}'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => splitRepo.deleteSplitDay(day.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
