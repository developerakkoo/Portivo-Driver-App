import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_handler.dart';
import '../models/auth_response_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<AuthResponseModel> sendOTP(String mobile) async {
    try {
      if (kDebugMode) {
        print('AuthService: Sending OTP for mobile: $mobile, userType: driver');
      }
      
      final response = await _api.post(
        ApiConfig.sendOTP,
        data: {
          'mobile': mobile,
          'userType': 'driver',
        },
      );

      if (kDebugMode) {
        print('AuthService: OTP response received');
      }

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        if (kDebugMode) {
          print('AuthService: OTP successful, saving tokens and user data');
        }
        // Ensure storage is initialized
        await _storage.init();
        
        // Save tokens
        await _storage.saveAccessToken(authResponse.data!.accessToken);
        await _storage.saveRefreshToken(authResponse.data!.refreshToken);

        // Verify tokens were saved
        final savedAccessToken = await _storage.getAccessToken();
        final savedRefreshToken = await _storage.getRefreshToken();
        if (kDebugMode) {
          print('AuthService: Token verification - Access: ${savedAccessToken != null}, Refresh: ${savedRefreshToken != null}');
        }

        // Save user data
        await _storage.saveDriverId(authResponse.data!.user.id);
        await _storage.saveUserData(authResponse.data!.user.id);
      } else {
        if (kDebugMode) {
          print('AuthService: OTP failed: ${authResponse.message}');
        }
      }

      return authResponse;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'AuthService: Error during OTP login');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'AuthService: Error during OTP login');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        if (kDebugMode) {
          print('AuthService: No refresh token available');
        }
        return false;
      }

      final response = await _api.post(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
        retryOnFailure: false, // Don't retry token refresh
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.saveAccessToken(data['accessToken']);
        if (data['refreshToken'] != null) {
          await _storage.saveRefreshToken(data['refreshToken']);
        }
        if (kDebugMode) {
          print('AuthService: Token refresh successful');
        }
        return true;
      }
      if (kDebugMode) {
        print('AuthService: Token refresh failed: ${response.data['message']}');
      }
      return false;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'AuthService: Error refreshing token');
      return false;
    } catch (e) {
      ErrorHandler.logError(e, context: 'AuthService: Error refreshing token');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<String?> getDriverId() async {
    return await _storage.getDriverId();
  }
}
