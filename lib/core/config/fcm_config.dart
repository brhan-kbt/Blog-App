/// FCM Configuration
class FCMConfig {
  // TODO: Replace with your actual backend URL
  static const String backendUrl = 'https://your-backend-url.com';

  // FCM endpoints
  static const String registerEndpoint = '$backendUrl/fcm/register';

  // Notification settings
  static const String defaultNotificationChannel = 'fcm_channel';
  static const String defaultNotificationChannelName = 'FCM Notifications';
  static const String defaultNotificationChannelDescription =
      'Notifications from Firebase Cloud Messaging';
}
