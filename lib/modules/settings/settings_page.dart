import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:jara_tech/core/theme/app_palette.dart';
import 'package:jara_tech/core/theme/theme_service.dart';
import 'package:jara_tech/modules/settings/pages/about_page.dart';
import 'package:jara_tech/modules/settings/pages/contact_us_page.dart';
import 'package:jara_tech/modules/settings/pages/privacy_policy_page.dart';
import 'package:jara_tech/modules/settings/pages/publisher_info_page.dart';
import 'package:jara_tech/modules/settings/pages/push_notification_page.dart';
import 'package:jara_tech/widgets/privacy_options_button.dart';
import 'package:path_provider/path_provider.dart';
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Scaffold(
      body: Obx(() {
        if (store.isLoadingSettings.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = store.settings.value;
        if (settings == null) {
          return const Center(child: Text("⚠️ No settings available"));
        }

        return CustomScrollView(
          slivers: [
            /// 🔹 Header with App Info
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 50,
              backgroundColor: theme.colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  bottom: 16,
                  end: 16,
                ),
                title: Align(
                  alignment: Alignment.bottomRight,
                  child: const Text(
                    "Settings",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.favoriteActive, palette.chipBg],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            /// 🔹 Body sections
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: const PrivacyOptionsButton(),
                ),

                /// General
                _SettingsSection(
                  title: "General",
                  subtitle: "Theme and notifications",
                  children: [
                    _SwitchTile(
                      icon: Icons.dark_mode,
                      title: "Dark Mode",
                      subtitle: "Better eyesight & power saving",
                      value: Get.isDarkMode,
                      onChanged: (v) {
                        Get.find<ThemeService>().set(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                    _SimpleTile(
                      icon: Icons.notifications_active,
                      title: "Push Notifications",
                      subtitle: "Manage notification preferences",
                      onTap: () => Get.to(() => const PushNotificationPage()),
                    ),
                  ],
                ),

                /// Cache
                _SettingsSection(
                  title: "Cache",
                  subtitle: "Clear caches & search history",
                  children: [
                    _SimpleTile(
                      icon: Icons.cleaning_services,
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
                          _snack('Cache', 'Failed: $e');
                        }
                      },
                    ),
                    _SimpleTile(
                      icon: Icons.history,
                      title: "Clear Search History",
                      subtitle: "Remove past searches",
                      onTap: () {
                        store.clearRecentSearches();
                        _snack('Search', 'History cleared');
                      },
                    ),
                  ],
                ),

                /// Privacy
                _SettingsSection(
                  title: "Privacy",
                  subtitle: "Policy, About & Contact",
                  children: [
                    _SimpleTile(
                      icon: Icons.privacy_tip,
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
                      icon: Icons.mail_outline,
                      title: "Contact Us",
                      onTap: () => Get.to(
                        () => ContactUsPage(
                          content: settings.contactUs ?? "Not available",
                        ),
                      ),
                    ),
                  ],
                ),

                /// The App
                _SettingsSection(
                  title: "The App",
                  subtitle: "Build version, rate & share",
                  children: [
                    _SimpleTile(
                      icon: Icons.phone_android,
                      title: "About App",
                      onTap: () => Get.bottomSheet(
                        AboutPage(content: settings.aboutUs ?? "Not available"),
                        backgroundColor: theme.colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    _SimpleTile(
                      icon: Icons.star_rate,
                      title: "Rate Us",
                      onTap: () async {
                        final inAppReview = InAppReview.instance;
                        if (await inAppReview.isAvailable()) {
                          inAppReview.requestReview();
                        } else {
                          inAppReview.openStoreListing(
                            appStoreId: "com.brhan.jaratech",
                          );
                        }
                      },
                    ),
                    _SimpleTile(
                      icon: Icons.share,
                      title: "Share to Friends",
                      onTap: () => Share.share(
                        "Check out Jara Tech: https://play.google.com/store/apps/details?id=com.brhan.jaratech",
                      ),
                    ),
                    _SimpleTile(
                      icon: Icons.apps,
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

                const SizedBox(height: 32),
              ]),
            ),
          ],
        );
      }),
    );
  }
}

/// 🔹 Section container
class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// 🔹 Simple tile with leading icon
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
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// 🔹 Switch tile with leading icon
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
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        child: Icon(icon, color: theme.colorScheme.secondary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
