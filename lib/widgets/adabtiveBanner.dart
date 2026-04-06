import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:risatech/core/consent/consent_service.dart';
import '../core/ads/ad_service.dart';

class AdaptiveBannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const AdaptiveBannerAdWidget({super.key, this.margin});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;
  bool _isLoading = false;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;
    _isLoading = true;

    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 No consent for ads");
      return;
    }

    final width = MediaQuery.of(context).size.width.truncate();

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (size == null) {
      debugPrint("❌ Failed to get adaptive size");
      return;
    }

    final ad = BannerAd(
      size: size,
      adUnitId: AdService.bannerId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
            _opacity = 1;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ Ad failed: $error");
          ad.dispose();
        },
      ),
    );

    await ad.load();

    if (!mounted) return;

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
    // 🚫 Don't render anything if not ready
    if (_ad == null) {
      return _buildPlaceholder();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }

  // ✨ Minimal modern placeholder (skeleton style)
  Widget _buildPlaceholder() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 10),
      height: 60,
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
