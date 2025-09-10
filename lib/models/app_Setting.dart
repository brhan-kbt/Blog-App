class AppSettings {
  final String? aboutUs;
  final String? privacyPolicy;
  final String? publisher_info;
  final String? appVersion;

  AppSettings({
    this.aboutUs,
    this.privacyPolicy,
    this.publisher_info,
    this.appVersion,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      aboutUs: json['about_us'],
      privacyPolicy: json['privacy_policy'],
      publisher_info: json['publisher_info'],
      appVersion: json['app_version'],
    );
  }
}
