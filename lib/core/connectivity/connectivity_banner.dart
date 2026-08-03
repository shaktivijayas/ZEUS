import 'package:flutter/material.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.isOffline, required this.child});

  final Stream<bool> isOffline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: isOffline,
      initialData: false,
      builder: (context, snapshot) {
        final offline = snapshot.data ?? false;
        return Column(
          children: [
            if (offline)
              Container(
                width: double.infinity,
                color: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  "You're offline — showing cached data",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
