import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:ethio_tips/core/state/blog_store.dart';
import 'package:ethio_tips/core/theme/theme_service.dart';
import 'package:ethio_tips/modules/settings/pages/about_page.dart';
import 'package:ethio_tips/modules/settings/pages/contact_us_page.dart';
import 'package:ethio_tips/modules/settings/pages/privacy_policy_page.dart';
import 'package:ethio_tips/modules/settings/pages/publisher_info_page.dart';
import 'package:ethio_tips/modules/settings/pages/push_notification_page.dart';
import 'package:ethio_tips/widgets/privacy_options_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isDark = Get.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), elevation: 0),
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
            const PrivacyOptionsButton(),

            const _SectionHeader("General"),
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              subtitle: "Better eyesight and power saving",
              value: isDark,
              onChanged: (v) {
                final themeSvc = Get.find<ThemeService>();
                themeSvc.set(v ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            _SimpleTile(
              icon: Icons.notifications_active_outlined,
              title: "Push Notifications",
              subtitle: "Manage push notification settings",
              onTap: () => Get.to(() => const PushNotificationPage()),
            ),

            const SizedBox(height: 24),

            const _SectionHeader("Cache"),
            _SimpleTile(
              icon: Icons.cleaning_services_outlined,
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
                  _snack("Cache", "Cache cleared successfully");
                } catch (e) {
                  _snack("Cache", "Failed to clear: $e");
                }
              },
            ),
            _SimpleTile(
              icon: Icons.history_outlined,
              title: "Clear Search History",
              onTap: () {
                store.clearRecentSearches();
                _snack("Search", "Search history cleared");
              },
            ),

            const SizedBox(height: 24),

            const _SectionHeader("Privacy"),
            _SimpleTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () => Get.to(
                () => PrivacyPolicyPage(
                  content: settings.privacyPolicy ?? "Not available",
                ),
              ),
            ),
            _SimpleTile(
              icon: Icons.info_outline,
              title: "About Us",
              onTap: () => Get.to(
                () => PublisherInfoPage(
                  content: settings.publisher_info ?? "Not available",
                ),
              ),
            ),
            _SimpleTile(
              icon: Icons.contact_mail_outlined,
              title: "Contact Us",
              onTap: () => Get.to(
                () => ContactUsPage(
                  content: settings.contactUs ?? "Not available",
                ),
              ),
            ),

            const SizedBox(height: 24),

            const _SectionHeader("The App"),
            _SimpleTile(
              icon: Icons.apps_outlined,
              title: "About App",
              onTap: () => Get.bottomSheet(
                AboutPage(content: settings.aboutUs ?? "Not available"),
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            _SimpleTile(
              icon: Icons.star_rate_outlined,
              title: "Rate Us",
              onTap: () async {
                final inAppReview = InAppReview.instance;
                if (await inAppReview.isAvailable()) {
                  inAppReview.requestReview();
                } else {
                  inAppReview.openStoreListing(
                    appStoreId: "com.tekopia.ethio_tips", // TODO replace
                  );
                }
              },
            ),
            _SimpleTile(
              icon: Icons.share_outlined,
              title: "Share with Friends",
              onTap: () {
                Share.share(
                  "Check out Ethio Tips App: https://play.google.com/store/apps/details?id=com.tekopia.ethio_tips",
                );
              },
            ),
            _SimpleTile(
              icon: Icons.more_horiz_outlined,
              title: "More Apps",
              onTap: () async {
                final uri = Uri.parse(
                  "https://play.google.com/store/apps/dev?id=5407164320419796496",
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      }),
    );
  }
}

/// Section headers like "General", "Privacy"
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Simple setting tile
class _SimpleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SimpleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// Switch tile (Dark mode)
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      ),
    );
  }
}
