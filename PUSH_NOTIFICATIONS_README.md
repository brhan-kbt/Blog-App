# Push Notifications Implementation

This document describes the push notification implementation for the Abay Tech Flutter app using Firebase Cloud Messaging (FCM).

## Features Implemented

### 1. FCM Service (`lib/core/services/fcm_service.dart`)
- **Token Management**: Automatic FCM token generation and registration with backend
- **Permission Handling**: Request and check notification permissions
- **Message Handling**: Process foreground, background, and terminated app messages
- **Local Notifications**: Display local notifications for foreground messages
- **Topic Subscription**: Subscribe/unsubscribe to notification topics
- **Token Refresh**: Automatic token refresh when needed

### 2. Main App Integration (`lib/main.dart`)
- **Firebase Initialization**: Initialize Firebase before app startup
- **Background Handler**: Set up background message handler
- **Service Registration**: Register FCM service as permanent GetX service
- **Permission Integration**: Integrate with existing permission handling

### 3. Android Configuration (`android/app/src/main/AndroidManifest.xml`)
- **Permissions**: Added necessary permissions for FCM
- **Services**: Configured FCM messaging services
- **Metadata**: Set default notification channel, icon, and color
- **Background Processing**: Enabled background message handling

### 4. iOS Configuration (`ios/Runner/Info.plist`)
- **Background Modes**: Enabled remote notifications and background fetch
- **Firebase Integration**: Disabled Firebase App Delegate proxy for manual handling

### 5. Settings Page (`lib/modules/settings/pages/push_notification_page.dart`)
- **Permission Management**: UI to enable/disable notifications
- **Token Display**: Show FCM token for debugging
- **Status Checking**: Real-time notification permission status

## Dependencies Added

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
```

## Backend Integration

The FCM service automatically registers tokens with your backend at `/fcm/register` endpoint. The service sends:

```json
{
  "token": "fcm_token_here",
  "platform": "android" // or "ios"
}
```

## Usage

### 1. Automatic Initialization
The FCM service is automatically initialized when the app starts. It will:
- Request notification permissions
- Generate and register FCM token
- Set up message handlers

### 2. Manual Token Management
```dart
// Get FCM service instance
final fcmService = FCMService.instance;

// Get current token
String token = fcmService.fcmToken;

// Refresh token
await fcmService.refreshToken();

// Subscribe to topic
await fcmService.subscribeToTopic('news');

// Unsubscribe from topic
await fcmService.unsubscribeFromTopic('news');
```

### 3. Message Handling
The service automatically handles:
- **Foreground messages**: Shows local notification
- **Background messages**: Processes when app is in background
- **Terminated app messages**: Handles when app is completely closed

### 4. Custom Message Data
You can send custom data with notifications:

```json
{
  "notification": {
    "title": "New Article",
    "body": "Check out the latest tech news!"
  },
  "data": {
    "postId": "123",
    "categoryId": "tech",
    "action": "open_post"
  }
}
```

## Testing

### 1. Test FCM Service
```dart
// Run FCM tests
final testHelper = FCMTestHelper.instance;
final results = await testHelper.runAllTests();
```

### 2. Manual Testing
1. **Permission Test**: Check if notification permission is granted
2. **Token Test**: Verify FCM token is generated and registered
3. **Message Test**: Send test notification from Firebase Console
4. **Background Test**: Test notifications when app is in background

## Troubleshooting

### Common Issues

1. **Token Not Generated**
   - Check if notification permission is granted
   - Verify Firebase configuration
   - Check internet connectivity

2. **Notifications Not Received**
   - Verify FCM token is registered with backend
   - Check notification channel settings (Android)
   - Ensure app is not in battery optimization mode

3. **Background Messages Not Handled**
   - Verify background handler is registered
   - Check if app has background app refresh enabled (iOS)
   - Ensure proper Android manifest configuration

### Debug Information

The FCM service provides extensive debug logging:
- Token generation and registration
- Permission status changes
- Message reception and handling
- Error conditions and stack traces

## Security Considerations

1. **Token Security**: FCM tokens are sensitive and should be transmitted securely
2. **Backend Validation**: Validate tokens on your backend before storing
3. **Token Refresh**: Handle token refresh on your backend
4. **User Privacy**: Respect user's notification preferences

## Future Enhancements

1. **Rich Notifications**: Add image and action buttons
2. **Scheduled Notifications**: Implement local scheduled notifications
3. **Notification Categories**: Add notification categorization
4. **Analytics**: Track notification engagement
5. **A/B Testing**: Test different notification strategies

## Support

For issues or questions regarding the push notification implementation, check:
1. Firebase Console for message delivery status
2. Device logs for FCM service debug information
3. Backend logs for token registration status
4. Network connectivity for token registration
