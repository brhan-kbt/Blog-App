import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get instance => Get.find<ConnectivityService>();

  final Connectivity _connectivity = Connectivity();
  final RxBool _isConnected = true.obs;
  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isConnected => _isConnected.value;
  ConnectivityResult get connectionStatus => _connectionStatus.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        debugPrint('Connectivity error: $error');
      },
    );
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected.value = false;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _connectionStatus.value = result.first;
    _isConnected.value = result.first != ConnectivityResult.none;

    if (!_isConnected.value) {
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('No Internet Connection'),
          ],
        ),
        content: const Text(
          'Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              checkConnectivity();
            },
            child: const Text('Retry'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> checkConnectivity() async {
    await _initConnectivity();
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.first != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }
}
