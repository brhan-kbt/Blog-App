import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  final mode = ThemeMode.light.obs;
  static const _key = 'theme_mode';
  late final GetStorage _box;

  Future<void> init() async {
    await GetStorage.init();
    _box = GetStorage();

    final storedMode = _box.read(_key);
    switch (storedMode) {
      case 'light':
        mode.value = ThemeMode.light;
        break;
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      default:
        mode.value = ThemeMode.light;
    }

    Get.changeThemeMode(mode.value);
  }

  Future<void> set(ThemeMode m) async {
    mode.value = m;
    Get.changeThemeMode(m);
    await _box.write(_key, m.toString().split('.').last);
  }

  bool get isDark =>
      mode.value == ThemeMode.dark ||
      (mode.value == ThemeMode.system && Get.isDarkMode);
}
