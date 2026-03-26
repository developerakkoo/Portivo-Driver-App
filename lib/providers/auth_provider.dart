import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/driver_model.dart';
import '../core/utils/error_handler.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        _isAuthenticated = true;
        if (kDebugMode) {
          print('AuthProvider: Found existing token, user is authenticated');
        }
        // Connect socket for real-time updates when app reopens with existing session
        final driverId = await _authService.getDriverId();
        if (driverId != null) {
          try {
            await _socketService.connect();
            _socketService.joinDriverRoom(driverId);
            if (kDebugMode) {
              print('AuthProvider: Socket connected for existing session, driver: $driverId');
            }
          } catch (e) {
            ErrorHandler.logError(e, context: 'AuthProvider: Socket connection on init (non-critical)');
          }
        }
      } else {
        if (kDebugMode) {
          print('AuthProvider: No existing token found');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('AuthProvider: Error during initialization: $e');
        print('Stack: $stackTrace');
      }
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithOTP(String mobile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('AuthProvider: Attempting OTP login for mobile: $mobile');
      }
      
      final response = await _authService.sendOTP(mobile);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _isLoading = false;
        
        if (kDebugMode) {
          print('AuthProvider: Login successful for user: ${_user!.id}');
        }
        
        // Connect Socket.IO after successful login
        try {
          await _socketService.connect();
          _socketService.joinDriverRoom(_user!.id);
          if (kDebugMode) {
            print('AuthProvider: Socket.IO connected and joined driver room: ${_user!.id}');
          }
        } catch (e) {
          ErrorHandler.logError(e, context: 'AuthProvider: Socket.IO connection failed (non-critical)');
        }
        
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        if (kDebugMode) {
          print('AuthProvider: Login failed: ${response.message}');
        }
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'AuthProvider: Login error');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'AuthProvider: Login error');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('AuthProvider: Logging out');
      }
      await _authService.logout();
      _socketService.disconnect();
      _user = null;
      _isAuthenticated = false;
      if (kDebugMode) {
        print('AuthProvider: Logout successful');
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'AuthProvider: Logout error');
      if (kDebugMode) {
        print('Stack: $stackTrace');
      }
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Hydrate user from driver profile after cold start (token exists but _user was null).
  void syncUserFromDriver(DriverModel driver) {
    _user = UserModel(
      id: driver.id,
      mobile: driver.mobile,
      name: driver.name,
      userType: 'driver',
      status: driver.status,
      hasPinSet: false,
      transporterId: driver.transporterId,
    );
    notifyListeners();
  }
}
