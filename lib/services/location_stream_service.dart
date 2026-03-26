import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Outcome of [LocationStreamService.start].
enum LocationStreamStartResult {
  started,
  alreadyRunning,
  permissionDenied,
  locationServiceDisabled,
  failed,
}

/// Service that streams GPS position updates at a throttled interval.
/// Designed for real-time driver location updates during active trips.
class LocationStreamService {
  StreamSubscription<Position>? _subscription;
  Timer? _throttleTimer;
  Position? _lastPosition;
  DateTime? _lastEmitTime;
  static const Duration _throttleInterval = Duration(seconds: 15);

  /// Callback invoked when a new position should be sent (throttled to ~15s)
  void Function(double latitude, double longitude)? onPositionUpdate;

  /// Start streaming location. Callback is invoked at most every 15 seconds.
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
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStreamStartResult.locationServiceDisabled;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    try {
      // Emit first position immediately
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = initialPosition;
      _emitIfNeeded();

      _subscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((position) {
        _lastPosition = position;
        _maybeEmit();
      });
    } catch (_) {
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
    if (_lastPosition == null || onPositionUpdate == null) return;
    _lastEmitTime = DateTime.now();
    onPositionUpdate!(_lastPosition!.latitude, _lastPosition!.longitude);
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
