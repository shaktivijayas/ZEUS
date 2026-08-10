import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces DESIGN.md's "Don't apply raw hex values directly in widgets —
/// resolve through Theme.of(context).colorScheme roles" rule (and its
/// spacing-token equivalent) across every screen, not just the theme layer.
void main() {
  test('screens resolve color and spacing through design tokens, not raw literals', () {
    final targets = [
      ...Directory('lib/features').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
      File('lib/core/connectivity/connectivity_banner.dart'),
    ];

    final rawColorLiteral = RegExp(r'Color\(0x');
    final materialColorsUsage = RegExp(r'\bColors\.');
    final edgeInsetsCall = RegExp(r'EdgeInsets\.\w+\(([^()]*)\)');
    final appSpacingToken = RegExp(r'AppSpacing\.\w+');
    final bareZero = RegExp(r'\b0\b');

    final violations = <String>[];

    for (final file in targets) {
      final content = file.readAsStringSync();

      if (rawColorLiteral.hasMatch(content)) {
        violations.add('${file.path}: raw Color(0x...) literal — use a ColorScheme role instead');
      }
      if (materialColorsUsage.hasMatch(content)) {
        violations.add('${file.path}: raw Colors.* usage — use Theme.of(context).colorScheme instead');
      }
      for (final match in edgeInsetsCall.allMatches(content)) {
        final withoutTokens = match.group(1)!.replaceAll(appSpacingToken, '').replaceAll(bareZero, '');
        if (RegExp(r'\d').hasMatch(withoutTokens)) {
          violations.add('${file.path}: hardcoded EdgeInsets value (${match.group(0)}) — use AppSpacing instead');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
