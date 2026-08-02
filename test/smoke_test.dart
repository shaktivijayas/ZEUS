import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus/main.dart';

void main() {
  testWidgets('app boots and shows the auth stub', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZeusApp()));
    await tester.pumpAndSettle();

    expect(find.text('Auth'), findsOneWidget);
  });
}
