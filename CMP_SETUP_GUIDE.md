# CMP (Consent Management Platform) Setup Guide

This guide will help you set up the Consent Management Platform (CMP) for your Flutter app using Google's User Messaging Platform (UMP) SDK.

## Prerequisites

- Flutter project with Google Mobile Ads already integrated
- AdMob account with app registered
- AdMob App ID configured in your app

## Step 1: Update Dependencies

Update your `pubspec.yaml` to use the latest `google_mobile_ads` package which now includes the integrated UMP SDK:

```yaml
dependencies:
  google_mobile_ads: ^6.0.0  # Includes integrated UMP SDK
```

**Important**: The separate `user_messaging_platform` package has been discontinued and replaced by the integrated UMP SDK in `google_mobile_ads` package.

Then run:
```bash
flutter pub get
```

## Step 2: Configure AdMob Console

### 2.1 Create Privacy Messages

1. Go to your [AdMob Console](https://admob.google.com/)
2. Navigate to **Privacy & messaging** tab
3. Create a new message type:
   - **GDPR message** (for EU users)
   - **CCPA message** (for California users)
   - **UMP message** (for other regions)

### 2.2 Configure Message Settings

- Set up consent collection for personalized ads
- Configure privacy options entry point
- Set message appearance and behavior
- Configure test devices for development

## Step 3: Update App Configuration

### 3.1 Android Configuration

Ensure your `android/app/src/main/AndroidManifest.xml` has the AdMob App ID:

```xml
<application>
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
</application>
```

### 3.2 iOS Configuration

Ensure your `ios/Runner/Info.plist` has the AdMob App ID:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

## Step 4: Update Implementation

The current implementation uses the integrated UMP SDK from `google_mobile_ads`. The consent service is already configured to work with the integrated SDK.

**Note**: The exact UMP SDK API within `google_mobile_ads` may vary by version. The current implementation provides a foundation that can be updated once the specific API is confirmed.

## Step 5: Testing

### 5.1 Test Device Setup

1. Run your app and check the logs for your device ID:
   ```
   Use new ConsentDebugSettings.Builder().addTestDeviceHashedId("YOUR_DEVICE_ID")
   ```

2. Add this device ID to your AdMob console test devices

### 5.2 Debug Geography Testing

For testing different regions, you can force specific geographies:

```dart
// In your consent service initialization
ConsentDebugSettings debugSettings = ConsentDebugSettings(
  debugGeography: DebugGeography.debugGeographyEea, // For EU testing
  testIdentifiers: ["YOUR_TEST_DEVICE_ID"],
);
```

### 5.3 Reset Consent State

For testing the first-time user experience:

```dart
// Only in debug mode
await ConsentService().resetConsentState();
```

## Step 6: Production Deployment

### 6.1 Remove Debug Code

- Remove all debug settings
- Remove test device configurations
- Ensure proper error handling

### 6.2 Verify Compliance

- Test consent flow in different regions
- Verify privacy options are accessible
- Ensure ads only show with proper consent

## Implementation Features

### ✅ What's Implemented

1. **Consent Service**: Manages consent state and privacy options
2. **Ad Integration**: All ads check consent before showing
3. **Privacy Options**: Users can modify preferences anytime
4. **Settings Integration**: Privacy settings accessible from app settings
5. **Error Handling**: Graceful degradation when consent fails
6. **Debug Support**: Testing tools for development

### 🔧 Key Components

- `ConsentService`: Core consent management
- `PrivacyOptionsButton`: UI for privacy settings
- `AdService`: Updated to check consent
- Settings page integration
- Main app initialization

### 📱 User Experience

- Consent forms appear naturally in app flow
- Privacy options easily accessible
- Clear communication about data usage
- Seamless integration with existing UI

## Troubleshooting

### Common Issues

1. **Consent form not showing**
   - Check AdMob console configuration
   - Verify App ID is correct
   - Ensure test device is configured

2. **Ads not displaying**
   - Check consent status in logs
   - Verify consent service initialization
   - Check AdMob console settings

3. **Privacy options not available**
   - Check privacy options requirement status
   - Verify UMP SDK integration
   - Check AdMob console configuration

### Debug Information

Enable debug logging to monitor consent flow:

```dart
// Check consent status
final status = ConsentService().getConsentStatus();
print('Consent Status: $status');
```

## Compliance Notes

### GDPR Compliance
- ✅ Explicit consent collection
- ✅ Granular consent options
- ✅ Right to withdraw consent
- ✅ Data processing transparency

### CCPA Compliance
- ✅ Privacy notice display
- ✅ Opt-out mechanisms
- ✅ Data collection transparency

## Next Steps

1. **Install UMP SDK**: Run `flutter pub get` after adding dependency
2. **Configure AdMob**: Set up privacy messages in console
3. **Test Implementation**: Use debug settings for testing
4. **Deploy to Production**: Remove debug code and test thoroughly

## Support

For issues with the CMP implementation:
- Check the [Google AdMob UMP SDK Documentation](https://developers.google.com/admob/flutter/privacy)
- Review the implementation files in `lib/core/consent/`
- Check the comprehensive documentation in `CMP_IMPLEMENTATION.md`
