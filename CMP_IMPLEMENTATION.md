# Consent Management Platform (CMP) Implementation

This document describes the implementation of Google's User Messaging Platform (UMP) SDK for consent management in the Abay Tech Flutter app.

## Overview

The CMP implementation ensures compliance with privacy regulations (GDPR, CCPA, etc.) by:
- Requesting user consent before showing personalized ads
- Providing privacy options for users to modify their preferences
- Integrating seamlessly with Google AdMob

## Implementation Details

### 1. Dependencies Updated

```yaml
dependencies:
  google_mobile_ads: ^6.0.0  # Updated to include integrated UMP SDK
```

**Note**: The separate `user_messaging_platform` package has been discontinued and replaced by the integrated UMP SDK in `google_mobile_ads` package.

### 2. Core Components

#### ConsentService (`lib/core/consent/consent_service.dart`)
- Singleton service managing consent state
- Handles consent information updates
- Manages privacy options requirements
- Provides consent checking before ad requests

#### PrivacyOptionsButton (`lib/widgets/privacy_options_button.dart`)
- UI component for accessing privacy settings
- Only shows when privacy options are required
- Handles loading states and error scenarios

### 3. Integration Points

#### App Initialization (`lib/main.dart`)
- Consent service initialized early in app lifecycle
- Integrated with existing service initialization

#### Ad Service (`lib/core/ads/ad_service.dart`)
- All ad methods now check consent before showing ads
- Graceful handling when consent is not available
- Maintains existing ad functionality

#### Settings Page (`lib/modules/settings/settings_page.dart`)
- Added privacy settings option
- Integrated with existing settings structure

### 4. Key Features

#### Consent Flow
1. **App Launch**: Consent service initializes and requests consent info
2. **Form Display**: If required, consent form is shown automatically
3. **Ad Requests**: All ads check consent before display
4. **Privacy Options**: Users can modify preferences anytime

#### Privacy Options
- Accessible from settings page
- Available as floating button when required
- Handles user preference changes

### 5. Configuration Requirements

#### AdMob Console Setup
1. Create privacy messages in AdMob console
2. Configure message types (GDPR, CCPA, etc.)
3. Set up test devices for development

#### App Configuration
- AdMob App ID must be configured in `android/app/src/main/AndroidManifest.xml`
- iOS configuration in `ios/Runner/Info.plist`

### 6. Testing

#### Debug Mode
```dart
// Reset consent state for testing
await ConsentService().resetConsentState();
```

#### Test Device Setup
1. Run app and check logs for device ID
2. Add device ID to AdMob console test devices
3. Configure debug geography for testing different regions

### 7. Compliance Features

#### GDPR Compliance
- Explicit consent collection
- Granular consent options
- Right to withdraw consent
- Data processing transparency

#### CCPA Compliance
- Privacy notice display
- Opt-out mechanisms
- Data collection transparency

### 8. Error Handling

#### Graceful Degradation
- App continues functioning if consent service fails
- Ads are not shown without proper consent
- User experience maintained during errors

#### Logging
- Comprehensive debug logging
- Error tracking and reporting
- Consent status monitoring

### 9. User Experience

#### Seamless Integration
- Consent forms appear naturally in app flow
- Privacy options easily accessible
- Clear communication about data usage

#### Accessibility
- Follows platform accessibility guidelines
- Supports screen readers
- High contrast support

### 10. Future Enhancements

#### Potential Improvements
- Analytics integration for consent rates
- A/B testing for consent form designs
- Advanced privacy controls
- Regional customization

## Usage Examples

### Checking Consent Before Showing Ads
```dart
final canRequestAds = await ConsentService().canRequestAds();
if (canRequestAds) {
  // Show ads
} else {
  // Handle no consent scenario
}
```

### Showing Privacy Options
```dart
await ConsentService().showPrivacyOptionsForm();
```

### Getting Consent Status
```dart
final status = ConsentService().getConsentStatus();
print('Can request ads: ${status['canRequestAds']}');
```

## Troubleshooting

### Common Issues
1. **Consent form not showing**: Check AdMob console configuration
2. **Ads not displaying**: Verify consent status
3. **Privacy options not available**: Check privacy options requirement status

### Debug Information
- Enable debug logging in development
- Check consent status in app settings
- Monitor AdMob console for configuration issues

## References

- [Google AdMob UMP SDK Documentation](https://developers.google.com/admob/flutter/privacy)
- [GDPR Compliance Guide](https://developers.google.com/admob/flutter/privacy#gdpr)
- [CCPA Compliance Guide](https://developers.google.com/admob/flutter/privacy#ccpa)
