import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Service to manage user rewards from watching ads
/// Handles ad-free periods and other rewards
class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  final _storage = GetStorage();
  static const String _adFreeUntilKey = 'ad_free_until';
  static const String _totalRewardsKey = 'total_rewards_watched';

  /// Check if user currently has ad-free status
  bool isAdFree() {
    final adFreeUntil = _storage.read(_adFreeUntilKey);
    if (adFreeUntil == null) return false;

    try {
      final until = DateTime.parse(adFreeUntil);
      final now = DateTime.now();
      if (now.isBefore(until)) {
        return true;
      } else {
        // Expired, clear it
        _storage.remove(_adFreeUntilKey);
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ RewardService - Error parsing ad-free date: $e");
      _storage.remove(_adFreeUntilKey);
      return false;
    }
  }

  /// Get remaining ad-free time in minutes
  int getRemainingAdFreeMinutes() {
    if (!isAdFree()) return 0;

    final adFreeUntil = _storage.read(_adFreeUntilKey);
    if (adFreeUntil == null) return 0;

    try {
      final until = DateTime.parse(adFreeUntil);
      final now = DateTime.now();
      final difference = until.difference(now);
      return difference.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Grant ad-free period (in minutes)
  /// Typically grants 60 minutes (1 hour) per rewarded ad
  void grantAdFreePeriod(int minutes) {
    final now = DateTime.now();
    final currentUntil = _storage.read(_adFreeUntilKey);

    DateTime newUntil;
    if (currentUntil != null) {
      try {
        final existingUntil = DateTime.parse(currentUntil);
        // If user already has ad-free time, extend it
        if (existingUntil.isAfter(now)) {
          newUntil = existingUntil.add(Duration(minutes: minutes));
        } else {
          newUntil = now.add(Duration(minutes: minutes));
        }
      } catch (e) {
        newUntil = now.add(Duration(minutes: minutes));
      }
    } else {
      newUntil = now.add(Duration(minutes: minutes));
    }

    _storage.write(_adFreeUntilKey, newUntil.toIso8601String());
    _incrementRewardCount();
    debugPrint(
      "✅ RewardService - Granted $minutes minutes ad-free. Valid until: $newUntil",
    );
  }

  /// Get total number of rewarded ads watched
  int getTotalRewardsWatched() {
    return _storage.read(_totalRewardsKey) ?? 0;
  }

  void _incrementRewardCount() {
    final current = getTotalRewardsWatched();
    _storage.write(_totalRewardsKey, current + 1);
  }

  /// Clear ad-free status (for testing or user request)
  void clearAdFreeStatus() {
    _storage.remove(_adFreeUntilKey);
    debugPrint("✅ RewardService - Ad-free status cleared");
  }

  /// Get formatted remaining time string
  String getRemainingTimeString() {
    final minutes = getRemainingAdFreeMinutes();
    if (minutes <= 0) return "No active ad-free period";

    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return "$hours hour${hours > 1 ? 's' : ''} $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}";
      }
      return "$hours hour${hours > 1 ? 's' : ''}";
    }
    return "$minutes minute${minutes > 1 ? 's' : ''}";
  }
}

