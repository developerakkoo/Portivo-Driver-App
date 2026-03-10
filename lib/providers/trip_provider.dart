import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/trip_model.dart';
import '../core/utils/error_handler.dart';
import '../services/trip_service.dart';
import '../services/socket_service.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();
  final SocketService _socketService = SocketService();

  TripModel? _activeTrip;
  List<TripModel> _queuedTrips = [];
  List<TripModel> _tripHistory = [];
  TripModel? _selectedTrip;
  bool _isLoading = false;
  String? _error;

  TripModel? get activeTrip => _activeTrip;
  List<TripModel> get queuedTrips => _queuedTrips;
  List<TripModel> get tripHistory => _tripHistory;
  TripModel? get selectedTrip => _selectedTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TripProvider() {
    _setupSocketListeners();
    _setupSocketConnectionListener();
  }

  void _setupSocketConnectionListener() {
    _socketService.onConnectionStateChanged = (state) {
      if (kDebugMode) {
        print('TripProvider: Socket connection state changed to $state');
      }
      // Rejoin rooms when reconnected
      if (state == SocketConnectionState.connected) {
        final activeTrip = _activeTrip;
        if (activeTrip != null) {
          _socketService.joinTripRoom(activeTrip.id);
          if (activeTrip.vehicleId.isNotEmpty) {
            _socketService.joinVehicleRoom(activeTrip.vehicleId);
          }
        }
      }
    };
  }

  void _setupSocketListeners() {
    _socketService.onTripStarted = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:started');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        _activeTrip = trip;
        // Remove from queued trips if it was there
        _queuedTrips.removeWhere((t) => t.id == trip.id);
        // Update selectedTrip if it's the same trip
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        // Join trip and vehicle rooms for real-time updates
        _joinTripRooms(trip);
        notifyListeners();
      }
    };

    _socketService.onTripMilestoneUpdated = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:milestone:updated');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        // Update activeTrip if it matches
        if (_activeTrip != null && _activeTrip!.id == trip.id) {
          _activeTrip = trip;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        // Update in history if it exists there
        final historyIndex = _tripHistory.indexWhere((t) => t.id == trip.id);
        if (historyIndex != -1) {
          _tripHistory[historyIndex] = trip;
        }
        notifyListeners();
      }
    };

    _socketService.onTripCompleted = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:completed');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        // Clear activeTrip if it matches
        if (_activeTrip?.id == trip.id) {
          _activeTrip = null;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        // Add to history (avoid duplicates)
        final existingIndex = _tripHistory.indexWhere((t) => t.id == trip.id);
        if (existingIndex != -1) {
          _tripHistory[existingIndex] = trip;
        } else {
          _tripHistory.insert(0, trip);
        }
        notifyListeners();
      }
    };

    _socketService.onTripAutoActivated = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:auto-activated');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        _activeTrip = trip;
        // Remove from queued trips if it was there
        _queuedTrips.removeWhere((t) => t.id == trip.id);
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        // Join trip and vehicle rooms for real-time updates
        _joinTripRooms(trip);
        notifyListeners();
      }
    };

    _socketService.onPODApproved = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - pod:approved');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        // Update in history
        final index = _tripHistory.indexWhere((t) => t.id == trip.id);
        if (index != -1) {
          _tripHistory[index] = trip;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        notifyListeners();
      }
    };

    _socketService.onTripCancelled = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:cancelled');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        // Clear activeTrip if it matches
        if (_activeTrip?.id == trip.id) {
          _activeTrip = null;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = null;
        }
        // Remove from queued trips
        _queuedTrips.removeWhere((t) => t.id == trip.id);
        notifyListeners();
      }
    };
  }

  /// Join socket rooms for a trip to receive real-time updates
  void _joinTripRooms(TripModel trip) {
    if (_socketService.isConnected) {
      _socketService.joinTripRoom(trip.id);
      if (trip.vehicleId.isNotEmpty) {
        _socketService.joinVehicleRoom(trip.vehicleId);
      }
    }
  }

  Future<void> loadActiveTrip({bool refresh = false}) async {
    if (!refresh && _activeTrip != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.getActiveTrip();
      _activeTrip = trip;
      // Join socket rooms for real-time updates
      if (trip != null) {
        _joinTripRooms(trip);
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error loading active trip');
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error loading active trip');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQueuedTrips({bool refresh = false}) async {
    if (!refresh && _queuedTrips.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trips = await _tripService.getQueuedTrips();
      _queuedTrips = trips;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error loading queued trips');
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error loading queued trips');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTripHistory({
    int page = 1,
    String? status,
    bool refresh = false,
  }) async {
    if (!refresh && _tripHistory.isNotEmpty && page == 1) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trips = await _tripService.getTripHistory(
        page: page,
        status: status,
      );
      if (refresh || page == 1) {
        _tripHistory = trips;
      } else {
        _tripHistory.addAll(trips);
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error loading trip history');
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error loading trip history');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TripModel?> getTripById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.getTripById(id);
      _selectedTrip = trip;
      // Join socket rooms for real-time updates if trip is active
      if (trip != null && trip.status == 'ACTIVE') {
        _joinTripRooms(trip);
      }
      return trip;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error getting trip');
      return null;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error getting trip');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startTrip(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Emit socket event first (if connected)
      if (_socketService.isConnected) {
        _socketService.emitTripStart(id);
      }
      
      // Then make API call
      final trip = await _tripService.startTrip(id);
      if (trip != null) {
        _activeTrip = trip;
        _queuedTrips.removeWhere((t) => t.id == id);
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == id) {
          _selectedTrip = trip;
        }
        // Join socket rooms for real-time updates
        _joinTripRooms(trip);
        notifyListeners();
        return true;
      }
      
      // If API call failed but socket was used, revert optimistic update
      _error = 'Failed to start trip';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error starting trip');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error starting trip');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeTrip(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Emit socket event first (if connected)
      if (_socketService.isConnected) {
        _socketService.emitTripComplete(id);
      }
      
      // Then make API call
      final trip = await _tripService.completeTrip(id);
      if (trip != null) {
        if (_activeTrip?.id == id) {
          _activeTrip = null;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == id) {
          _selectedTrip = trip;
        }
        // Add to history (avoid duplicates)
        final existingIndex = _tripHistory.indexWhere((t) => t.id == id);
        if (existingIndex != -1) {
          _tripHistory[existingIndex] = trip;
        } else {
          _tripHistory.insert(0, trip);
        }
        notifyListeners();
        return true;
      }
      
      _error = 'Failed to complete trip';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error completing trip');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error completing trip');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMilestone(
    String tripId,
    int milestoneNumber, {
    required double latitude,
    required double longitude,
    String? photoPath,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Emit socket event first (if connected)
      if (_socketService.isConnected) {
        _socketService.emitMilestoneUpdate(
          tripId: tripId,
          milestoneNumber: milestoneNumber,
          latitude: latitude,
          longitude: longitude,
          photo: photoPath,
          address: address,
        );
      }
      
      // Then make API call
      final trip = await _tripService.updateMilestone(
        tripId,
        milestoneNumber,
        latitude: latitude,
        longitude: longitude,
        photoPath: photoPath,
        address: address,
      );
      if (trip != null) {
        // Update activeTrip if it matches
        if (_activeTrip?.id == tripId) {
          _activeTrip = trip;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == tripId) {
          _selectedTrip = trip;
        }
        // Update in history if it exists there
        final historyIndex = _tripHistory.indexWhere((t) => t.id == tripId);
        if (historyIndex != -1) {
          _tripHistory[historyIndex] = trip;
        }
        notifyListeners();
        return true;
      }
      
      _error = 'Failed to update milestone';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error updating milestone');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error updating milestone');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPOD(String tripId, String photoPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.uploadPOD(tripId, photoPath);
      if (trip != null) {
        // Update in history
        final index = _tripHistory.indexWhere((t) => t.id == tripId);
        if (index != -1) {
          _tripHistory[index] = trip;
        } else {
          _tripHistory.insert(0, trip);
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == tripId) {
          _selectedTrip = trip;
        }
        // Update activeTrip if it matches (shouldn't happen for POD, but handle it)
        if (_activeTrip?.id == tripId) {
          _activeTrip = trip;
        }
        notifyListeners();
        return true;
      }
      _error = 'Failed to upload POD';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error uploading POD');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error uploading POD');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTrip(TripModel? trip) {
    _selectedTrip = trip;
    notifyListeners();
  }

  void refreshAll() {
    loadActiveTrip(refresh: true);
    loadQueuedTrips(refresh: true);
    loadTripHistory(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all trip data (used on logout)
  void clearAll() {
    _activeTrip = null;
    _queuedTrips = [];
    _tripHistory = [];
    _selectedTrip = null;
    _error = null;
    _isLoading = false;
    // Socket will be disconnected by AuthProvider on logout
    notifyListeners();
  }
}
