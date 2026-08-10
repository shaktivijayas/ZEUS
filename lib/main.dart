import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/connectivity/connectivity_banner.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/firebase/firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: ZeusApp()));
}

class ZeusApp extends StatelessWidget {
  ZeusApp({super.key});

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZEUS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) => ConnectivityBanner(
        isOffline: _connectivityService.isOffline,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
