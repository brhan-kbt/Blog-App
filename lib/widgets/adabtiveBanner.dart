import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sheger_tech/core/consent/consent_service.dart';
import '../core/ads/ad_service.dart';

class AdaptiveBannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  const AdaptiveBannerAdWidget({super.key, this.margin});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 AdaptiveBannerAdWidget - Cannot load ad: no consent");
      return;
    }

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        );

    if (size == null) {
      debugPrint("❌ Unable to get adaptive banner size.");
      return;
    }

    final BannerAd ad = BannerAd(
      size: size,
      adUnitId: AdService.bannerId, // your AdMob unit id
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ Failed to load adaptive banner: $error");
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );

    await ad.load();
    setState(() {
      _ad = ad;
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
