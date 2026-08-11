import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/split_repository.dart';
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

class SplitEditorScreen extends StatelessWidget {
  const SplitEditorScreen({super.key, required this.splitRepo});

  final SplitRepository splitRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkMockupPalette.background,
      appBar: AppBar(
        backgroundColor: DarkMockupPalette.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Split Editor', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<SplitDay>>(
        stream: splitRepo.watchSplitDays(),
        builder: (context, snapshot) {
          final byId = {for (final d in snapshot.data ?? const <SplitDay>[]) d.id: d};
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final (id, name) in _weekdays)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Material(
                    color: DarkMockupPalette.card,
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
                              decoration: const BoxDecoration(color: DarkMockupPalette.cardAlt, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(
                                name.substring(0, 2).toUpperCase(),
                                style: const TextStyle(color: DarkMockupPalette.accent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text(
                                    byId[id] == null
                                        ? 'Rest day — tap to configure'
                                        : '${byId[id]!.label} · ${byId[id]!.exercises.length} exercises',
                                    style: const TextStyle(color: DarkMockupPalette.mutedText, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: DarkMockupPalette.mutedText),
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
