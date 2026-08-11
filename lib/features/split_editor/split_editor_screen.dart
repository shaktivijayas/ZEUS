import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/apple_fitness_palette.dart';
import '../../core/widgets/apple_bottom_bar.dart';
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

/// Apple's real SF Pro can't be licensed/bundled for Android, so Inter — the
/// closest freely-licensed geometric sans and the community's standard
/// SF Pro stand-in on non-Apple platforms — is used for this screen's
/// Apple-styled headings and labels instead of the app-wide Roboto type
/// scale (AppTypography).
TextStyle _appleFont({required double fontSize, required FontWeight fontWeight, required Color color, double? letterSpacing}) {
  return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);
}

/// Displays user-entered split day labels in sentence case regardless of how
/// they were typed, without mutating the stored value.
String _sentenceCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class SplitEditorScreen extends StatelessWidget {
  const SplitEditorScreen({super.key, required this.splitRepo});

  final SplitRepository splitRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApplePalette.background,
      appBar: AppBar(
        backgroundColor: ApplePalette.background,
        elevation: 0,
        // Cupertino's plain chevron (not Material's arrow_back) with an
        // explicit accent color — like the title below, the app-wide
        // AppBarTheme would otherwise hand this a near-invisible color and
        // a heavier Material arrow shape.
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: ApplePalette.green, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        // Explicit color (not just `foregroundColor`) because the app-wide
        // AppBarTheme.titleTextStyle (Roboto, light-theme ink) otherwise
        // wins the merge and renders near-invisible on this black AppBar.
        title: Text('Split Editor', style: _appleFont(fontSize: 22, fontWeight: FontWeight.bold, color: ApplePalette.primaryText)),
      ),
      bottomNavigationBar: AppleBottomBar(
        active: AppleBottomTab.split,
        onSummary: () => Navigator.of(context).maybePop(),
        onCalendar: () => context.push('/calendar'),
        onCalories: () => context.push('/calories'),
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
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: Key('weekday_row_$id'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/split-editor/$id', extra: name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md + 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: _appleFont(fontSize: 17, fontWeight: FontWeight.bold, color: ApplePalette.primaryText)),
                                  const SizedBox(height: 2),
                                  byId[id] == null
                                      ? Text(
                                          'Rest day — tap to configure',
                                          style: _appleFont(fontSize: 15, fontWeight: FontWeight.w300, color: ApplePalette.secondaryText),
                                        )
                                      : Text.rich(
                                          TextSpan(
                                            style: _appleFont(fontSize: 15, fontWeight: FontWeight.w300, color: ApplePalette.secondaryText),
                                            children: [
                                              TextSpan(text: '${_sentenceCase(byId[id]!.label)} · '),
                                              TextSpan(
                                                text: '${byId[id]!.exercises.length} exercises',
                                                style: const TextStyle(color: ApplePalette.systemRed, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_forward, color: ApplePalette.chevron, size: 18),
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
