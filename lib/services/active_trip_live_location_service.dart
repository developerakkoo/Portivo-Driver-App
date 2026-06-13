import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../models/trip_model.dart';
import 'app_lifecycle_tracker.dart';
import 'location_stream_service.dart';
import 'socket_service.dart';

/// Keeps GPS streaming + Socket.IO `driver:location:update` running for the
/// current ACTIVE trip app-wide (not tied to [ActiveTripScreen]), until the
/// trip completes or leaves ACTIVE.
///
/// Also emits a fixed-cadence `driver:health:heartbeat` carrying GPS / network /
/// battery / app-state telemetry so the transporter can detect when the driver
/// loses GPS, goes offline, or backgrounds the app — independent of whether the
/// vehicle is moving.
class ActiveTripLiveLocationService {
  ActiveTripLiveLocationService._();
  static final ActiveTripLiveLocationService instance =
      ActiveTripLiveLocationService._();

  final LocationStreamService _locationStream = LocationStreamService();
  final SocketService _socket = SocketService();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  String? _trackingTripId;
  Timer? _heartbeatTimer;

  /// Heartbeat cadence; sent regardless of GPS movement.
  static const Duration _heartbeatInterval = Duration(seconds: 15);

  /// Start or continue streaming for [trip], or stop when not ACTIVE / null.
  Future<void> syncWithActiveTrip(TripModel? trip) async {
    final t = trip;
    if (t == null || t.status != AppConstants.tripStatusActive) {
      stop();
      return;
    }

    final id = t.id;
    if (id.isEmpty) return;

    if (_trackingTripId == id) {
      return;
    }

    _locationStream.stop();
    _trackingTripId = id;

    _locationStream.onPositionUpdate = (lat, lng, {accuracy, speed, heading}) {
      _socket.emitDriverLocationUpdate(
        tripId: id,
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        speed: speed,
        heading: heading,
      );
    };

    await _socket.connect();
    final result = await _locationStream.start();
    if (result != LocationStreamStartResult.started &&
        result != LocationStreamStartResult.alreadyRunning) {
      if (kDebugMode) {
        print('ActiveTripLiveLocation: could not start stream: $result');
      }
      _trackingTripId = null;
      _locationStream.stop();
      _stopHeartbeat();
      return;
    }

    if (kDebugMode) {
      print('ActiveTripLiveLocation: streaming for trip $id');
    }
    _startHeartbeat(id);
  }

  void _startHeartbeat(String tripId) {
    _stopHeartbeat();
    // Send one immediately so status is fresh, then on a fixed cadence.
    unawaited(_sendHeartbeat(tripId));
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      unawaited(_sendHeartbeat(tripId));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat(String tripId) async {
    if (_trackingTripId != tripId) return;
    bool? gpsEnabled;
    bool? networkConnected;
    int? batteryLevel;

    try {
      gpsEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {}
    try {
      final result = await _connectivity.checkConnectivity();
      networkConnected = !result.contains(ConnectivityResult.none);
    } catch (_) {}
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    if (_trackingTripId != tripId) return;
    _socket.emitDriverHealthHeartbeat(
      tripId: tripId,
      gpsEnabled: gpsEnabled,
      networkConnected: networkConnected,
      appState: AppLifecycleTracker.instance.appStateLabel,
      batteryLevel: batteryLevel,
    );
  }

  void stop() {
    if (_trackingTripId != null) {
      if (kDebugMode) {
        print('ActiveTripLiveLocation: stopped');
      }
    }
    _trackingTripId = null;
    _stopHeartbeat();
    _locationStream.stop();
  }
}
