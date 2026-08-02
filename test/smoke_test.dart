import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus/main.dart';

void main() {
  testWidgets('app boots and shows the auth screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZeusApp()));
    await tester.pump();

    expect(find.byKey(const Key('auth_submit_button')), findsOneWidget);
  });
}
