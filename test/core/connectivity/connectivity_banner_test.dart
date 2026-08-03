import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/connectivity/connectivity_banner.dart';

void main() {
  testWidgets('shows the offline banner when isOffline emits true, hides it otherwise', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(MaterialApp(
      home: ConnectivityBanner(
        isOffline: controller.stream,
        child: const Text('content'),
      ),
    ));

    expect(find.textContaining('offline'), findsNothing);

    controller.add(true);
    await tester.pump();

    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);

    controller.add(false);
    // Two pumps: the widget-removal rebuild settles a frame after the stream
    // event is delivered (the true->banner-shown transition settles in one
    // pump; the removal transition needs the extra frame to finalize).
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('offline'), findsNothing);
  });
}
