import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  final mode = ThemeMode.light.obs;
  static const _key = 'theme_mode';
  late final GetStorage _box;

  Future<void> init() async {
    _box = GetStorage();

    final storedMode = _box.read<String>(_key);
    debugPrint("🎨 ThemeService - Stored theme from box: $storedMode");

    switch (storedMode) {
      case 'dark':
        mode.value = ThemeMode.dark;
        debugPrint("🎨 ThemeService - Setting DARK mode");
        break;
      case 'system':
        mode.value = ThemeMode.system;
        debugPrint("🎨 ThemeService - Setting SYSTEM mode");
        break;
      case 'light':
      default:
        mode.value = ThemeMode.light;
        debugPrint("🎨 ThemeService - Setting LIGHT mode (default)");
    }

    debugPrint("🎨 ThemeService - Final theme mode: ${mode.value}");
    debugPrint("🎨 ThemeService - IsDark: $isDark");
    Get.changeThemeMode(mode.value);
  }

  Future<void> set(ThemeMode m) async {
    mode.value = m;
    debugPrint("💾 Saving theme 1: $m");

    Get.changeThemeMode(m);

    final value = m.toString().split('.').last; // "light" | "dark" | "system"
    debugPrint("💾 Saving theme: $value");
    await _box.write(_key, value);
  }

  bool get isDark {
    final result =
        mode.value == ThemeMode.dark ||
        (mode.value == ThemeMode.system && Get.isDarkMode);
    debugPrint(
      "🎨 ThemeService - isDark getter: mode=${mode.value}, Get.isDarkMode=${Get.isDarkMode}, result=$result",
    );
    return result;
  }
}
