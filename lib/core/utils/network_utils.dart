import 'dart:io';
import 'package:flutter/foundation.dart';

/// Network utility class for checking connectivity
class NetworkUtils {
  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('NetworkUtils: No internet connection: $e');
      }
      return false;
    }
    return false;
  }

  /// Check connectivity with a specific host
  static Future<bool> checkConnectivity(String host) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('NetworkUtils: Cannot reach $host: $e');
      }
      return false;
    }
  }
}
