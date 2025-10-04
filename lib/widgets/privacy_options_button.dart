import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/consent/consent_service.dart';

/// Privacy Options Button Widget
/// Shows a button to access privacy settings when required
class PrivacyOptionsButton extends StatefulWidget {
  const PrivacyOptionsButton({super.key});

  @override
  State<PrivacyOptionsButton> createState() => _PrivacyOptionsButtonState();
}

class _PrivacyOptionsButtonState extends State<PrivacyOptionsButton> {
  final ConsentService _consentService = ConsentService();
  bool _isPrivacyOptionsRequired = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyOptionsRequirement();
  }

  Future<void> _checkPrivacyOptionsRequirement() async {
    try {
      final isRequired = _consentService.isPrivacyOptionsRequired;
      if (mounted) {
        setState(() {
          _isPrivacyOptionsRequired = isRequired;
        });
      }
    } catch (e) {
      debugPrint("🔒 PrivacyOptionsButton - Error checking requirement: $e");
    }
  }

  Future<void> _showPrivacyOptions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _consentService.showPrivacyOptionsForm();

      // Refresh the requirement status after showing the form
      await _checkPrivacyOptionsRequirement();

      if (mounted) {
        Get.snackbar(
          "Privacy Settings",
          "Your privacy preferences have been updated",
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          backgroundColor: Get.isDarkMode ? Colors.grey[800] : Colors.grey[100],
          colorText: Get.isDarkMode ? Colors.white : Colors.black,
        );
      }
    } catch (e) {
      debugPrint("🔒 PrivacyOptionsButton - Error showing privacy options: $e");
      if (mounted) {
        Get.snackbar(
          "Error",
          "Failed to open privacy settings",
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show the button if privacy options are required
    if (!_isPrivacyOptionsRequired) {
      return const SizedBox.shrink();
    }

    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        // elevation: 2,
        child: ListTile(
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: Theme.of(context).primaryColor,
          ),
          title: const Text(
            "Privacy Settings",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: const Text(
            "Manage your privacy preferences",
            style: TextStyle(fontSize: 12),
          ),
          trailing: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _isLoading ? null : _showPrivacyOptions,
        ),
      ),
    );
  }
}

/// Privacy Options Dialog
/// A dialog that can be shown from settings to access privacy options
class PrivacyOptionsDialog extends StatelessWidget {
  const PrivacyOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined),
          SizedBox(width: 8),
          Text("Privacy Settings"),
        ],
      ),
      content: const Text(
        "You can manage your privacy preferences and control how your data is used for personalized ads.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await ConsentService().showPrivacyOptionsForm();
            } catch (e) {
              debugPrint("🔒 PrivacyOptionsDialog - Error: $e");
            }
          },
          child: const Text("Open Settings"),
        ),
      ],
    );
  }
}
