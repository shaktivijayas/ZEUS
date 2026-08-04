import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
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

class SplitEditorScreen extends StatelessWidget {
  const SplitEditorScreen({super.key, required this.splitRepo});

  final SplitRepository splitRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split Editor')),
      body: StreamBuilder<List<SplitDay>>(
        stream: splitRepo.watchSplitDays(),
        builder: (context, snapshot) {
          final byId = {for (final d in snapshot.data ?? const <SplitDay>[]) d.id: d};
          return ListView(
            children: [
              for (final (id, name) in _weekdays)
                ListTile(
                  key: Key('weekday_row_$id'),
                  title: Text(name),
                  subtitle: Text(
                    byId[id] == null
                        ? 'Rest day — tap to configure'
                        : '${byId[id]!.label} · ${byId[id]!.exercises.length} exercises',
                  ),
                  onTap: () => context.push('/split-editor/$id', extra: name),
                ),
            ],
          );
        },
      ),
    );
  }
}
