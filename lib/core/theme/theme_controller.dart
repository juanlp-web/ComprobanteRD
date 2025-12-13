import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

const _seedColorPreferenceKey = 'theme_seed_color';
const _themeModePreferenceKey = 'theme_mode';

class ThemeConfig {
  const ThemeConfig({
    required this.seedColor,
    this.themeMode = ThemeMode.light,
  });

  final Color seedColor;
  final ThemeMode themeMode;

  ThemeConfig copyWith({Color? seedColor, ThemeMode? themeMode}) {
    return ThemeConfig(
      seedColor: seedColor ?? this.seedColor,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ThemeConfig &&
        other.seedColor.value == seedColor.value &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => Object.hash(seedColor.value, themeMode);
}

class ThemeController extends StateNotifier<ThemeConfig> {
  ThemeController()
      : super(
          const ThemeConfig(seedColor: AppTheme.defaultSeedColor),
        ) {
    _loadSeedColor();
  }

  SharedPreferences? _cachedPreferences;

  Future<SharedPreferences> get _preferences async {
    return _cachedPreferences ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadSeedColor() async {
    final prefs = await _preferences;
    final storedColor = prefs.getInt(_seedColorPreferenceKey);
    final storedThemeMode = prefs.getString(_themeModePreferenceKey);
    
    ThemeMode themeMode = ThemeMode.light;
    if (storedThemeMode != null) {
      switch (storedThemeMode) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
          themeMode = ThemeMode.system;
          break;
        default:
          themeMode = ThemeMode.light;
      }
    }
    
    if (mounted) {
      state = ThemeConfig(
        seedColor: storedColor != null ? Color(storedColor) : AppTheme.defaultSeedColor,
        themeMode: themeMode,
      );
    }
  }

  Future<void> updateSeedColor(Color seedColor) async {
    if (state.seedColor.value == seedColor.value) {
      return;
    }

    state = state.copyWith(seedColor: seedColor);
    final prefs = await _preferences;
    await prefs.setInt(_seedColorPreferenceKey, seedColor.value);
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    if (state.themeMode == themeMode) {
      return;
    }

    state = state.copyWith(themeMode: themeMode);
    final prefs = await _preferences;
    String modeString;
    switch (themeMode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await prefs.setString(_themeModePreferenceKey, modeString);
  }

  void toggleThemeMode() {
    final currentMode = state.themeMode;
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isCurrentlyDark = currentMode == ThemeMode.dark ||
        (currentMode == ThemeMode.system && brightness == Brightness.dark);
    
    final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    updateThemeMode(newMode);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeConfig>(
  (ref) => ThemeController(),
);
