import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Consent Management Platform (CMP) Service
/// Handles user consent for personalized ads and data collection
/// Uses the integrated UMP SDK from google_mobile_ads package
class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  bool _isInitialized = false;
  bool _canRequestAds = false;
  bool _isPrivacyOptionsRequired = false;

  /// Getter for initialization status
  bool get isInitialized => _isInitialized;

  /// Getter for ads consent status
  bool get canRequestAds => _canRequestAds;

  /// Getter for privacy options requirement
  bool get isPrivacyOptionsRequired => _isPrivacyOptionsRequired;

  /// Initialize the consent service
  /// This should be called early in the app lifecycle
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint("🔒 ConsentService - Already initialized");
      return;
    }

    try {
      debugPrint("🔒 ConsentService - Starting initialization...");

      // Initialize Mobile Ads SDK first
      await MobileAds.instance.initialize();

      // Request consent information update
      await _requestConsentInfoUpdate();

      _isInitialized = true;
      debugPrint("🔒 ConsentService - Initialization completed");
    } catch (e) {
      debugPrint("🔒 ConsentService - Initialization failed: $e");
      _isInitialized = false;
    }
  }

  /// Request consent information update
  Future<void> _requestConsentInfoUpdate() async {
    try {
      debugPrint("🔒 ConsentService - Requesting consent info update...");

      // Create consent request parameters with debug settings for testing
      final params = _createConsentRequestParameters();

      // Request consent information update
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          debugPrint("🔒 ConsentService - Consent info updated successfully");
          await _handleConsentInfoUpdate();
        },
        (FormError error) {
          debugPrint(
            "🔒 ConsentService - Error updating consent info: ${error.message}",
          );
          _handleConsentError(error);
        },
      );
    } catch (e) {
      debugPrint("🔒 ConsentService - Error updating consent info: $e");
      _handleConsentError(e);
    }
  }

  /// Create consent request parameters with optional debug settings
  ConsentRequestParameters _createConsentRequestParameters() {
    final params = ConsentRequestParameters();

    // Add debug settings for testing (only in debug mode)
    //   if (kDebugMode) {
    //     debugPrint("🔒 ConsentService - Adding debug settings for testing...");
    //     final debugSettings = ConsentDebugSettings(
    //       debugGeography: DebugGeography.debugGeographyRegulatedUsState,
    //       testIdentifiers: [
    //         '253128ab-6100-4b36-927f-71346f33fb6b',
    //       ],
    //     );
    //   params.consentDebugSettings = debugSettings;
    // }

    return params;
  }

  /// Handle consent information update
  Future<void> _handleConsentInfoUpdate() async {
    try {
      // Check if we can request ads
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      debugPrint("🔒 ConsentService - Can request ads: $_canRequestAds");

      // Check if privacy options are required
      final privacyOptionsStatus = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      _isPrivacyOptionsRequired =
          privacyOptionsStatus == PrivacyOptionsRequirementStatus.required;
      debugPrint(
        "🔒 ConsentService - Privacy options required: $_isPrivacyOptionsRequired",
      );

      // Load and show consent form if required
      await _loadAndShowConsentForm();
    } catch (e) {
      debugPrint("🔒 ConsentService - Error handling consent update: $e");
    }
  }

  /// Load and show consent form if required
  Future<void> _loadAndShowConsentForm() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((loadAndShowError) {
        if (loadAndShowError != null) {
          debugPrint(
            "🔒 ConsentService - Consent gathering failed: ${loadAndShowError.message}",
          );
          _handleConsentError(loadAndShowError);
        } else {
          debugPrint("🔒 ConsentService - Consent gathering completed");
          _updateConsentStatus();
        }
      });
    } catch (e) {
      debugPrint("🔒 ConsentService - Error loading consent form: $e");
    }
  }

  /// Update consent status after form completion
  Future<void> _updateConsentStatus() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      final privacyOptionsStatus = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      _isPrivacyOptionsRequired =
          privacyOptionsStatus == PrivacyOptionsRequirementStatus.required;

      debugPrint(
        "🔒 ConsentService - Updated status - Can request ads: $_canRequestAds, Privacy options required: $_isPrivacyOptionsRequired",
      );
    } catch (e) {
      debugPrint("🔒 ConsentService - Error updating consent status: $e");
    }
  }

  /// Handle consent errors
  void _handleConsentError(dynamic error) {
    debugPrint("🔒 ConsentService - Consent error: $error");
    // In case of error, we'll be conservative and not request ads
    _canRequestAds = false;
  }

  /// Show privacy options form
  /// Call this when user wants to modify their privacy settings
  Future<void> showPrivacyOptionsForm() async {
    if (!_isInitialized) {
      debugPrint(
        "🔒 ConsentService - Not initialized, cannot show privacy options",
      );
      return;
    }

    try {
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint(
            "🔒 ConsentService - Privacy options form error: ${formError.message}",
          );
        } else {
          debugPrint("🔒 ConsentService - Privacy options form completed");
          _updateConsentStatus();
        }
      });
    } catch (e) {
      debugPrint("🔒 ConsentService - Error showing privacy options: $e");
    }
  }

  /// Check if ads can be requested
  /// This should be called before showing any ads
  Future<bool> checkCanRequestAds() async {
    if (!_isInitialized) {
      debugPrint("🔒 ConsentService - Not initialized, cannot request ads");
      return false;
    }

    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      debugPrint("🔒 ConsentService - Can request ads check: $_canRequestAds");
      return _canRequestAds;
    } catch (e) {
      debugPrint("🔒 ConsentService - Error checking ads consent: $e");
      return false;
    }
  }

  /// Reset consent state (for testing only)
  /// ⚠️ WARNING: This should only be used for testing purposes
  Future<void> resetConsentState() async {
    // if (kDebugMode) {
    //   try {
    //     await ConsentInformation.instance.reset();
    //     _canRequestAds = false;
    //     _isPrivacyOptionsRequired = false;
    //     debugPrint("🔒 ConsentService - Consent state reset (DEBUG MODE ONLY)");
    //   } catch (e) {
    //     debugPrint("🔒 ConsentService - Error resetting consent: $e");
    //   }
    // } else {
    //   debugPrint("🔒 ConsentService - Reset not allowed in production");
    // }
  }

  /// Get consent status for debugging
  Map<String, dynamic> getConsentStatus() {
    return {
      'isInitialized': _isInitialized,
      'canRequestAds': _canRequestAds,
      'isPrivacyOptionsRequired': _isPrivacyOptionsRequired,
    };
  }

  /// Get detailed consent information from UMP SDK
  Future<Map<String, dynamic>> getDetailedConsentInfo() async {
    try {
      final canRequestAds = await ConsentInformation.instance.canRequestAds();
      final privacyOptionsStatus = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();

      return {
        'canRequestAds': canRequestAds,
        'privacyOptionsRequired':
            privacyOptionsStatus == PrivacyOptionsRequirementStatus.required,
        'privacyOptionsStatus': privacyOptionsStatus.toString(),
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      debugPrint("🔒 ConsentService - Error getting detailed consent info: $e");
      return {'error': e.toString(), 'isInitialized': _isInitialized};
    }
  }
}
