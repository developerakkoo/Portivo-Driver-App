import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import 'api_service.dart';

class FuelService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> getAssignedFuelCard() async {
    try {
      final response = await _api.get(ApiConfig.fuelCardAssigned);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      if (kDebugMode) {
        print('FuelService: Error getting assigned card: $e');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('FuelService: Error getting assigned card: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> generateQR({
    required String vehicleNumber,
    required double amount,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? address,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.fuelGenerateQR,
        data: {
          'vehicleNumber': vehicleNumber,
          'amount': amount,
          'latitude': latitude,
          'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
          if (address != null) 'address': address,
        },
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('FuelService: Error generating QR: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> confirmTransaction({
    required String transactionId,
    required double amount,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.fuelConfirm,
        data: {
          'transactionId': transactionId,
          'amount': amount,
        },
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('FuelService: Error confirming transaction: $e');
      }
      rethrow;
    }
  }
}
