import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Web-specific storage implementation using SharedPreferences only
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;

  Future<bool> init() async {
    try {
      if (!_isInitialized) {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
        if (kDebugMode) {
          print('StorageService: Initialized for web (SharedPreferences only)');
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error initializing SharedPreferences: $e');
      }
      // Try to use localStorage as fallback
      try {
        // localStorage is always available on web
        _isInitialized = true;
        if (kDebugMode) {
          print('StorageService: Using localStorage fallback');
        }
        return true;
      } catch (e2) {
        if (kDebugMode) {
          print('StorageService: localStorage also unavailable: $e2');
        }
      }
      return false;
    }
  }

  // Secure Storage (for tokens) - uses SharedPreferences on web
  Future<void> saveAccessToken(String token) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (_prefs != null) {
        await _prefs!.setString(AppConstants.accessTokenKey, token);
        if (kDebugMode) {
          print('StorageService: Access token saved successfully');
        }
      } else {
        // Fallback to localStorage
        html.window.localStorage[AppConstants.accessTokenKey] = token;
        if (kDebugMode) {
          print('StorageService: Access token saved to localStorage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error saving access token: $e');
      }
      // Fallback to localStorage
      try {
        html.window.localStorage[AppConstants.accessTokenKey] = token;
      } catch (e2) {
        if (kDebugMode) {
          print('StorageService: Fallback save also failed: $e2');
        }
        rethrow;
      }
    }
  }

  Future<String?> getAccessToken() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (_prefs != null) {
        final token = _prefs!.getString(AppConstants.accessTokenKey);
        if (kDebugMode) {
          print('StorageService: Access token retrieved: ${token != null ? "found" : "not found"}');
        }
        return token;
      } else {
        // Fallback to localStorage
        final token = html.window.localStorage[AppConstants.accessTokenKey];
        if (kDebugMode) {
          print('StorageService: Access token retrieved from localStorage: ${token != null ? "found" : "not found"}');
        }
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error getting access token: $e');
      }
      // Fallback to localStorage
      try {
        return html.window.localStorage[AppConstants.accessTokenKey];
      } catch (e2) {
        return null;
      }
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (_prefs != null) {
        await _prefs!.setString(AppConstants.refreshTokenKey, token);
        if (kDebugMode) {
          print('StorageService: Refresh token saved successfully');
        }
      } else {
        // Fallback to localStorage
        html.window.localStorage[AppConstants.refreshTokenKey] = token;
        if (kDebugMode) {
          print('StorageService: Refresh token saved to localStorage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error saving refresh token: $e');
      }
      // Fallback to localStorage
      try {
        html.window.localStorage[AppConstants.refreshTokenKey] = token;
      } catch (e2) {
        if (kDebugMode) {
          print('StorageService: Fallback save also failed: $e2');
        }
        rethrow;
      }
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (_prefs != null) {
        final token = _prefs!.getString(AppConstants.refreshTokenKey);
        if (kDebugMode) {
          print('StorageService: Refresh token retrieved: ${token != null ? "found" : "not found"}');
        }
        return token;
      } else {
        // Fallback to localStorage
        final token = html.window.localStorage[AppConstants.refreshTokenKey];
        if (kDebugMode) {
          print('StorageService: Refresh token retrieved from localStorage: ${token != null ? "found" : "not found"}');
        }
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error getting refresh token: $e');
      }
      // Fallback to localStorage
      try {
        return html.window.localStorage[AppConstants.refreshTokenKey];
      } catch (e2) {
        return null;
      }
    }
  }

  Future<void> clearTokens() async {
    try {
      if (_prefs != null) {
        await _prefs!.remove(AppConstants.accessTokenKey);
        await _prefs!.remove(AppConstants.refreshTokenKey);
      }
      // Also clear from localStorage
      html.window.localStorage.remove(AppConstants.accessTokenKey);
      html.window.localStorage.remove(AppConstants.refreshTokenKey);
      if (kDebugMode) {
        print('StorageService: Tokens cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageService: Error clearing tokens: $e');
      }
      // Try localStorage fallback
      try {
        html.window.localStorage.remove(AppConstants.accessTokenKey);
        html.window.localStorage.remove(AppConstants.refreshTokenKey);
      } catch (e2) {
        if (kDebugMode) {
          print('StorageService: Fallback clear also failed: $e2');
        }
      }
    }
  }

  // Shared Preferences (for user data)
  Future<void> saveUserData(String userData) async {
    if (!_isInitialized) {
      await init();
    }
    if (_prefs != null) {
      await _prefs!.setString(AppConstants.userDataKey, userData);
    } else {
      html.window.localStorage[AppConstants.userDataKey] = userData;
    }
  }

  Future<String?> getUserData() async {
    if (!_isInitialized) {
      await init();
    }
    if (_prefs != null) {
      return _prefs!.getString(AppConstants.userDataKey);
    } else {
      return html.window.localStorage[AppConstants.userDataKey];
    }
  }

  Future<void> saveDriverId(String driverId) async {
    if (!_isInitialized) {
      await init();
    }
    if (_prefs != null) {
      await _prefs!.setString(AppConstants.driverIdKey, driverId);
    } else {
      html.window.localStorage[AppConstants.driverIdKey] = driverId;
    }
  }

  Future<String?> getDriverId() async {
    if (!_isInitialized) {
      await init();
    }
    if (_prefs != null) {
      return _prefs!.getString(AppConstants.driverIdKey);
    } else {
      return html.window.localStorage[AppConstants.driverIdKey];
    }
  }

  Future<void> clearAll() async {
    await clearTokens();
    if (_prefs != null) {
      await _prefs!.clear();
    }
    html.window.localStorage.clear();
  }
}
