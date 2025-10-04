import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gold_tech/widgets/privacy_options_button.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:gold_tech/modules/settings/pages/push_notification_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gold_tech/core/theme/app_palette.dart';
import 'package:gold_tech/core/theme/theme_service.dart';
import 'package:gold_tech/modules/settings/pages/about_page.dart';
import 'package:gold_tech/modules/settings/pages/contact_us_page.dart';
import 'package:gold_tech/modules/settings/pages/privacy_policy_page.dart';
import 'package:gold_tech/modules/settings/pages/publisher_info_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/blog_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);
    final isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (store.isLoadingSettings.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xffed761c),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Settings...',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final settings = store.settings.value;
        if (settings == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No settings available",
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Options Button
                PrivacyOptionsButton(),

                const SizedBox(height: 24),

                // General Section
                _SectionHeader(
                  icon: Icons.settings,
                  title: 'General',
                  subtitle: 'Theme and notification preferences',
                ),
                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.sunny,
                      title: 'Dark Mode',
                      subtitle: 'Better eyesight and power saving',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (v) {
                          final themeSvc = Get.find<ThemeService>();
                          themeSvc.set(v ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeColor: const Color(0xffed761c),
                      ),
                      onTap: () {
                        final themeSvc = Get.find<ThemeService>();
                        themeSvc.set(
                          !isDark ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.notifications,
                      title: 'Push Notification',
                      subtitle: 'Manage push notification settings',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xffed761c).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: const Color(0xffed761c),
                        ),
                      ),
                      onTap: () => Get.to(() => PushNotificationPage()),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Cache Section
                _SectionHeader(
                  icon: Icons.storage,
                  title: 'Storage',
                  subtitle: 'Clear cache and search history',
                ),
                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.delete,
                      title: 'Clear Cache',
                      subtitle: 'Free up storage space',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                      onTap: () async {
                        try {
                          await GetStorage().erase();
                          imageCache.clear();
                          imageCache.clearLiveImages();
                          final tempDir = await getTemporaryDirectory();
                          if (tempDir.existsSync()) {
                            tempDir.deleteSync(recursive: true);
                          }
                          _snack('Success', 'Cache cleared successfully');
                        } catch (e) {
                          _snack('Error', 'Failed to clear cache: $e');
                        }
                      },
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.search_off,
                      title: 'Clear Search History',
                      subtitle: 'Remove all recent searches',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                      onTap: () {
                        store.clearRecentSearches();
                        _snack('Success', 'Search history cleared');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Privacy Section
                _SectionHeader(
                  icon: Icons.security,
                  title: 'Privacy & Legal',
                  subtitle: 'Privacy policy and contact information',
                ),
                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.edit_document,
                      title: 'Privacy Policy',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => Get.to(
                        () => PrivacyPolicyPage(
                          content: settings.privacyPolicy ?? "Not available",
                        ),
                      ),
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.info,
                      title: 'About Us',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () => Get.to(
                        () => PublisherInfoPage(
                          content: settings.publisher_info ?? "Not available",
                        ),
                      ),
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.message,
                      title: 'Contact Us',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.purple,
                        ),
                      ),
                      onTap: () => Get.to(
                        () => ContactUsPage(
                          content: settings.contactUs ?? "Not available",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // App Section
                _SectionHeader(
                  icon: Icons.phone_android,
                  title: 'The App',
                  subtitle: 'Version, rating, and sharing',
                ),
                _SettingsCard(
                  children: [
                    _SettingTile(
                      icon: Icons.apps,
                      title: 'About App',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xffed761c).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: const Color(0xffed761c),
                        ),
                      ),
                      onTap: () => Get.bottomSheet(
                        AboutPage(content: settings.aboutUs ?? "Not available"),
                        backgroundColor: isDark
                            ? Colors.grey[900]
                            : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                      ),
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.star,
                      title: 'Rate Us',
                      subtitle: 'Share your feedback',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.amber,
                        ),
                      ),
                      onTap: () async {
                        final inAppReview = InAppReview.instance;
                        if (await inAppReview.isAvailable()) {
                          inAppReview.requestReview();
                        } else {
                          inAppReview.openStoreListing(
                            appStoreId: "com.brhan.goldtech",
                          );
                        }
                      },
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.share,
                      title: 'Share to Friends',
                      subtitle: 'Spread the word',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () {
                        Share.share(
                          "Check out Gold Tech App: https://play.google.com/store/apps/details?id=com.brhan.goldtech",
                        );
                      },
                    ),
                    _Divider(),
                    _SettingTile(
                      icon: Icons.apps,
                      title: 'More Apps',
                      subtitle: 'Discover our other applications',
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () async {
                        final uri = Uri.parse(
                          "https://play.google.com/store/apps/dev?id=5407164320419796496",
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          throw 'Could not launch $uri';
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // App Version
                // Center(
                //   child: Text(
                //     'Version ${settings.appVersion ?? "1.0.0"}',
                //     style: TextStyle(
                //       color: isDark ? Colors.white54 : Colors.grey[600],
                //       fontSize: 14,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xffed761c).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xffed761c)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xffed761c).withOpacity(0.1),
        highlightColor: const Color(0xffed761c).withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffed761c).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xffed761c)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Html(
                      data: title,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(16),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      },
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Html(
                        data: subtitle!,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(12),
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    );
  }
}
