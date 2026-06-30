import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:milki_tech/core/ads/ad_service.dart';
import 'package:milki_tech/core/services/reward_service.dart';
import 'package:milki_tech/core/state/blog_store.dart';
import 'package:milki_tech/core/theme/app_palette.dart';
import 'package:milki_tech/core/theme/theme_service.dart';
import 'package:milki_tech/modules/settings/pages/about_page.dart';
import 'package:milki_tech/modules/settings/pages/contact_us_page.dart';
import 'package:milki_tech/modules/settings/pages/privacy_policy_page.dart';
import 'package:milki_tech/modules/settings/pages/publisher_info_page.dart';
import 'package:milki_tech/modules/settings/pages/push_notification_page.dart';
import 'package:milki_tech/widgets/privacy_options_button.dart';
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
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);
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

        final policy = store.adpExist.value;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const PrivacyOptionsButton(),
            if (policy)
              _SectionCard(
                initiallyExpanded: true,
                headerTitle: 'Rewards',
                headerSubtitle: 'Watch ads to unlock ad-free experience',
                background: palette.cardBg,
                children: [_RewardedAdTile()],
              ),

            const SizedBox(height: 12),
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
                    appStoreId: "com.milki.tech", // TODO replace
                  );
                }
              },
            ),
            _SimpleTile(
              icon: Icons.share_outlined,
              title: "Share with Friends",
              onTap: () {
                Share.share(
                  "Check out Milki Tech App: https://play.google.com/store/apps/details?id=com.milki.tech",
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

/// Tile for watching rewarded ads to get ad-free experience
class _RewardedAdTile extends StatefulWidget {
  const _RewardedAdTile();

  @override
  State<_RewardedAdTile> createState() => _RewardedAdTileState();
}

class _RewardedAdTileState extends State<_RewardedAdTile> {
  final _rewardService = RewardService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isAdFree = _rewardService.isAdFree();
    final remainingTime = _rewardService.getRemainingTimeString();

    return ListTile(
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(
        isAdFree ? Icons.block : Icons.play_circle_outline,
        color: isAdFree ? Colors.green : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        isAdFree ? 'Ad-Free Active' : 'Watch Ad for Ad-Free',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: isAdFree
          ? Text(
              'Remaining: $remainingTime',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            )
          : Text('Watch a short ad to get 1 hour of ad-free experience'),
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ElevatedButton.icon(
              onPressed: isAdFree ? null : _watchRewardedAd,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Watch Ad'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Future<void> _watchRewardedAd() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await AdService.instance.showRewarded(
        onReward: (reward) {
          // Reward is automatically granted by AdService
          setState(() {
            _isLoading = false;
          });

          Get.snackbar(
            'Reward Earned! 🎉',
            'You\'ve earned 1 hour of ad-free experience!',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        },
      );

      // If ad failed to show or was dismissed without reward
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error showing rewarded ad: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Error',
          'Failed to load ad. Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    }
  }
}

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
