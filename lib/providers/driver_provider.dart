import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/driver_model.dart';
import '../core/utils/error_handler.dart';
import '../services/driver_service.dart';
import 'locale_provider.dart';

class DriverProvider with ChangeNotifier {
  final DriverService _driverService = DriverService();
  LocaleProvider? _localeProvider;

  DriverModel? _driver;
  bool _isLoading = false;
  String? _error;

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Set locale provider reference (called from main.dart or where providers are initialized)
  void setLocaleProvider(LocaleProvider localeProvider) {
    _localeProvider = localeProvider;
  }

  Future<void> loadProfile({bool refresh = false}) async {
    if (!refresh && _driver != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = await _driverService.getProfile();
      _driver = driver;
      // Update locale when profile is loaded
      if (_localeProvider != null && driver != null) {
        _localeProvider!.loadLocaleFromProfile(this);
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'DriverProvider: Error loading profile');
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'DriverProvider: Error loading profile');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = await _driverService.updateProfile(name: name);
      if (driver != null) {
        _driver = driver;
        notifyListeners();
        return true;
      }
      _error = 'Failed to update profile';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'DriverProvider: Error updating profile');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'DriverProvider: Error updating profile');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLanguage(String language) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = await _driverService.updateLanguage(language);
      if (driver != null) {
        _driver = driver;
        // Update locale immediately when language changes
        if (_localeProvider != null) {
          _localeProvider!.updateLocaleFromLanguageCode(language);
        }
        notifyListeners();
        return true;
      }
      _error = 'Failed to update language';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'DriverProvider: Error updating language');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'DriverProvider: Error updating language');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all driver data (used on logout)
  void clearAll() {
    _driver = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
