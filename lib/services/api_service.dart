import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/network_utils.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  late Dio _dio;
  final StorageService _storage = StorageService();

  BaseOptions get _baseOptions => BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kDebugMode) {
            print('ApiService: ${options.method} ${options.path}');
            print('ApiService: Full URL: ${options.uri}');
          }
          try {
            // Ensure storage is initialized
            if (!_storage.isInitialized) {
              await _storage.init();
            }
            
            // Add access token to headers
            final token = await _storage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              if (kDebugMode) {
                print('ApiService: Token added to request: ${options.path}');
              }
            } else {
              if (kDebugMode) {
                print('ApiService: WARNING - No token found for request: ${options.path}');
              }
            }
          } catch (e) {
            ErrorHandler.logError(e, context: 'ApiService: Error getting token');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          ErrorHandler.logError(error, context: 'ApiService: Request error');
          
          // Handle 401 Unauthorized - try to refresh token
          if (error.response?.statusCode == 401) {
            if (kDebugMode) {
              print('ApiService: 401 Unauthorized, attempting token refresh');
            }
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                if (kDebugMode) {
                  print('ApiService: Token refreshed, retrying request');
                }
                // Retry the original request
                final opts = error.requestOptions;
                final token = await _storage.getAccessToken();
                if (token != null) {
                  opts.headers['Authorization'] = 'Bearer $token';
                  final response = await _dio.request(
                    opts.path,
                    options: Options(
                      method: opts.method,
                      headers: opts.headers,
                    ),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );
                  return handler.resolve(response);
                } else {
                  if (kDebugMode) {
                    print('ApiService: Token refresh succeeded but no token retrieved');
                  }
                }
              } else {
                if (kDebugMode) {
                  print('ApiService: Token refresh failed');
                }
                // Clear tokens on refresh failure
                await _storage.clearTokens();
              }
            } catch (e) {
              ErrorHandler.logError(e, context: 'ApiService: Error during token refresh');
              // Refresh failed, clear tokens
              await _storage.clearTokens();
            }
          }
          
          // Handle 403 Forbidden - clear tokens and logout
          if (error.response?.statusCode == 403) {
            if (kDebugMode) {
              print('ApiService: 403 Forbidden - Access denied');
            }
            await _storage.clearTokens();
          }
          
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      if (kDebugMode) {
        print('ApiService: Attempting token refresh');
      }
      
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        if (kDebugMode) {
          print('ApiService: No refresh token available');
        }
        return false;
      }

      // Use a separate Dio instance to avoid interceptors
      final refreshDio = Dio(_baseOptions);
      final response = await refreshDio.post(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.saveAccessToken(data['accessToken']);
        if (data['refreshToken'] != null) {
          await _storage.saveRefreshToken(data['refreshToken']);
        }
        if (kDebugMode) {
          print('ApiService: Token refresh successful');
        }
        return true;
      }
      
      if (kDebugMode) {
        print('ApiService: Token refresh failed: ${response.data['message']}');
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: Token refresh error');
      return false;
    }
  }

  /// Retry request with exponential backoff
  Future<Response> _retryRequest(
    Future<Response> Function() request, {
    int maxAttempts = ApiConfig.maxRetryAttempts,
  }) async {
    int attempt = 0;
    Duration delay = ApiConfig.retryDelay;

    while (attempt < maxAttempts) {
      try {
        return await request();
      } on DioException catch (e) {
        attempt++;
        
        // Check if error is retryable
        if (!ErrorHandler.isRetryable(e) || attempt >= maxAttempts) {
          rethrow;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * ApiConfig.retryBackoffMultiplier).round(),
        );

        if (kDebugMode) {
          print('ApiService: Retrying request (attempt $attempt/$maxAttempts)');
        }
      }
    }

    throw Exception('Max retry attempts reached');
  }

  // GET request with retry logic
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool retryOnFailure = true,
  }) async {
    try {
      // Check network connectivity before making request
      if (!await NetworkUtils.hasInternetConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }

      if (retryOnFailure) {
        return await _retryRequest(() => _dio.get(
              path,
              queryParameters: queryParameters,
              options: options,
            ));
      } else {
        return await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: GET $path');
      rethrow;
    }
  }

  // POST request with retry logic
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool retryOnFailure = true,
  }) async {
    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }

      if (retryOnFailure) {
        return await _retryRequest(() => _dio.post(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            ));
      } else {
        return await _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: POST $path');
      rethrow;
    }
  }

  // PUT request with retry logic
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool retryOnFailure = true,
  }) async {
    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }

      if (retryOnFailure) {
        return await _retryRequest(() => _dio.put(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            ));
      } else {
        return await _dio.put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: PUT $path');
      rethrow;
    }
  }

  // DELETE request with retry logic
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool retryOnFailure = true,
  }) async {
    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }

      if (retryOnFailure) {
        return await _retryRequest(() => _dio.delete(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            ));
      } else {
        return await _dio.delete(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: DELETE $path');
      rethrow;
    }
  }

  // POST with file upload (multipart) with retry logic
  Future<Response> postMultipart(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool retryOnFailure = true,
    Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }

      final requestOptions = options ??
          Options(
            contentType: 'multipart/form-data',
          );

      if (retryOnFailure) {
        return await _retryRequest(() => _dio.post(
              path,
              data: formData,
              queryParameters: queryParameters,
              options: requestOptions,
              onSendProgress: onSendProgress,
            ));
      } else {
        return await _dio.post(
          path,
          data: formData,
          queryParameters: queryParameters,
          options: requestOptions,
          onSendProgress: onSendProgress,
        );
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: POST Multipart $path');
      rethrow;
    }
  }

  /// Normalize and validate API response structure
  Map<String, dynamic> normalizeResponse(Response response) {
    try {
      final data = response.data;
      
      if (data is! Map) {
        if (kDebugMode) {
          print('ApiService: Response data is not a Map: ${data.runtimeType}');
        }
        return {
          'success': false,
          'message': 'Invalid response format',
          'data': null,
        };
      }
      
      final responseMap = data as Map<String, dynamic>;
      
      if (!responseMap.containsKey('success')) {
        if (kDebugMode) {
          print('ApiService: Response missing success field');
        }
        responseMap['success'] = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      }
      
      if (!responseMap.containsKey('data')) {
        if (kDebugMode) {
          print('ApiService: Response missing data field');
        }
        responseMap['data'] = null;
      }
      
      return responseMap;
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error normalizing response: $e');
      }
      return {
        'success': false,
        'message': 'Error processing response',
        'data': null,
      };
    }
  }

  /// Validate response has success = true
  bool isSuccessResponse(Response response) {
    try {
      final normalized = normalizeResponse(response);
      return normalized['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error validating success response: $e');
      }
      return false;
    }
  }

  /// Extract data from response safely
  dynamic extractResponseData(Response response) {
    try {
      final normalized = normalizeResponse(response);
      return normalized['data'];
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error extracting response data: $e');
      }
      return null;
    }
  }

  /// Extract error message from response
  String extractErrorMessage(Response response) {
    try {
      final normalized = normalizeResponse(response);
      return normalized['message']?.toString() ?? 
             normalized['error']?.toString() ?? 
             'Unknown error occurred';
    } catch (e) {
      ErrorHandler.logError(e, context: 'ApiService: Error extracting error message');
      return 'Error processing response';
    }
  }

  /// Extract error message from DioException
  String extractDioErrorMessage(DioException error) {
    return ErrorHandler.getErrorMessage(error);
  }

  Dio get dio => _dio;
}
