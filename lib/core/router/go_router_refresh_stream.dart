import 'dart:async';
import 'package:flutter/foundation.dart';

/// Turns a Stream into a Listenable so GoRouter can re-run its redirect
/// callback whenever the stream emits — used here to re-run redirect on
/// every Firebase auth state change (sign-in AND sign-out), so no call
/// site needs to remember to call GoRouter.refresh() manually.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
