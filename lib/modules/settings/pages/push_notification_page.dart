import 'package:flutter/material.dart';

class PushNotificationPage extends StatelessWidget {
  const PushNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Push Notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "To enable or disable push notifications for Milki App, "
              "please use your phone’s system settings.",
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Open Notification Settings"),
                onPressed: () {
                  // AppSettings.openAppSettings(
                  //   type: AppSettingsType.notification,
                  // );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
