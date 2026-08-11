import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/apple_fitness_palette.dart';
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
      backgroundColor: ApplePalette.background,
      appBar: AppBar(
        backgroundColor: ApplePalette.background,
        foregroundColor: ApplePalette.primaryText,
        elevation: 0,
        title: const Text('Split Editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<List<SplitDay>>(
        stream: splitRepo.watchSplitDays(),
        builder: (context, snapshot) {
          final byId = {for (final d in snapshot.data ?? const <SplitDay>[]) d.id: d};
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final (id, name) in _weekdays)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: ApplePalette.card,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: Key('weekday_row_$id'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/split-editor/$id', extra: name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(color: ApplePalette.background, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(
                                name.substring(0, 2).toUpperCase(),
                                style: const TextStyle(color: ApplePalette.green, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: ApplePalette.primaryText, fontWeight: FontWeight.bold, fontSize: 17)),
                                  const SizedBox(height: 2),
                                  byId[id] == null
                                      ? const Text(
                                          'Rest day — tap to configure',
                                          style: TextStyle(color: ApplePalette.secondaryText, fontSize: 15),
                                        )
                                      : Text.rich(
                                          TextSpan(
                                            style: const TextStyle(color: ApplePalette.secondaryText, fontSize: 15),
                                            children: [
                                              TextSpan(text: '${byId[id]!.label} · '),
                                              TextSpan(
                                                text: '${byId[id]!.exercises.length} exercises',
                                                style: const TextStyle(color: ApplePalette.pink, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: ApplePalette.dateGray),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
