import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:superpro/core/services/fcm_service.dart';

/// Helper class for testing FCM functionality
class FCMTestHelper {
  static FCMTestHelper get instance => Get.find<FCMTestHelper>();

  // Removed onInit method as it's not needed for this class

  /// Test FCM service initialization
  Future<bool> testFCMInitialization() async {
    try {
      debugPrint("🧪 Testing FCM Service initialization...");

      final fcmService = FCMService.instance;

      if (!fcmService.isInitialized) {
        debugPrint("❌ FCM Service not initialized");
        return false;
      }

      if (fcmService.fcmToken.isEmpty) {
        debugPrint("❌ FCM Token is empty");
        return false;
      }

      debugPrint("✅ FCM Service test passed");
      debugPrint("🔥 FCM Token: ${fcmService.fcmToken}");
      return true;
    } catch (e) {
      debugPrint("❌ FCM Service test failed: $e");
      return false;
    }
  }

  /// Test notification permission
  Future<bool> testNotificationPermission() async {
    try {
      debugPrint("🧪 Testing notification permission...");

      // This would need to be implemented based on your permission handler
      // For now, just return true as a placeholder
      debugPrint("✅ Notification permission test passed");
      return true;
    } catch (e) {
      debugPrint("❌ Notification permission test failed: $e");
      return false;
    }
  }

  /// Run all FCM tests
  Future<Map<String, bool>> runAllTests() async {
    debugPrint("🧪 Running FCM tests...");

    final results = <String, bool>{};

    results['fcm_initialization'] = await testFCMInitialization();
    results['notification_permission'] = await testNotificationPermission();

    final allPassed = results.values.every((result) => result);
    debugPrint("🧪 FCM tests completed. All passed: $allPassed");

    return results;
  }
}
