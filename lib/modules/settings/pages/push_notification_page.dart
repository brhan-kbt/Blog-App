import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class PushNotificationPage extends StatefulWidget {
  const PushNotificationPage({super.key});

  @override
  State<PushNotificationPage> createState() => _PushNotificationPageState();
}

class _PushNotificationPageState extends State<PushNotificationPage> {
  bool _isLoading = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await Permission.notification.status;
      setState(() {
        _notificationsEnabled = status.isGranted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("⚠️ Error checking notification status: $e");
    }
  }

  Future<void> _openNotificationSettings() async {
    setState(() => _isLoading = true);
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      debugPrint("⚠️ Error opening notification settings: $e");
      Get.snackbar(
        'Error',
        'Could not open notification settings',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);
    try {
      final result = await Permission.notification.request();
      setState(() {
        _notificationsEnabled = result.isGranted;
        _isLoading = false;
      });

      if (result.isGranted) {
        Get.snackbar(
          'Success',
          'Notifications enabled!',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else if (result.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Please enable notifications in Settings',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("⚠️ Error requesting notification permission: $e");
    }
  }

  Future<void> _revokeNotificationPermission() async {
    Get.snackbar(
      'Success',
      'Notifications disabled!',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkNotificationStatus,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _notificationsEnabled
                              ? Icons.notifications
                              : Icons.notifications_off,
                          color: _notificationsEnabled
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _notificationsEnabled
                              ? 'Notifications Enabled'
                              : 'Notifications Disabled',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _notificationsEnabled
                          ? 'You will receive notifications about new articles and updates.'
                          : 'Enable notifications to stay updated with the latest articles.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Manage Push Notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "To enable or disable push notifications for Gold Tech App, "
              "please use your phone's system settings or the buttons below.",
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Center(
                child: Column(
                  children: [
                    if (!_notificationsEnabled) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.notifications),
                        label: const Text("Enable Notifications"),
                        onPressed: _requestNotificationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_notificationsEnabled) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_off),
                        label: const Text("Disable Notifications"),
                        onPressed: _revokeNotificationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
