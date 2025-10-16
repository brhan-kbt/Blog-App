import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:jira_tips/modules/settings/pages/contact_us_page.dart';
import 'package:jira_tips/modules/settings/pages/push_notification_page.dart';
import 'package:jira_tips/widgets/privacy_options_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jira_tips/core/theme/app_palette.dart';
import 'package:jira_tips/core/theme/theme_service.dart';
import 'package:jira_tips/modules/settings/pages/about_page.dart';
import 'package:jira_tips/modules/settings/pages/privacy_policy_page.dart';
import 'package:jira_tips/modules/settings/pages/publisher_info_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_settings/app_settings.dart';
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
      backgroundColor: Get.theme.colorScheme.surface,
      colorText: Get.theme.colorScheme.onSurface,
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
      backgroundColor: isDark ? Color(0xFF0F0F1E) : Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: isDark ? Colors.white : Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : Color(0xFF1A1A2E),
            ),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (store.isLoadingSettings.value) {
          return _buildLoadingShimmer();
        }

        final settings = store.settings.value;
        if (settings == null) {
          return _buildEmptyState();
        }

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with decorative elements
                _buildHeader(),
                const SizedBox(height: 24),

                // Privacy Options
                const PrivacyOptionsButton(),
                const SizedBox(height: 20),

                // General Section
                _ModernSectionCard(
                  icon: Icons.settings_rounded,
                  title: 'General',
                  subtitle: 'Appearance and notifications',
                  gradient: isDark
                      ? [Color(0xFF1A1A2E), Color(0xFF16213E)]
                      : [Color(0xFF667eea), Color(0xFF764ba2)],
                  children: [
                    _ModernSwitchTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Better for your eyes and battery',
                      value: isDark,
                      onChanged: (v) {
                        final themeSvc = Get.find<ThemeService>();
                        themeSvc.set(v ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                    _ModernSimpleTile(
                      icon: Icons.notifications_active_rounded,
                      title: 'Push Notification',
                      subtitle: 'Manage your notification preferences',
                      gradient: isDark
                          ? [Color(0xFFFF6221), Color(0xFFFFD700)]
                          : [Color(0xFFf093fb), Color(0xFFf5576c)],
                      onTap: () => Get.to(() => PushNotificationPage()),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cache Section
                _ModernSectionCard(
                  icon: Icons.storage_rounded,
                  title: 'Storage',
                  subtitle: 'Clear cache and search history',
                  gradient: isDark
                      ? [Color(0xFF0F3460), Color(0xFF1A1A2E)]
                      : [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  children: [
                    _ModernSimpleTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Clear Cache',
                      subtitle: 'Free up storage space',
                      gradient: isDark
                          ? [Color(0xFF00b4db), Color(0xFF0083b0)]
                          : [Color(0xFFa8edea), Color(0xFFfed6e3)],
                      onTap: () async {
                        try {
                          await GetStorage().erase();
                          imageCache.clear();
                          imageCache.clearLiveImages();
                          final tempDir = await getTemporaryDirectory();
                          if (tempDir.existsSync()) {
                            tempDir.deleteSync(recursive: true);
                          }
                          _snack('Success', 'Cache cleared successfully 🎉');
                        } catch (e) {
                          _snack('Error', 'Failed to clear cache');
                        }
                      },
                    ),
                    _ModernSimpleTile(
                      icon: Icons.history_rounded,
                      title: 'Clear Search History',
                      subtitle: 'Remove all recent searches',
                      gradient: isDark
                          ? [Color(0xFF834d9b), Color(0xFFd04ed6)]
                          : [Color(0xFFffecd2), Color(0xFFfcb69f)],
                      onTap: () {
                        store.clearRecentSearches();
                        _snack('Success', 'Search history cleared 🗑️');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Privacy Section
                _ModernSectionCard(
                  icon: Icons.security_rounded,
                  title: 'Privacy & Legal',
                  subtitle: 'Policies and information',
                  gradient: isDark
                      ? [Color(0xFF16213E), Color(0xFF0F3460)]
                      : [Color(0xFFfd746c), Color(0xFFff9068)],
                  children: [
                    _ModernSimpleTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Policy',
                      gradient: isDark
                          ? [Color(0xFF667eea), Color(0xFF764ba2)]
                          : [Color(0xFFa8edea), Color(0xFFfed6e3)],
                      onTap: () => Get.to(
                        () => PrivacyPolicyPage(
                          content: settings.privacyPolicy ?? "Not available",
                        ),
                      ),
                    ),
                    _ModernSimpleTile(
                      icon: Icons.business_center_rounded,
                      title: 'About Us',
                      gradient: isDark
                          ? [Color(0xFFf093fb), Color(0xFFf5576c)]
                          : [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      onTap: () => Get.to(
                        () => PublisherInfoPage(
                          content: settings.publisher_info ?? "Not available",
                        ),
                      ),
                    ),
                    _ModernSimpleTile(
                      icon: Icons.contact_support_rounded,
                      title: 'Contact Us',
                      gradient: isDark
                          ? [Color(0xFF4facfe), Color(0xFF00f2fe)]
                          : [Color(0xFFa8edea), Color(0xFFfed6e3)],
                      onTap: () => Get.to(
                        () => ContactUsPage(
                          content: settings.contactUs ?? "Not available",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // App Section
                _ModernSectionCard(
                  icon: Icons.apps_rounded,
                  title: 'About App',
                  subtitle: 'Version, rating, and sharing',
                  gradient: isDark
                      ? [Color(0xFF834d9b), Color(0xFFd04ed6)]
                      : [Color(0xFFff9a9e), Color(0xFFfecfef)],
                  children: [
                    _ModernSimpleTile(
                      icon: Icons.info_rounded,
                      title: 'App Information',
                      gradient: isDark
                          ? [Color(0xFF00b4db), Color(0xFF0083b0)]
                          : [Color(0xFFa8edea), Color(0xFFfed6e3)],
                      onTap: () => Get.bottomSheet(
                        AboutPage(content: settings.aboutUs ?? "Not available"),
                        backgroundColor: isDark
                            ? Color(0xFF1A1A2E)
                            : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.0),
                            topRight: Radius.circular(24.0),
                          ),
                        ),
                      ),
                    ),
                    _ModernSimpleTile(
                      icon: Icons.star_rate_rounded,
                      title: 'Rate Us',
                      gradient: isDark
                          ? [Color(0xFFFFD700), Color(0xFFFF6221)]
                          : [Color(0xFFf6d365), Color(0xFFfda085)],
                      onTap: () async {
                        final inAppReview = InAppReview.instance;
                        if (await inAppReview.isAvailable()) {
                          inAppReview.requestReview();
                        } else {
                          inAppReview.openStoreListing(
                            appStoreId: "com.brhan.jobs",
                          );
                        }
                      },
                    ),
                    _ModernSimpleTile(
                      icon: Icons.share_rounded,
                      title: 'Share with Friends',
                      gradient: isDark
                          ? [Color(0xFF667eea), Color(0xFF764ba2)]
                          : [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      onTap: () {
                        Share.share(
                          "🚀 Check out Jira Tips App - Master your Jira workflow! https://play.google.com/store/apps/details?id=com.brhan.jobs",
                        );
                      },
                    ),
                    _ModernSimpleTile(
                      icon: Icons.apps_outage_rounded,
                      title: 'More Apps',
                      gradient: isDark
                          ? [Color(0xFFf093fb), Color(0xFFf5576c)]
                          : [Color(0xFFa8edea), Color(0xFFfed6e3)],
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

                const SizedBox(height: 30),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Get.isDarkMode ? Colors.white70 : Color(0xFF666666),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your experience',
            style: TextStyle(
              fontSize: 12,
              color: Get.isDarkMode ? Colors.white54 : Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Get.isDarkMode
              ? [
                  Color(0xFF1A1A2E).withOpacity(0.8),
                  Color(0xFF16213E).withOpacity(0.8),
                ]
              : [
                  Color(0xFF667eea).withOpacity(0.1),
                  Color(0xFF764ba2).withOpacity(0.1),
                ],
        ),
      ),
      // child: Column(
      //   children: [
      //     Icon(
      //       Icons.rocket_launch_rounded,
      //       size: 40,
      //       color: Get.isDarkMode ? Color(0xFFFF6221) : Color(0xFF667eea),
      //     ),
      //     const SizedBox(height: 12),
      //     Text(
      //       'Jira Tips',
      //       style: TextStyle(
      //         fontSize: 18,
      //         fontWeight: FontWeight.w800,
      //         color: Get.isDarkMode ? Colors.white : Color(0xFF1A1A2E),
      //       ),
      //     ),
      //     const SizedBox(height: 4),
      //     Text(
      //       'Master Your Workflow',
      //       style: TextStyle(
      //         fontSize: 12,
      //         color: Get.isDarkMode ? Colors.white70 : Color(0xFF666666),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: List.generate(5, (index) => _buildShimmerCard()),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Get.isDarkMode ? Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? Color(0xFF16213E) : Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Get.isDarkMode
                            ? Color(0xFF16213E)
                            : Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Get.isDarkMode
                            ? Color(0xFF16213E)
                            : Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_suggest_rounded,
            size: 80,
            color: Get.isDarkMode ? Color(0xFFFF6221) : Color(0xFF667eea),
          ),
          SizedBox(height: 20),
          Text(
            'Settings Unavailable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Get.isDarkMode ? Colors.white : Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your connection',
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white70 : Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<Widget> children;

  const _ModernSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF0F0F1E) : Colors.white,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Children
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernSimpleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _ModernSimpleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Color(0xFF1A1A2E).withOpacity(0.5)
                  : Color(0xFFF8FAFD),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                SizedBox(width: 12),
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
                            fontSize: FontSize(15),
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Color(0xFF1A1A2E),
                          ),
                        },
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Html(
                          data: subtitle!,
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontSize: FontSize(12),
                              color: isDark
                                  ? Colors.white70
                                  : Color(0xFF666666),
                            ),
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : Color(0xFF888888),
                  ),
              ],
            ),
          ),
        ),
      ),
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
    final isDark = Get.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Color(0xFF1A1A2E).withOpacity(0.5)
                  : Color(0xFFF8FAFD),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Color(0xFF667eea), Color(0xFF764ba2)]
                          : [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF1A1A2E),
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Color(0xFF666666),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Color(0xFFFF6221),
                    activeTrackColor: Color(0xFFFF6221).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
