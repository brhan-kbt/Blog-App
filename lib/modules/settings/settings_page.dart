import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qubee/core/theme/app_palette.dart';
import 'package:qubee/modules/settings/pages/about_page.dart';
import 'package:qubee/modules/settings/pages/privacy_policy_page.dart';
import 'package:qubee/modules/settings/pages/publisher_info_page.dart';
import 'package:qubee/modules/settings/pages/push_notification_page.dart';
import 'package:qubee/modules/settings/pages/text_size_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/blog_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    final isDark = Get.isDarkMode;
    final bg = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionCard(
              initiallyExpanded: true,
              headerTitle: 'General',
              headerSubtitle: 'Theme, text size and notifications',
              background: palette.cardBg,
              children: [
                _SwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Better eyesight and power saving',
                  value: isDark,
                  onChanged: (v) {
                    Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                _SimpleTile(
                  title: 'Text size',
                  subtitle: 'Preferred text size for content description',
                  onTap: () => Get.to(() => const TextSizePage()),
                ),
                _SimpleTile(
                  title: 'Push Notification',
                  subtitle: 'Manage push notification settings',
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      AppSettings.openAppSettings(
                        type: AppSettingsType.notification,
                      );
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SectionCard(
              headerTitle: 'Cache',
              headerSubtitle: 'Clear caches, search history',
              background: palette.cardBg,
              children: [
                _SimpleTile(
                  title: 'Clear Cache',
                  subtitle: 'Free up space',
                  onTap: () async {
                    try {
                      // Clear GetStorage
                      await GetStorage().erase();

                      // Clear Flutter image cache
                      imageCache.clear();
                      imageCache.clearLiveImages();

                      // Clear temp directory
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
                _SimpleTile(
                  title: 'Clear search history',
                  onTap: () {
                    store.clearRecentSearches();
                    _snack('Search', 'Search history cleared');
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SectionCard(
              headerTitle: 'Privacy',
              headerSubtitle: 'Privacy policy, publisher info',
              background: palette.cardBg,

              children: [
                _SimpleTile(
                  title: 'Privacy policy',
                  onTap: () => Get.to(() => const PrivacyPolicyPage()),
                  subtitle: 'Learn more about our privacy policy',
                ),
                _SimpleTile(
                  title: 'Publisher info',
                  subtitle: 'Learn about us',
                  onTap: () => Get.to(() => const PublisherInfoPage()),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SectionCard(
              headerTitle: 'About',
              headerSubtitle: 'Build version, rate, share',
              background: palette.cardBg,
              children: [
                _SimpleTile(
                  title: 'About',

                  onTap: () => {
                    // Modal Bottom Sheet
                    Get.bottomSheet(
                      const AboutPage(),
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                      ),
                    ),
                  },
                ),
                _SimpleTile(
                  title: 'Rate us',

                  onTap: () async {
                    final inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    } else {
                      inAppReview.openStoreListing(
                        appStoreId: "com.example.qubee",
                      ); // <-- replace
                    }
                  },
                ),
                _SimpleTile(
                  title: 'Share to friends',
                  onTap: () {
                    Share.share(
                      "Check out Qubee App: https://play.google.com/store/apps/details?id=com.example.qubee",
                    );
                  },
                ),
                _SimpleTile(
                  title: 'More apps',
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

            // subtle bottom spacer matching your screenshots
            Container(height: 12, color: bg.withOpacity(0)),
          ],
        ),
      ),
    );
  }

  static void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }
}

/// A polished expandable card that mirrors your screenshots:
/// - rounded 12
/// - subtle background
/// - header title + subtitle
/// - rotating chevron
/// - clean dividers between tiles
class _SectionCard extends StatefulWidget {
  final String headerTitle;
  final String? headerSubtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color? background;

  const _SectionCard({
    required this.headerTitle,
    this.headerSubtitle,
    required this.children,
    this.initiallyExpanded = false,
    this.background,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _ctr = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _rotate = Tween(
    begin: 0.0,
    end: .5,
  ).animate(CurvedAnimation(parent: _ctr, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    if (_expanded) _ctr.value = .5;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctr.forward() : _ctr.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).textTheme.bodySmall!.color?.withOpacity(.7),
    );

    return Material(
      color: widget.background ?? Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.headerTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.headerSubtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.headerSubtitle!, style: subtitleStyle),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotate,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),

              // content
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: _SectionChildren(children: widget.children),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }
}

/// Renders children with slim dividers like your screenshots.
class _SectionChildren extends StatelessWidget {
  final List<Widget> children;
  const _SectionChildren({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 0,
                endIndent: 0,
                color: Theme.of(context).dividerColor.withOpacity(.6),
              ),
          ],
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SimpleTile({required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return ListTile(
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(title, style: titleStyle),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
      visualDensity: const VisualDensity(vertical: -1),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return ListTile(
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(title, style: titleStyle),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
