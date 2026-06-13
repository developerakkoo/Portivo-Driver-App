import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/trip_model.dart';
import '../core/utils/error_handler.dart';
import '../services/trip_service.dart';
import '../services/socket_service.dart';
import '../services/active_trip_live_location_service.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();
  final SocketService _socketService = SocketService();

  /// Called after socket queues a trip from [trip:driver:assigned] (e.g. refresh notification badge).
  final void Function()? onTripDriverAssigned;

  TripModel? _activeTrip;
  List<TripModel> _queuedTrips = [];
  List<TripModel> _tripHistory = [];
  TripModel? _selectedTrip;
  bool _isLoading = false;
  String? _error;

  TripModel? get activeTrip => _activeTrip;

  /// Active trip only when assigned to [driverId] with valid ids (aligns with Trips tab).
  TripModel? activeTripForDriver(String? driverId) {
    final t = _activeTrip;
    if (t == null || driverId == null) return null;
    if (t.id.isEmpty) return null;
    final did = t.driverId;
    if (did == null || did.isEmpty) return null;
    if (did != driverId) return null;
    return t;
  }

  List<TripModel> get queuedTrips => _queuedTrips;
  List<TripModel> get tripHistory => _tripHistory;
  TripModel? get selectedTrip => _selectedTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Queued trips that should show a short green border highlight (new assignment).
  final Set<String> _highlightQueuedTripIds = <String>{};
  bool isQueuedTripHighlighted(String tripId) =>
      _highlightQueuedTripIds.contains(tripId);

  void _flashHighlightQueuedTrip(String tripId) {
    _highlightQueuedTripIds.add(tripId);
    notifyListeners();
    Future<void>.delayed(const Duration(seconds: 3), () {
      _highlightQueuedTripIds.remove(tripId);
      notifyListeners();
    });
  }

  TripProvider({this.onTripDriverAssigned}) {
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
        loadActiveTrip(refresh: true);
        loadQueuedTrips(refresh: true);
      }
      notifyListeners();
    };
  }

  void _setupSocketListeners() {
    _socketService.onTripUpdated = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:updated');
      }
      if (data['trip'] == null) return;
      final trip = TripModel.fromJson(data['trip']);
      if (_activeTrip?.id == trip.id) {
        _activeTrip = trip;
      }
      _syncLiveLocationTracking();
      final qi = _queuedTrips.indexWhere((t) => t.id == trip.id);
      if (qi != -1) {
        _queuedTrips[qi] = trip;
      }
      final hi = _tripHistory.indexWhere((t) => t.id == trip.id);
      if (hi != -1) {
        _tripHistory[hi] = trip;
      }
      if (_selectedTrip?.id == trip.id) {
        _selectedTrip = trip;
      }
      notifyListeners();
    };

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
        _syncLiveLocationTracking();
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
        _syncLiveLocationTracking();
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
        _syncLiveLocationTracking();
        notifyListeners();
      }
    };

    _socketService.onTripPodPending = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:pod:pending');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        // Clear activeTrip - trip moved to POD_PENDING
        if (_activeTrip?.id == trip.id) {
          _activeTrip = null;
        }
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        // Update in history
        final historyIndex = _tripHistory.indexWhere((t) => t.id == trip.id);
        if (historyIndex != -1) {
          _tripHistory[historyIndex] = trip;
        } else {
          _tripHistory.insert(0, trip);
        }
        _syncLiveLocationTracking();
        notifyListeners();
      }
    };

    _socketService.onTripPodUploaded = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:pod:uploaded');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        // Update selectedTrip if it matches
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        // Update in history
        final historyIndex = _tripHistory.indexWhere((t) => t.id == trip.id);
        if (historyIndex != -1) {
          _tripHistory[historyIndex] = trip;
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
        _syncLiveLocationTracking();
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
        _syncLiveLocationTracking();
        notifyListeners();
      }
    };

    _socketService.onTripCustomerAssigned = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:customer:assigned');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        _addToQueuedTrips(trip);
        notifyListeners();
      }
    };

    _socketService.onTripDriverAssigned = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:driver:assigned');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        _addToQueuedTrips(trip);
        _flashHighlightQueuedTrip(trip.id);
        notifyListeners();
        onTripDriverAssigned?.call();
      }
    };

    _socketService.onTripVehicleAssigned = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:vehicle:assigned');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        _addToQueuedTrips(trip);
        notifyListeners();
      }
    };

    _socketService.onTripClosedWithoutPOD = (data) {
      if (kDebugMode) {
        print('TripProvider: Socket event - trip:closed:without-pod');
      }
      if (data['trip'] != null) {
        final trip = TripModel.fromJson(data['trip']);
        if (_activeTrip?.id == trip.id) {
          _activeTrip = null;
        }
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = trip;
        }
        _queuedTrips.removeWhere((t) => t.id == trip.id);
        final historyIndex = _tripHistory.indexWhere((t) => t.id == trip.id);
        if (historyIndex != -1) {
          _tripHistory[historyIndex] = trip;
        } else {
          _tripHistory.insert(0, trip);
        }
        _syncLiveLocationTracking();
        notifyListeners();
      }
    };
  }

  void _addToQueuedTrips(TripModel trip) {
    final existingIndex = _queuedTrips.indexWhere((t) => t.id == trip.id);
    if (existingIndex != -1) {
      _queuedTrips[existingIndex] = trip;
    } else {
      _queuedTrips.insert(0, trip);
    }
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

  void _syncLiveLocationTracking() {
    unawaited(ActiveTripLiveLocationService.instance.syncWithActiveTrip(_activeTrip));
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
      _syncLiveLocationTracking();
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

  TripModel? getTripForDetail(String id) {
    if (_selectedTrip?.id == id) return _selectedTrip;
    if (_activeTrip?.id == id) return _activeTrip;
    try {
      return _tripHistory.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TripModel?> getTripById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.getTripById(id);
      _selectedTrip = trip;
      // Join socket rooms for real-time updates if trip is active or POD pending
      if (trip != null &&
          (trip.status == 'ACTIVE' || trip.status == 'POD_PENDING')) {
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

  Future<bool> updateTrip(String id, Map<String, dynamic> tripData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.updateTrip(id, tripData);
      if (trip != null) {
        if (_activeTrip?.id == id) {
          _activeTrip = trip;
        }
        if (_selectedTrip?.id == id) {
          _selectedTrip = trip;
        }
        final historyIndex = _tripHistory.indexWhere((t) => t.id == id);
        if (historyIndex != -1) {
          _tripHistory[historyIndex] = trip;
        }
        final queuedIndex = _queuedTrips.indexWhere((t) => t.id == id);
        if (queuedIndex != -1) {
          _queuedTrips[queuedIndex] = trip;
        }
        _syncLiveLocationTracking();
        notifyListeners();
        return true;
      }
      _error = 'Failed to update trip';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error updating trip');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error updating trip');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptTrip(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.acceptTrip(id);
      if (trip != null) {
        // Update in queued trips
        final queuedIndex = _queuedTrips.indexWhere((t) => t.id == id);
        if (queuedIndex != -1) {
          _queuedTrips[queuedIndex] = trip;
        }
        if (_selectedTrip?.id == id) {
          _selectedTrip = trip;
        }
        notifyListeners();
        return true;
      }
      _error = 'Failed to accept trip';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error accepting trip');
      notifyListeners();
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError(e, context: 'TripProvider: Error accepting trip');
      notifyListeners();
      return false;
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
        // Background location is requested from the UI via
        // BackgroundLocationConsent after a prominent disclosure (store policy);
        // tracking still works in the foreground until then.
        _syncLiveLocationTracking();
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
        _syncLiveLocationTracking();
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
    List<String>? photoPaths,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Only use HTTP API - backend updates DB and emits trip:milestone:updated.
      // Do NOT emit socket from driver; if API fails (e.g. 413), no status change.
      final trip = await _tripService.updateMilestone(
        tripId,
        milestoneNumber,
        latitude: latitude,
        longitude: longitude,
        photoPath: photoPath,
        photoPaths: photoPaths,
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
        _socketService.emitDriverLocationUpdate(
          tripId: tripId,
          latitude: latitude,
          longitude: longitude,
        );
        _syncLiveLocationTracking();
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
        _syncLiveLocationTracking();
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
    ActiveTripLiveLocationService.instance.stop();
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
