import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';
import '../../models/version_check_response.dart';

class VersionCheckService extends GetxService {
  static VersionCheckService get instance => Get.find<VersionCheckService>();

  final RxBool _isCheckingVersion = false.obs;
  bool get isCheckingVersion => _isCheckingVersion.value;

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  /// Check if the app needs an update
  Future<VersionCheckResponse?> checkForUpdate() async {
    if (_isCheckingVersion.value) return null;

    _isCheckingVersion.value = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      debugPrint('🔍 Platform: $platform');
      debugPrint('🔍 Current Version: $currentVersion');

      final url = '${ApiConfig.checkVersion}?version=$currentVersion';

      debugPrint('🔍 Checking app version: $currentVersion');
      debugPrint('🌐 API URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final versionResponse = VersionCheckResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );

        debugPrint(
          ' Version : ✅ Version check successful: ${versionResponse.data.message}',
        );
        debugPrint(
          ' Version : 📱 Current: ${versionResponse.data.currentVersion}',
        );
        debugPrint(
          ' Version : 🆕 Latest: ${versionResponse.data.latestVersion}',
        );
        debugPrint(
          ' Version : ⚠️ Needs Update: ${versionResponse.data.needsUpdate}',
        );
        debugPrint(
          ' Version : 🚨 Force Update: ${versionResponse.data.forceUpdate}',
        );

        return versionResponse;
      } else {
        debugPrint(
          '❌ Version check failed with status: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking app version: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    } finally {
      _isCheckingVersion.value = false;
    }
  }

  /// Get current app version info
  Future<PackageInfo> getCurrentVersionInfo() async {
    return await PackageInfo.fromPlatform();
  }
}
