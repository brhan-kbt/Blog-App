class VersionCheckResponse {
  final bool success;
  final VersionData data;

  VersionCheckResponse({required this.success, required this.data});

  factory VersionCheckResponse.fromJson(Map<String, dynamic> json) {
    return VersionCheckResponse(
      success: json['success'] ?? false,
      data: VersionData.fromJson(json['data'] ?? {}),
    );
  }
}

class VersionData {
  final bool needsUpdate;
  final bool forceUpdate;
  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final String updateUrl;
  final String platform;
  final bool updateAvailable;
  final String message;

  VersionData({
    required this.needsUpdate,
    required this.forceUpdate,
    required this.currentVersion,
    required this.minVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.platform,
    required this.updateAvailable,
    required this.message,
  });

  factory VersionData.fromJson(Map<String, dynamic> json) {
    return VersionData(
      needsUpdate: json['needs_update'] ?? false,
      forceUpdate: json['force_update'] ?? false,
      currentVersion: json['current_version'] ?? '',
      minVersion: json['min_version'] ?? '',
      latestVersion: json['latest_version'] ?? '',
      updateUrl: json['update_url'] ?? '',
      platform: json['platform'] ?? '',
      updateAvailable: json['update_available'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
