import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_handler.dart';
import '../models/driver_model.dart';
import 'api_service.dart';

class DriverService {
  final ApiService _api = ApiService();

  Future<DriverModel?> getProfile() async {
    try {
      if (kDebugMode) {
        print('DriverService: Fetching driver profile');
      }
      
      final response = await _api.get(ApiConfig.driverProfile);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['driver'] != null) {
          return DriverModel.fromJson(data['driver']);
        }
        if (data != null) {
          return DriverModel.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'DriverService: Error fetching profile');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'DriverService: Error fetching profile');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<DriverModel?> updateProfile({String? name}) async {
    try {
      if (kDebugMode) {
        print('DriverService: Updating driver profile');
      }

      // Validate input
      if (name != null && name.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name.trim();

      final response = await _api.put(
        ApiConfig.driverProfile,
        data: updateData,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['driver'] != null) {
          return DriverModel.fromJson(data['driver']);
        }
        if (data != null) {
          return DriverModel.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'DriverService: Error updating profile');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'DriverService: Error updating profile');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<DriverModel?> updateLanguage(String language) async {
    try {
      if (kDebugMode) {
        print('DriverService: Updating language preference: $language');
      }

      // Validate input
      if (language.isEmpty) {
        throw Exception('Language cannot be empty');
      }

      final response = await _api.put(
        ApiConfig.driverLanguage,
        data: {'language': language},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['driver'] != null) {
          return DriverModel.fromJson(data['driver']);
        }
        if (data != null) {
          return DriverModel.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'DriverService: Error updating language');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'DriverService: Error updating language');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }
}
