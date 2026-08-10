import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

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
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            if (offline)
              Container(
                width: double.infinity,
                color: colorScheme.tertiaryContainer,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  "You're offline — showing cached data",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onTertiaryContainer),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
