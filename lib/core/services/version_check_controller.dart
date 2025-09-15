import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'version_check_service.dart';
import '../../widgets/update_dialog.dart';

class VersionCheckController extends GetxController {
  final VersionCheckService _versionCheckService = VersionCheckService.instance;

  /// Manually trigger version check (useful for testing or manual refresh)
  Future<void> checkForUpdateManually() async {
    try {
      final versionResponse = await _versionCheckService.checkForUpdate();

      if (versionResponse != null && versionResponse.data.needsUpdate) {
        debugPrint("🔄 Manual version check - update available");
        _showUpdateDialog(versionResponse.data);
      } else {
        Get.snackbar(
          'Version Check',
          'You are using the latest version!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check for updates: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  void _showUpdateDialog(versionData) {
    showDialog(
      context: Get.context!,
      barrierDismissible: !versionData.forceUpdate,
      builder: (context) => UpdateDialog(versionData: versionData),
    );
  }
}
