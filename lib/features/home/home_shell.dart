import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../invoice/presentation/list/invoice_list_page.dart';
import '../scanner/presentation/scanner_page.dart';
import '../settings/presentation/settings_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Escanear e-CF',
    'Mis comprobantes',
    'Configuración',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ScannerPage(isVisible: _currentIndex == 0),
      InvoiceListPage(
        onRequestScan: () => setState(() => _currentIndex = 0),
      ),
      const SettingsPage(),
    ];

    final themeConfig = ref.watch(themeControllerProvider);
    final isDarkMode = themeConfig.themeMode == ThemeMode.dark ||
        (themeConfig.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Modo claro' : 'Modo oscuro',
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleThemeMode();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Escanear',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Comprobantes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
