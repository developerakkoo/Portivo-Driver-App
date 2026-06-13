import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of [LocationStreamService.start].
enum LocationStreamStartResult {
  started,
  alreadyRunning,
  permissionDenied,
  locationServiceDisabled,
  failed,
}

/// Streams GPS position updates at a throttled interval during active trips.
///
/// On Android the stream runs inside a location **foreground service** (persistent
/// notification + wake lock) so tracking continues while the app is backgrounded
/// or the phone is locked. On iOS background location updates are enabled for the
/// same reason. Tracking is independent of milestone uploads.
class LocationStreamService {
  StreamSubscription<Position>? _subscription;
  Timer? _throttleTimer;
  Position? _lastPosition;
  DateTime? _lastEmitTime;

  /// Align with API TRACKING_UPDATE_INTERVAL_SECONDS (5s).
  static const Duration _throttleInterval = Duration(seconds: 5);

  /// Callback invoked when a new position should be sent (throttled to ~5s).
  void Function(
    double latitude,
    double longitude, {
    double? accuracy,
    double? speed,
    double? heading,
  })? onPositionUpdate;

  bool get isRunning => _subscription != null;

  /// Platform-specific settings that keep streaming alive in the background.
  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        // Push the OS for an update at least this often even when stationary,
        // so the heartbeat/last-updated stays fresh.
        intervalDuration: _throttleInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Porttivo trip in progress',
          notificationText: 'Sharing your live location with the transporter.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  /// Start streaming location. Callback is invoked at most every 5 seconds.
  Future<LocationStreamStartResult> start() async {
    if (_subscription != null) {
      return LocationStreamStartResult.alreadyRunning;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return LocationStreamStartResult.permissionDenied;
      }
    } else if (permission == LocationPermission.deniedForever) {
      return LocationStreamStartResult.permissionDenied;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStreamStartResult.locationServiceDisabled;
    }

    try {
      // Emit first position immediately for a responsive marker.
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = initialPosition;
      _emitIfNeeded();

      _subscription =
          Geolocator.getPositionStream(locationSettings: _buildLocationSettings())
              .listen(
        (position) {
          _lastPosition = position;
          _maybeEmit();
        },
        onError: (Object e) {
          if (kDebugMode) {
            print('LocationStreamService: position stream error: $e');
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('LocationStreamService: failed to start stream: $e');
      }
      return LocationStreamStartResult.failed;
    }

    return LocationStreamStartResult.started;
  }

  void _maybeEmit() {
    if (_lastPosition == null) return;
    final now = DateTime.now();
    if (_lastEmitTime == null ||
        now.difference(_lastEmitTime!) >= _throttleInterval) {
      _emitIfNeeded();
    } else if (_throttleTimer == null || !_throttleTimer!.isActive) {
      final remaining = _throttleInterval - now.difference(_lastEmitTime!);
      _throttleTimer = Timer(remaining, () {
        _emitIfNeeded();
        _throttleTimer = null;
      });
    }
  }

  void _emitIfNeeded() {
    final pos = _lastPosition;
    if (pos == null || onPositionUpdate == null) return;
    _lastEmitTime = DateTime.now();
    onPositionUpdate!(
      pos.latitude,
      pos.longitude,
      accuracy: pos.accuracy,
      speed: pos.speed,
      heading: pos.heading,
    );
  }

  /// Stop streaming and clear resources.
  void stop() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _lastPosition = null;
    _lastEmitTime = null;
  }
}
