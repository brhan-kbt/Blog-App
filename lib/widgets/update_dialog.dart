import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_check_response.dart';

class UpdateDialog extends StatelessWidget {
  final VersionData versionData;

  const UpdateDialog({super.key, required this.versionData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isForceUpdate = versionData.forceUpdate;

    return WillPopScope(
      onWillPop: () async =>
          !isForceUpdate, // Prevent back button if force update
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.cardColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Update icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isForceUpdate
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isForceUpdate
                      ? Icons.warning_rounded
                      : Icons.system_update_rounded,
                  size: 40,
                  color: isForceUpdate ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isForceUpdate ? 'Update Required' : 'Update Available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isForceUpdate
                      ? Colors.red
                      : theme.textTheme.headlineSmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              // Text(
              //   versionData.message,
              //   style: theme.textTheme.bodyMedium?.copyWith(
              //     color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: 20),

              // Version info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildVersionRow(
                      'Current Version',
                      versionData.currentVersion,
                      theme,
                      isLatest: true,
                    ),
                    const SizedBox(height: 8),
                    _buildVersionRow(
                      'Latest Version',
                      versionData.minVersion,
                      theme,
                      isLatest: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (!isForceUpdate) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Later'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _launchUpdateUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isForceUpdate
                            ? Colors.red
                            : theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Update Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionRow(
    String label,
    String version,
    ThemeData theme, {
    bool isLatest = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLatest
                ? Colors.green.withOpacity(0.1)
                : theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            version,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLatest ? Colors.green : theme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUpdateUrl() async {
    try {
      final uri = Uri.parse(versionData.updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open the update URL',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open update URL: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
