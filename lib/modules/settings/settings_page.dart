import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:abay_tips/core/theme/theme_service.dart';
import 'package:abay_tips/modules/settings/pages/about_page.dart';
import 'package:abay_tips/modules/settings/pages/contact_us_page.dart';
import 'package:abay_tips/modules/settings/pages/privacy_policy_page.dart';
import 'package:abay_tips/modules/settings/pages/publisher_info_page.dart';
import 'package:abay_tips/modules/settings/pages/push_notification_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (store.isLoadingSettings.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = store.settings.value;
        if (settings == null) {
          return const Center(child: Text("No settings available"));
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            /// 🔹 General
            SettingsSection(
              title: "General",
              subtitle: "Theme and notifications",
              children: [
                SettingsSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  title: "Dark Mode",
                  subtitle: "Better eyesight and power saving",
                  value: isDark,
                  onChanged: (v) {
                    Get.find<ThemeService>().set(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.notifications_active_rounded,
                  title: "Push Notification",
                  subtitle: "Manage push notification settings",
                  onTap: () => Get.to(() => const PushNotificationPage()),
                ),
              ],
            ),

            /// 🔹 Cache
            SettingsSection(
              title: "Cache",
              subtitle: "Clear caches, search history",
              children: [
                SettingsTile(
                  icon: Icons.cleaning_services_rounded,
                  title: "Clear Cache",
                  subtitle: "Free up space",
                  onTap: () async {
                    try {
                      await GetStorage().erase();
                      imageCache.clear();
                      imageCache.clearLiveImages();
                      final tempDir = await getTemporaryDirectory();
                      if (tempDir.existsSync()) {
                        tempDir.deleteSync(recursive: true);
                      }
                      _snack('Cache', 'Cache cleared successfully');
                    } catch (e) {
                      _snack('Cache', 'Failed to clear: $e');
                    }
                  },
                ),
                SettingsTile(
                  icon: Icons.history_rounded,
                  title: "Clear search history",
                  onTap: () {
                    store.clearRecentSearches();
                    _snack('Search', 'Search history cleared');
                  },
                ),
              ],
            ),

            /// 🔹 Privacy
            SettingsSection(
              title: "Privacy",
              subtitle: "Policies and company info",
              children: [
                SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: "Privacy Policy",
                  onTap: () => Get.to(
                    () => PrivacyPolicyPage(
                      content: settings.privacyPolicy ?? "",
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: "About Us",
                  onTap: () => Get.to(
                    () => PublisherInfoPage(
                      content: settings.publisher_info ?? "",
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.support_agent_rounded,
                  title: "Contact Us",
                  onTap: () => Get.to(
                    () => ContactUsPage(content: settings.contactUs ?? ""),
                  ),
                ),
              ],
            ),

            /// 🔹 App Info
            SettingsSection(
              title: "The App",
              subtitle: "Build version, rate, share",
              children: [
                SettingsTile(
                  icon: Icons.apps_rounded,
                  title: "About App",
                  onTap: () => Get.bottomSheet(
                    AboutPage(content: settings.aboutUs ?? "Not available"),
                    backgroundColor: theme.colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.star_rate_rounded,
                  title: "Rate Us",
                  onTap: () async {
                    final inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    } else {
                      inAppReview.openStoreListing(
                        appStoreId: "com.birhanu.quiz",
                      );
                    }
                  },
                ),
                SettingsTile(
                  icon: Icons.share_rounded,
                  title: "Share with Friends",
                  onTap: () {
                    Share.share(
                      "Check out Abay Tips App: https://play.google.com/store/apps/details?id=com.birhanu.quiz",
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.apps_outage_rounded,
                  title: "More Apps",
                  onTap: () async {
                    final uri = Uri.parse(
                      "https://play.google.com/store/apps/dev?id=5407164320419796496",
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

//
// 🔹 Custom Widgets
//

class SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}
