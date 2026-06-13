import 'dart:async';
import 'dart:collection';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../core/config/api_config.dart';

/// Socket connection state
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storage = StorageService();
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  Timer? _heartbeatTimer;
  String? _driverId;
  String? _vehicleId;
  String? _tripId;

  /// Ordered buffer of driver location fixes captured while the socket was not
  /// ready (e.g. internet dropped). Flushed in order on reconnect so the trail
  /// has no gaps. Capped to avoid unbounded memory growth on long outages.
  static const int _maxBufferedLocations = 240; // ~20 min at one fix / 5s
  final Queue<Map<String, dynamic>> _locationBuffer =
      Queue<Map<String, dynamic>>();

  // Event callbacks
  Function(Map<String, dynamic>)? onTripStarted;
  Function(Map<String, dynamic>)? onTripMilestoneUpdated;
  Function(Map<String, dynamic>)? onTripCompleted;
  Function(Map<String, dynamic>)? onTripPodPending;
  Function(Map<String, dynamic>)? onTripPodUploaded;
  Function(Map<String, dynamic>)? onTripAutoActivated;
  Function(Map<String, dynamic>)? onPODApproved;
  Function(Map<String, dynamic>)? onTripCancelled;
  Function(Map<String, dynamic>)? onTripCustomerAssigned;
  Function(Map<String, dynamic>)? onTripDriverAssigned;
  Function(Map<String, dynamic>)? onTripVehicleAssigned;
  Function(Map<String, dynamic>)? onTripClosedWithoutPOD;
  Function(Map<String, dynamic>)? onTripUpdated;
  Function(SocketConnectionState)? onConnectionStateChanged;
  Function(String)? onError;

  bool get isConnected => _connectionState == SocketConnectionState.connected;
  SocketConnectionState get connectionState => _connectionState;

  /// Whether the underlying Socket.IO client is connected (source of truth for emits).
  bool get _socketIoConnected => _socket != null && _socket!.connected;

  void _flushLocationBuffer() {
    if (!_socketIoConnected || _locationBuffer.isEmpty) return;
    final count = _locationBuffer.length;

    // Replay buffered fixes in order using the per-fix `driver:location:update`
    // event so delivery works regardless of whether the server has the newer
    // `driver:location:batch` endpoint deployed.
    while (_locationBuffer.isNotEmpty && _socketIoConnected) {
      final fix = _locationBuffer.removeFirst();
      _socket!.emit('driver:location:update', fix);
    }

    if (kDebugMode) {
      print('SocketService: Flushed $count buffered driver location(s)');
    }
  }

  Future<void> connect() async {
    // Idempotent: when a socket already exists, Socket.IO's built-in
    // reconnection owns retries — never tear it down here (that would restart
    // the backoff and can starve buffered location flushes during a trip).
    if (_socket != null) {
      if (_socketIoConnected) {
        _setConnectionState(SocketConnectionState.connected);
      } else if (_socket!.disconnected) {
        // Built-in reconnection is not running (e.g. server-forced disconnect);
        // nudge a fresh connection on the existing instance.
        _setConnectionState(SocketConnectionState.connecting);
        _socket!.connect();
      } else if (kDebugMode) {
        print('SocketService: Connection already in progress');
      }
      return;
    }

    try {
      _setConnectionState(SocketConnectionState.connecting);

      final token = await _storage.getAccessToken();
      if (token == null) {
        if (kDebugMode) {
          print('SocketService: No access token available - skipping connection');
        }
        _setConnectionState(SocketConnectionState.disconnected);
        return;
      }

      // Extract base URL from ApiConfig
      final baseUrl = ApiConfig.socketUrl;

      if (kDebugMode) {
        print('SocketService: Connecting to $baseUrl (path ${ApiConfig.socketPath})');
      }

      // Flutter / dart:io: Engine.IO polling over XHR is not supported like in
      // the browser. Using polling first causes connect timeouts while curl to
      // /socket.io still works. WebSocket-only matches socket_io_client on
      // mobile. (Mirrors the transporter app's proven config — do not revert.)
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setPath(ApiConfig.socketPath)
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setTimeout(ApiConfig.socketConnectionTimeout.inMilliseconds)
            .setReconnectionAttempts(ApiConfig.socketMaxReconnectAttempts)
            .setReconnectionDelay(ApiConfig.socketReconnectDelay.inMilliseconds)
            .setReconnectionDelayMax(
              ApiConfig.socketReconnectDelayMax.inMilliseconds,
            )
            .setRandomizationFactor(0.5)
            .enableReconnection()
            .disableAutoConnect()
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('SocketService: Connection error: $e');
        print('Stack: $stackTrace');
      }
      _setConnectionState(SocketConnectionState.error);
    }
  }

  void _setConnectionState(SocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      onConnectionStateChanged?.call(state);
      if (kDebugMode) {
        print('SocketService: Connection state changed to $state');
      }
    }
  }

  /// Shared handling for the first connect and every subsequent reconnect:
  /// mark connected, restart the heartbeat, rejoin rooms, and flush any
  /// buffered location fixes so the transporter's trail has no gaps.
  void _onConnectedOrReconnected() {
    _setConnectionState(SocketConnectionState.connected);
    _startHeartbeat();

    if (_driverId != null) {
      joinDriverRoom(_driverId!);
    }
    if (_vehicleId != null) {
      joinVehicleRoom(_vehicleId!);
    }
    if (_tripId != null) {
      joinTripRoom(_tripId!);
    }
    _flushLocationBuffer();
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _onConnectedOrReconnected();
      if (kDebugMode) {
        print('SocketService: Connected successfully');
      }
    });

    // Fires on every successful built-in reconnection after a drop.
    _socket!.on('reconnect', (_) {
      _onConnectedOrReconnected();
      if (kDebugMode) {
        print('SocketService: Reconnected — rooms re-joined, buffer flushed');
      }
    });

    _socket!.onDisconnect((reason) {
      _setConnectionState(SocketConnectionState.disconnected);
      _stopHeartbeat();

      if (kDebugMode) {
        print('SocketService: Disconnected - $reason');
      }

      // 'io server disconnect' means the server dropped us and the client will
      // NOT auto-reconnect; restart manually. All other reasons are handled by
      // Socket.IO's built-in reconnection.
      if (reason == 'io server disconnect') {
        _socket?.connect();
      }
    });

    _socket!.onConnectError((error) {
      _setConnectionState(SocketConnectionState.error);
      _stopHeartbeat();

      if (kDebugMode) {
        print('SocketService: Connection error: $error');
      }

      onError?.call(error.toString());
      // Built-in reconnection retries automatically; do not schedule here.
    });

    // Built-in reconnection exhausted its attempt burst. While the driver may
    // still be on an active trip we must never permanently give up: hard-reset
    // the instance and start a fresh connection cycle.
    _socket!.on('reconnect_failed', (_) {
      if (kDebugMode) {
        print('SocketService: Reconnect attempts exhausted — hard reset');
      }
      _setConnectionState(SocketConnectionState.error);
      _socket?.dispose();
      _socket = null;
      connect();
    });

    _socket!.onError((error) {
      if (kDebugMode) {
        print('SocketService: Error: $error');
      }
      onError?.call(error.toString());
    });

    // Trip events
    _socket!.on('trip:updated', (data) {
      if (kDebugMode) {
        print('SocketService: trip:updated - $data');
      }
      onTripUpdated?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:started', (data) {
      if (kDebugMode) {
        print('SocketService: trip:started - $data');
      }
      onTripStarted?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:milestone:updated', (data) {
      if (kDebugMode) {
        print('SocketService: trip:milestone:updated - $data');
      }
      onTripMilestoneUpdated?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:completed', (data) {
      if (kDebugMode) {
        print('SocketService: trip:completed - $data');
      }
      onTripCompleted?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:pod:pending', (data) {
      if (kDebugMode) {
        print('SocketService: trip:pod:pending - $data');
      }
      onTripPodPending?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:pod:uploaded', (data) {
      if (kDebugMode) {
        print('SocketService: trip:pod:uploaded - $data');
      }
      onTripPodUploaded?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:auto-activated', (data) {
      if (kDebugMode) {
        print('SocketService: trip:auto-activated - $data');
      }
      onTripAutoActivated?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // POD events - backend emits trip:closed:with-pod when transporter approves POD
    _socket!.on('trip:closed:with-pod', (data) {
      if (kDebugMode) {
        print('SocketService: trip:closed:with-pod - $data');
      }
      onPODApproved?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });
    _socket!.on('pod:approved', (data) {
      if (kDebugMode) {
        print('SocketService: pod:approved - $data');
      }
      onPODApproved?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // Trip cancelled event
    _socket!.on('trip:cancelled', (data) {
      if (kDebugMode) {
        print('SocketService: trip:cancelled - $data');
      }
      onTripCancelled?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // Trip assignment events (driver assigned to trip)
    _socket!.on('trip:customer:assigned', (data) {
      if (kDebugMode) {
        print('SocketService: trip:customer:assigned - $data');
      }
      onTripCustomerAssigned?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:driver:assigned', (data) {
      if (kDebugMode) {
        print('SocketService: trip:driver:assigned - $data');
      }
      onTripDriverAssigned?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:vehicle:assigned', (data) {
      if (kDebugMode) {
        print('SocketService: trip:vehicle:assigned - $data');
      }
      onTripVehicleAssigned?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    _socket!.on('trip:closed:without-pod', (data) {
      if (kDebugMode) {
        print('SocketService: trip:closed:without-pod - $data');
      }
      onTripClosedWithoutPOD?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // Error event from server
    _socket!.on('error', (data) {
      if (kDebugMode) {
        print('SocketService: Server error event - $data');
      }
      final errorMessage = data is Map ? data['message']?.toString() : data.toString();
      onError?.call(errorMessage ?? 'Unknown socket error');
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(ApiConfig.socketHeartbeatInterval, (_) {
      if (_socketIoConnected) {
        _socket!.emit('ping');
        if (kDebugMode) {
          print('SocketService: Heartbeat ping sent');
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void joinDriverRoom(String driverId) {
    _driverId = driverId;
    if (_socketIoConnected) {
      _socket!.emit('join:driver', driverId);
      if (kDebugMode) {
        print('SocketService: Joined driver room: $driverId');
      }
    }
  }

  void joinVehicleRoom(String vehicleId) {
    _vehicleId = vehicleId;
    if (_socketIoConnected) {
      _socket!.emit('join:vehicle', vehicleId);
      if (kDebugMode) {
        print('SocketService: Joined vehicle room: $vehicleId');
      }
    }
  }

  void joinTripRoom(String tripId) {
    _tripId = tripId;
    if (_socketIoConnected) {
      _socket!.emit('join:trip', tripId);
      if (kDebugMode) {
        print('SocketService: Joined trip room: $tripId');
      }
    }
  }

  /// Emit trip start event
  void emitTripStart(String tripId) {
    if (_socketIoConnected) {
      _socket!.emit('trip:start', {'tripId': tripId});
      if (kDebugMode) {
        print('SocketService: Emitted trip:start for trip: $tripId');
      }
    } else {
      if (kDebugMode) {
        print('SocketService: Cannot emit trip:start - not connected');
      }
    }
  }

  /// Emit driver location update (for real-time tracking during active trip).
  ///
  /// When the socket is connected the fix is sent immediately (after first
  /// draining any buffered fixes to preserve order). Otherwise it is buffered
  /// and flushed in order on reconnect, so the transporter's trail has no gaps.
  void emitDriverLocationUpdate({
    required String tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) {
    final payload = <String, dynamic>{
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    if (accuracy != null && accuracy >= 0) payload['accuracy'] = accuracy;
    if (speed != null && speed >= 0) payload['speed'] = speed;
    if (heading != null && heading >= 0) payload['heading'] = heading;

    if (_socketIoConnected) {
      _flushLocationBuffer();
      _socket!.emit('driver:location:update', payload);
      if (kDebugMode) {
        print('SocketService: Emitted driver:location:update for trip: $tripId');
      }
      return;
    }

    _locationBuffer.addLast(payload);
    while (_locationBuffer.length > _maxBufferedLocations) {
      _locationBuffer.removeFirst();
    }

    if (_connectionState != SocketConnectionState.connecting) {
      connect();
    }

    if (kDebugMode) {
      print(
        'SocketService: Buffered driver location (${_locationBuffer.length} pending); will send on connect',
      );
    }
  }

  /// Emit a driver health/presence heartbeat so the transporter can tell when
  /// GPS is off, the device is offline, or the app is backgrounded. Sent on a
  /// fixed cadence independent of GPS movement.
  void emitDriverHealthHeartbeat({
    required String tripId,
    bool? gpsEnabled,
    bool? networkConnected,
    String? appState,
    int? batteryLevel,
  }) {
    if (!_socketIoConnected) {
      if (_connectionState != SocketConnectionState.connecting) {
        connect();
      }
      return;
    }
    final payload = <String, dynamic>{'tripId': tripId};
    if (gpsEnabled != null) payload['gpsEnabled'] = gpsEnabled;
    if (networkConnected != null) payload['networkConnected'] = networkConnected;
    if (appState != null) payload['appState'] = appState;
    if (batteryLevel != null) payload['batteryLevel'] = batteryLevel;
    _socket!.emit('driver:health:heartbeat', payload);
    if (kDebugMode) {
      print('SocketService: Emitted driver:health:heartbeat for trip: $tripId');
    }
  }

  /// Tell the server the driver is logging out so the transporter sees a
  /// `logged_out` tracking status immediately (rather than waiting for stale
  /// detection). Best-effort; safe to call when not connected.
  void emitDriverSessionLogout({String? tripId}) {
    if (!_socketIoConnected) return;
    _socket!.emit('driver:session:logout', {
      if (tripId != null) 'tripId': tripId,
    });
    if (kDebugMode) {
      print('SocketService: Emitted driver:session:logout');
    }
  }

  /// Emit milestone update event
  void emitMilestoneUpdate({
    required String tripId,
    required int milestoneNumber,
    required double latitude,
    required double longitude,
    String? photo,
    String? address,
  }) {
    if (_socketIoConnected) {
      _socket!.emit('trip:milestone:update', {
        'tripId': tripId,
        'milestoneNumber': milestoneNumber,
        'latitude': latitude,
        'longitude': longitude,
        if (photo != null) 'photo': photo,
        if (address != null) 'address': address,
      });
      if (kDebugMode) {
        print('SocketService: Emitted trip:milestone:update for trip: $tripId, milestone: $milestoneNumber');
      }
    } else {
      if (kDebugMode) {
        print('SocketService: Cannot emit milestone update - not connected');
      }
    }
  }

  /// Emit trip complete event
  void emitTripComplete(String tripId) {
    if (_socketIoConnected) {
      _socket!.emit('trip:complete', {'tripId': tripId});
      if (kDebugMode) {
        print('SocketService: Emitted trip:complete for trip: $tripId');
      }
    } else {
      if (kDebugMode) {
        print('SocketService: Cannot emit trip:complete - not connected');
      }
    }
  }

  void disconnect() {
    _stopHeartbeat();
    _driverId = null;
    _vehicleId = null;
    _tripId = null;

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setConnectionState(SocketConnectionState.disconnected);
    _locationBuffer.clear();

    if (kDebugMode) {
      print('SocketService: Disconnected');
    }
  }

  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }
}
