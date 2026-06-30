import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../state/blog_store.dart';

import '../config/ad_config.dart';
import '../consent/consent_service.dart';
import '../services/reward_service.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  bool get policy {
    try {
      if (Get.isRegistered<BlogStore>()) {
        return Get.find<BlogStore>().adpExist.value;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await _loadInterstitial();
    await _loadRewarded();
    await _loadRewardedInterstitial();
  }

  static String get bannerId {
    if (Platform.isIOS) return AdConfig.iosBanner;
    return AdConfig.androidBanner;
  }

  static String get interstitialId {
    if (Platform.isIOS) return AdConfig.iosInterstitial;
    return AdConfig.androidInterstitial;
  }

  static String get rewardedId {
    if (Platform.isIOS) return AdConfig.iosRewarded;
    return AdConfig.androidRewarded;
  }

  static String get appOpenId {
    if (Platform.isIOS) return AdConfig.iosAppOPen;
    return AdConfig.androidAppOPen;
  }

  static String get rewardedInterstitialId {
    if (Platform.isIOS) {
      return AdConfig.iosRewardedInterstitial;
    }
    return AdConfig.androidRewardedInterstitial;
  }

  AppOpenAd? _appOpenAd;

  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenId, // replace
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          debugPrint("OPen : ✅ AppOpenAd loaded");
        },
        onAdFailedToLoad: (error) {
          debugPrint("OPen : ❌ Failed to load AppOpenAd: $error");
        },
      ),
    );
  }

  Future<void> showAppOpenAd() async {
    // Check consent before showing ads
    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 AdService - Cannot show app open ad: no consent");
      return;
    }

    // Check if user has ad-free status
    if (RewardService().isAdFree()) {
      debugPrint(
        "🔒 AdService - User has ad-free status, skipping app open ad",
      );
      return;
    }

    if (_appOpenAd == null) {
      debugPrint("⚠️ Tried to show before loaded");
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("OPen : Ad dismissed");
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd(); // preload again
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("OPen : Failed to show ad: $error");
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  Future<void> _loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _loadRewarded() async {
    await RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  Future<void> _loadRewardedInterstitial() async {
    await RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _rewardedInterstitialAd = ad,
        onAdFailedToLoad: (_) => _rewardedInterstitialAd = null,
      ),
    );
  }

  Future<void> showRandomOpenAd() async {
    final choice = Random().nextInt(5); // 0 none, 1 interstitial, 2 rewarded

    print("Random choice: $choice");
    if (choice == 1) {
      await showInterstitial();
    } else if (choice == 2) {
      await showRewarded(onReward: (_) {});
    }
  }

  Future<int> showRandomBottomAd() async {
    final choice = Random().nextInt(1); // 0 none, 1 interstitial, 2 rewarded
    if (choice == 1) {
      return 1;
    }
    return 0;
  }

  Future<void> showInterstitial() async {
    // Check consent before showing ads
    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 AdService - Cannot show interstitial ad: no consent");
      return;
    }

    // Check if user has ad-free status
    if (RewardService().isAdFree()) {
      debugPrint(
        "🔒 AdService - User has ad-free status, skipping interstitial",
      );
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint("⚠️ AdService - Interstitial ad not loaded yet");
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  Future<void> showRewarded({
    required void Function(RewardItem) onReward,
  }) async {
    // Check consent before showing ads
    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 AdService - Cannot show rewarded ad: no consent");
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint("⚠️ AdService - Rewarded ad not loaded yet");
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
      },
    );
    if (policy) {
      // Show ad and grant reward when user completes it
      await ad.show(
        onUserEarnedReward: (_, reward) {
          debugPrint(
            "✅ AdService - User earned reward: ${reward.amount} ${reward.type}",
          );
          // Grant 60 minutes (1 hour) of ad-free experience
          RewardService().grantAdFreePeriod(60);
          onReward(reward);
        },
      );
    } else {
      await ad.show(onUserEarnedReward: (_, reward) => onReward(reward));
    }
  }

  Future<void> showAppResumeAd(BuildContext context) async {
    // Check consent before showing ads
    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 AdService - Cannot show app resume ad: no consent");
      if (context.mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final ad = _rewardedInterstitialAd;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        _loadRewardedInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        _loadRewardedInterstitial();
      },
    );
    await ad.show(onUserEarnedReward: (_, reward) {});
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  /// Show interstitial ad between content transitions
  /// This is acceptable per AdMob policy when shown after user actions
  /// (e.g., after reading multiple articles)
  Future<void> showInterstitialAfterContentTransition() async {
    // Check consent before showing ads
    final canRequestAds = await ConsentService().checkCanRequestAds();
    if (!canRequestAds) {
      debugPrint("🔒 AdService - Cannot show interstitial ad: no consent");
      return;
    }

    // Check if user has ad-free status
    if (RewardService().isAdFree()) {
      debugPrint(
        "🔒 AdService - User has ad-free status, skipping interstitial",
      );
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint("⚠️ AdService - Interstitial ad not loaded yet");
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    );
    await ad.show();
  }
}
