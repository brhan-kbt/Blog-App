import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:rivo_tech/modules/settings/pages/push_notification_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rivo_tech/core/theme/app_palette.dart';
import 'package:rivo_tech/core/theme/theme_service.dart';
import 'package:rivo_tech/modules/settings/pages/about_page.dart';
import 'package:rivo_tech/modules/settings/pages/privacy_policy_page.dart';
import 'package:rivo_tech/modules/settings/pages/publisher_info_page.dart';
import 'package:rivo_tech/widgets/privacy_options_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/blog_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static void _showSnack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
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
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (store.isLoadingSettings.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = store.settings.value;
        if (settings == null) {
          return const Center(
            child: Text(
              "No settings available",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                _ProfileCard(palette: palette),

                const SizedBox(height: 24),

                // Quick Settings Section
                _SettingsSection(
                  title: "Quick Settings",
                  icon: Icons.settings,
                  children: [
                    _ModernSwitchTile(
                      icon: Icons.dark_mode,
                      title: "Dark Mode",
                      subtitle: "Better eyesight and power saving",
                      value: Get.isDarkMode,
                      onChanged: (v) {
                        final themeSvc = Get.find<ThemeService>();
                        themeSvc.set(v ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                    _ModernListTile(
                      icon: Icons.notifications,
                      title: "Push Notification",
                      subtitle: "Manage push notification settings",
                      onTap: () => Get.to(() => const PushNotificationPage()),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Storage Section
                _SettingsSection(
                  title: "Storage",
                  icon: Icons.storage,
                  children: [
                    _ModernListTile(
                      icon: Icons.cleaning_services,
                      title: "Clear Cache",
                      subtitle: "Free up storage space",
                      onTap: _clearCache,
                    ),
                    _ModernListTile(
                      icon: Icons.history,
                      title: "Clear Search History",
                      subtitle: "Remove all search records",
                      onTap: () {
                        store.clearRecentSearches();
                        _showSnack('Search', 'Search history cleared');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Privacy & Legal Section
                _SettingsSection(
                  title: "Privacy & Legal",
                  icon: Icons.security,
                  children: [
                    _ModernListTile(
                      icon: Icons.privacy_tip,
                      title: "Privacy Policy",
                      onTap: () => Get.to(
                        () => PrivacyPolicyPage(
                          content: settings.privacyPolicy ?? "Not available",
                        ),
                      ),
                    ),
                    _ModernListTile(
                      icon: Icons.people,
                      title: "About Us",
                      onTap: () => Get.to(
                        () => PublisherInfoPage(
                          content: settings.publisher_info ?? "Not available",
                        ),
                      ),
                    ),
                    const PrivacyOptionsButton(),
                  ],
                ),

                const SizedBox(height: 20),

                // App Section
                _SettingsSection(
                  title: "The App",
                  icon: Icons.phone_iphone,
                  children: [
                    _ModernListTile(
                      icon: Icons.info,
                      title: "About App",
                      onTap: () => Get.bottomSheet(
                        AboutPage(content: settings.aboutUs ?? "Not available"),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    _ModernListTile(
                      icon: Icons.star,
                      title: "Rate Us",
                      onTap: _rateApp,
                    ),
                    _ModernListTile(
                      icon: Icons.share,
                      title: "Share to Friends",
                      onTap: _shareApp,
                    ),
                    _ModernListTile(
                      icon: Icons.apps,
                      title: "More Apps",
                      onTap: _openMoreApps,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // App Version
                // Text(
                //   "Version ${settings.appVersion ?? '1.0.0'}",
                //   style: TextStyle(
                //     color: Theme.of(
                //       context,
                //     ).textTheme.bodySmall?.color?.withOpacity(0.6),
                //     fontSize: 14,
                //   ),
                // ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _clearCache() async {
    try {
      await GetStorage().erase();
      imageCache.clear();
      imageCache.clearLiveImages();
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      _showSnack('Success', 'Cache cleared successfully');
    } catch (e) {
      _showSnack('Error', 'Failed to clear cache: $e');
    }
  }

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      inAppReview.openStoreListing(appStoreId: "com.brhan.rivotech");
    }
  }

  void _shareApp() {
    Share.share(
      "Check out Rivo Tech App - Your ultimate tech companion! https://play.google.com/store/apps/details?id=com.brhan.rivotech",
    );
  }

  Future<void> _openMoreApps() async {
    final uri = Uri.parse(
      "https://play.google.com/store/apps/dev?id=5407164320419796496",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final AppPalette palette;

  const _ProfileCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withOpacity(0.1),
            palette.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Customize your app experience",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ModernListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Html(
        data: title,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(16),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        },
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ModernSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
