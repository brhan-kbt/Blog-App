# UMP SDK Implementation Guide

## Overview

This document provides a complete implementation of Google's User Messaging Platform (UMP) SDK using the integrated version in `google_mobile_ads` v6.0.0.

## Implementation Details

### 1. Dependencies

```yaml
dependencies:
  google_mobile_ads: ^6.0.0  # Includes integrated UMP SDK
```

### 2. Core Implementation

The `ConsentService` class provides a complete UMP SDK implementation with the following features:

#### Key Methods

- **`initialize()`**: Initializes the consent service and requests consent information
- **`_requestConsentInfoUpdate()`**: Requests consent information from UMP SDK
- **`_handleConsentInfoUpdate()`**: Handles consent information updates
- **`_loadAndShowConsentForm()`**: Loads and shows consent forms when required
- **`showPrivacyOptionsForm()`**: Shows privacy options form
- **`checkCanRequestAds()`**: Checks if ads can be requested
- **`resetConsentState()`**: Resets consent state for testing

#### Debug Features

- **Debug Geography**: Test as EU user for GDPR compliance
- **Test Device IDs**: Add your test device IDs for development
- **Detailed Logging**: Comprehensive debug information

### 3. Usage Examples

#### Basic Initialization
```dart
// Initialize consent service
await ConsentService().initialize();
```

#### Check Consent Before Showing Ads
```dart
final canRequestAds = await ConsentService().checkCanRequestAds();
if (canRequestAds) {
  // Show ads
} else {
  // Handle no consent scenario
}
```

#### Show Privacy Options
```dart
await ConsentService().showPrivacyOptionsForm();
```

#### Get Detailed Consent Information
```dart
final consentInfo = await ConsentService().getDetailedConsentInfo();
print('Can request ads: ${consentInfo['canRequestAds']}');
print('Privacy options required: ${consentInfo['privacyOptionsRequired']}');
```

### 4. Debug Configuration

#### Test Device Setup
1. Run your app and check logs for device ID
2. Add device ID to `_createConsentRequestParameters()`:
```dart
final debugSettings = ConsentDebugSettings(
  debugGeography: DebugGeography.debugGeographyEea,
  testIdentifiers: ["YOUR_TEST_DEVICE_ID"], // Add your device ID here
);
```

#### Debug Geography Options
- `DebugGeography.debugGeographyEea`: Test as EU user (GDPR)
- `DebugGeography.debugGeographyUk`: Test as UK user
- `DebugGeography.debugGeographyNotEea`: Test as non-EU user

### 5. AdMob Console Configuration

#### Required Setup
1. **App ID**: Configure in `AndroidManifest.xml` and `Info.plist`
2. **Privacy Messages**: Create in AdMob console
3. **Test Devices**: Add your test device IDs
4. **Message Types**: Configure GDPR, CCPA, and UMP messages

#### Android Configuration
```xml
<application>
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
</application>
```

#### iOS Configuration
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

### 6. Integration Points

#### Ad Service Integration
All ad methods now check consent before showing ads:
```dart
Future<void> showInterstitial() async {
  final canRequestAds = await ConsentService().checkCanRequestAds();
  if (!canRequestAds) {
    debugPrint("🔒 AdService - Cannot show interstitial ad: no consent");
    return;
  }
  // Show ad...
}
```

#### Settings Integration
Privacy options accessible from app settings:
```dart
_SimpleTile(
  title: 'Privacy Settings',
  subtitle: 'Manage your privacy preferences',
  onTap: () async {
    await ConsentService().showPrivacyOptionsForm();
  },
),
```

### 7. Error Handling

#### Graceful Degradation
- App continues functioning if consent service fails
- Ads are not shown without proper consent
- User experience maintained during errors

#### Error Logging
```dart
try {
  await ConsentService().initialize();
} catch (e) {
  debugPrint("❌ Error initializing consent service: $e");
  // Continue app initialization
}
```

### 8. Testing

#### Development Testing
```dart
// Reset consent state for testing
await ConsentService().resetConsentState();

// Get detailed consent information
final info = await ConsentService().getDetailedConsentInfo();
print('Consent Status: $info');
```

#### Production Considerations
- Remove debug settings before release
- Test consent flow in different regions
- Verify privacy options functionality
- Ensure compliance with regulations

### 9. Compliance Features

#### GDPR Compliance
- ✅ Explicit consent collection
- ✅ Granular consent options
- ✅ Right to withdraw consent
- ✅ Data processing transparency

#### CCPA Compliance
- ✅ Privacy notice display
- ✅ Opt-out mechanisms
- ✅ Data collection transparency

### 10. Troubleshooting

#### Common Issues
1. **Consent form not showing**: Check AdMob console configuration
2. **Ads not displaying**: Verify consent status
3. **Privacy options not available**: Check privacy options requirement status

#### Debug Information
```dart
// Check consent status
final status = ConsentService().getConsentStatus();
print('Consent Status: $status');

// Get detailed information
final details = await ConsentService().getDetailedConsentInfo();
print('Detailed Info: $details');
```

## Conclusion

This implementation provides a complete, production-ready UMP SDK integration that ensures compliance with privacy regulations while maintaining a seamless user experience. The service handles all aspects of consent management, from initial collection to ongoing privacy options management.

