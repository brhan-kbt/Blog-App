import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final AdSize size;
  const BannerAdWidget({super.key, this.margin, this.size = AdSize.banner});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      size: widget.size,
      adUnitId: AdService.bannerId,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _loaded = false);
        },
      ),
      request: const AdRequest(),
    )..load();
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
      decoration: BoxDecoration(
        color: Brightness.light == Theme.of(context).brightness
            ? const Color.fromARGB(255, 220, 255, 234)
            : Color.fromARGB(255, 207, 255, 209),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      margin: widget.margin ?? const EdgeInsets.only(top: 8, bottom: 8),
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
