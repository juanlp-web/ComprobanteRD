import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/presentation/auth_gate.dart';

class MiComprobanteApp extends ConsumerWidget {
  const MiComprobanteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'ComprobanteRD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeConfig.seedColor),
      darkTheme: AppTheme.darkTheme(themeConfig.seedColor),
      themeMode: themeConfig.themeMode,
      home: const AuthGate(),
    );
  }
}
