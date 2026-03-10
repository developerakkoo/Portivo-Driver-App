import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/utils/json_parser.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/image_utils.dart';
import '../models/trip_model.dart';
import 'api_service.dart';

class TripService {
  final ApiService _api = ApiService();

  Future<TripModel?> getActiveTrip() async {
    try {
      if (kDebugMode) {
        print('TripService: Fetching active trip');
      }
      
      final response = await _api.get(ApiConfig.driverActiveTrip);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['trip'] != null) {
          // Handle null trip (no active trip)
          if (data['trip'] == null) {
            return null;
          }
          final tripData = data['trip'];
          if (tripData is Map<String, dynamic>) {
            return TripModel.fromJson(tripData);
          } else if (tripData is Map) {
            return TripModel.fromJson(Map<String, dynamic>.from(tripData));
          }
        }
        // Fallback
        if (data != null && data is Map) {
          if (data is Map<String, dynamic>) {
            return TripModel.fromJson(data);
          } else {
            return TripModel.fromJson(Map<String, dynamic>.from(data));
          }
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching active trip');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching active trip');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<List<TripModel>> getQueuedTrips() async {
    try {
      if (kDebugMode) {
        print('TripService: Fetching queued trips');
      }
      
      final response = await _api.get(ApiConfig.driverQueuedTrips);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        List<dynamic> tripsData = [];
        
        if (data is List) {
          tripsData = data;
        } else if (data is Map && data['trips'] != null) {
          final trips = data['trips'];
          if (trips is List) {
            tripsData = trips;
          }
        }
        
        if (tripsData.isNotEmpty) {
          return JsonParser.extractList<TripModel>(
            tripsData,
            (json) => TripModel.fromJson(json),
          );
        }
      }
      return [];
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching queued trips');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching queued trips');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<List<TripModel>> getTripHistory({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      if (kDebugMode) {
        print('TripService: Fetching trip history');
      }
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _api.get(
        ApiConfig.driverTripHistory,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        List<dynamic> tripsData = [];
        
        if (data is List) {
          tripsData = data;
        } else if (data is Map && data['trips'] != null) {
          final trips = data['trips'];
          if (trips is List) {
            tripsData = trips;
          }
        }
        
        if (tripsData.isNotEmpty) {
          return JsonParser.extractList<TripModel>(
            tripsData,
            (json) => TripModel.fromJson(json),
          );
        }
      }
      return [];
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching trip history');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching trip history');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<TripModel?> getTripById(String id) async {
    try {
      if (kDebugMode) {
        print('TripService: Fetching trip by ID: $id');
      }
      
      final response = await _api.get(ApiConfig.tripById(id));

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        if (data != null && data is Map && data['trip'] != null) {
          final tripData = data['trip'];
          if (tripData is Map<String, dynamic>) {
            return TripModel.fromJson(tripData);
          } else if (tripData is Map) {
            return TripModel.fromJson(Map<String, dynamic>.from(tripData));
          }
        }
        
        if (data != null && data is Map) {
          if (data is Map<String, dynamic>) {
            return TripModel.fromJson(data);
          } else {
            return TripModel.fromJson(Map<String, dynamic>.from(data));
          }
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching trip by ID');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching trip by ID');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<TripModel?> startTrip(String id) async {
    try {
      if (kDebugMode) {
        print('TripService: Starting trip: $id');
      }
      
      final response = await _api.put(ApiConfig.tripStart(id));

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['trip'] != null) {
          final tripData = data['trip'];
          if (tripData is Map<String, dynamic>) {
            return TripModel.fromJson(tripData);
          } else if (tripData is Map) {
            return TripModel.fromJson(Map<String, dynamic>.from(tripData));
          }
        }
        if (data != null && data is Map) {
          if (data is Map<String, dynamic>) {
            return TripModel.fromJson(data);
          } else {
            return TripModel.fromJson(Map<String, dynamic>.from(data));
          }
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error starting trip');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error starting trip');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<TripModel?> completeTrip(String id) async {
    try {
      if (kDebugMode) {
        print('TripService: Completing trip: $id');
      }
      
      final response = await _api.put(ApiConfig.tripComplete(id));

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['trip'] != null) {
          final tripData = data['trip'];
          if (tripData is Map<String, dynamic>) {
            return TripModel.fromJson(tripData);
          } else if (tripData is Map) {
            return TripModel.fromJson(Map<String, dynamic>.from(tripData));
          }
        }
        if (data != null && data is Map) {
          if (data is Map<String, dynamic>) {
            return TripModel.fromJson(data);
          } else {
            return TripModel.fromJson(Map<String, dynamic>.from(data));
          }
        }
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error completing trip');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error completing trip');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<TripModel?> updateMilestone(
    String tripId,
    int milestoneNumber, {
    required double latitude,
    required double longitude,
    String? photoPath,
    String? address,
  }) async {
    try {
      if (kDebugMode) {
        print('TripService: Updating milestone $milestoneNumber for trip: $tripId');
      }
      
      // Validate inputs
      if (tripId.isEmpty) {
        throw Exception('Trip ID is required');
      }
      if (milestoneNumber < 1 || milestoneNumber > 5) {
        throw Exception('Milestone number must be between 1 and 5');
      }
      if (latitude < -90 || latitude > 90) {
        throw Exception('Invalid latitude value');
      }
      if (longitude < -180 || longitude > 180) {
        throw Exception('Invalid longitude value');
      }
      
      if (photoPath != null) {
        // Compress image before upload
        String finalPhotoPath = photoPath;
        try {
          if (await ImageUtils.needsCompression(photoPath)) {
            if (kDebugMode) {
              print('TripService: Compressing image before upload');
            }
            finalPhotoPath = await ImageUtils.compressImage(photoPath);
          }
        } catch (e) {
          if (kDebugMode) {
            print('TripService: Error compressing image, using original: $e');
          }
          // Continue with original image if compression fails
        }

        // Upload with photo (multipart)
        final formData = FormData.fromMap({
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
          'photo': await MultipartFile.fromFile(finalPhotoPath),
        });

        final response = await _api.postMultipart(
          ApiConfig.tripMilestone(tripId, milestoneNumber),
          formData: formData,
        );

        if (response.data['success'] == true) {
          final data = response.data['data'];
          if (data != null && data['trip'] != null) {
            final tripData = data['trip'];
            if (tripData is Map<String, dynamic>) {
              return TripModel.fromJson(tripData);
            } else if (tripData is Map) {
              return TripModel.fromJson(Map<String, dynamic>.from(tripData));
            }
          }
          if (data != null && data is Map) {
            if (data is Map<String, dynamic>) {
              return TripModel.fromJson(data);
            } else {
              return TripModel.fromJson(Map<String, dynamic>.from(data));
            }
          }
        }
      } else {
        // Upload without photo (JSON)
        final response = await _api.post(
          ApiConfig.tripMilestone(tripId, milestoneNumber),
          data: {
            'latitude': latitude,
            'longitude': longitude,
            if (address != null) 'address': address,
          },
        );

        if (response.data['success'] == true) {
          final data = response.data['data'];
          if (data != null && data['trip'] != null) {
            final tripData = data['trip'];
            if (tripData is Map<String, dynamic>) {
              return TripModel.fromJson(tripData);
            } else if (tripData is Map) {
              return TripModel.fromJson(Map<String, dynamic>.from(tripData));
            }
          }
          if (data != null && data is Map) {
            if (data is Map<String, dynamic>) {
              return TripModel.fromJson(data);
            } else {
              return TripModel.fromJson(Map<String, dynamic>.from(data));
            }
          }
        }
      }
      throw Exception('Failed to update milestone: Invalid response format');
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error updating milestone');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error updating milestone');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCurrentMilestone(String tripId) async {
    try {
      final response = await _api.get(ApiConfig.tripCurrentMilestone(tripId));

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching current milestone');
      rethrow;
    } catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching current milestone');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTripTimeline(String tripId) async {
    try {
      final response = await _api.get(ApiConfig.tripTimeline(tripId));

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching trip timeline');
      rethrow;
    } catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error fetching trip timeline');
      rethrow;
    }
  }

  Future<TripModel?> uploadPOD(String tripId, String photoPath) async {
    try {
      if (kDebugMode) {
        print('TripService: Uploading POD for trip: $tripId');
      }
      
      // Validate inputs
      if (tripId.isEmpty) {
        throw Exception('Trip ID is required');
      }
      if (photoPath.isEmpty) {
        throw Exception('Photo path is required');
      }
      
      // Compress image before upload
      String finalPhotoPath = photoPath;
      try {
        if (await ImageUtils.needsCompression(photoPath)) {
          if (kDebugMode) {
            print('TripService: Compressing POD image before upload');
          }
          finalPhotoPath = await ImageUtils.compressImage(photoPath);
        }
      } catch (e) {
        if (kDebugMode) {
          print('TripService: Error compressing POD image, using original: $e');
        }
        // Continue with original image if compression fails
      }
      
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(finalPhotoPath),
      });

      final response = await _api.postMultipart(
        ApiConfig.tripPOD(tripId),
        formData: formData,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['trip'] != null) {
          final tripData = data['trip'];
          if (tripData is Map<String, dynamic>) {
            return TripModel.fromJson(tripData);
          } else if (tripData is Map) {
            return TripModel.fromJson(Map<String, dynamic>.from(tripData));
          }
        }
        if (data != null && data is Map) {
          if (data is Map<String, dynamic>) {
            return TripModel.fromJson(data);
          } else {
            return TripModel.fromJson(Map<String, dynamic>.from(data));
          }
        }
      }
      throw Exception('Failed to upload POD: Invalid response format');
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'TripService: Error uploading POD');
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'TripService: Error uploading POD');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }
}
