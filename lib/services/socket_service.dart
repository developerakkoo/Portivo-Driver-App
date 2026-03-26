import 'dart:async';
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
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  String? _driverId;
  String? _vehicleId;
  String? _tripId;

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
  Function(SocketConnectionState)? onConnectionStateChanged;
  Function(String)? onError;

  bool get isConnected => _connectionState == SocketConnectionState.connected;
  SocketConnectionState get connectionState => _connectionState;

  Future<void> connect() async {
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
      if (kDebugMode) {
        print('SocketService: Already connected');
      }
      return;
    }

    if (_connectionState == SocketConnectionState.connecting) {
      if (kDebugMode) {
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

      // Disconnect existing socket if any
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      // Extract base URL from ApiConfig
      final baseUrl = ApiConfig.socketUrl;
      
      if (kDebugMode) {
        print('SocketService: Connecting to $baseUrl');
      }

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .setTimeout(ApiConfig.socketConnectionTimeout.inMilliseconds)
            .build(),
      );

      _setupEventListeners();
      _reconnectAttempts = 0;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('SocketService: Connection error: $e');
        print('Stack: $stackTrace');
      }
      _setConnectionState(SocketConnectionState.error);
      _scheduleReconnect();
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

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _setConnectionState(SocketConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      // Rejoin rooms if we have IDs
      if (_driverId != null) {
        joinDriverRoom(_driverId!);
      }
      if (_vehicleId != null) {
        joinVehicleRoom(_vehicleId!);
      }
      if (_tripId != null) {
        joinTripRoom(_tripId!);
      }
      
      if (kDebugMode) {
        print('SocketService: Connected successfully');
      }
    });

    _socket!.onDisconnect((reason) {
      _setConnectionState(SocketConnectionState.disconnected);
      _stopHeartbeat();
      
      if (kDebugMode) {
        print('SocketService: Disconnected - $reason');
      }
      
      // Schedule reconnect if not intentional disconnect
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _setConnectionState(SocketConnectionState.error);
      _stopHeartbeat();
      
      if (kDebugMode) {
        print('SocketService: Connection error: $error');
      }
      
      onError?.call(error.toString());
      _scheduleReconnect();
    });

    _socket!.onError((error) {
      if (kDebugMode) {
        print('SocketService: Error: $error');
      }
      onError?.call(error.toString());
    });

    // Trip events
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

  void _scheduleReconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
    }

    if (_reconnectAttempts >= ApiConfig.socketMaxReconnectAttempts) {
      if (kDebugMode) {
        print('SocketService: Max reconnect attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      milliseconds: (ApiConfig.socketReconnectDelay.inMilliseconds * 
                    (_reconnectAttempts * ApiConfig.retryBackoffMultiplier)).round(),
    );

    if (kDebugMode) {
      print('SocketService: Scheduling reconnect in ${delay.inMilliseconds}ms (attempt $_reconnectAttempts/${ApiConfig.socketMaxReconnectAttempts})');
    }

    _reconnectTimer = Timer(delay, () {
      if (_connectionState != SocketConnectionState.connected) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(ApiConfig.socketHeartbeatInterval, (_) {
      if (_socket != null && _connectionState == SocketConnectionState.connected) {
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
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
      _socket!.emit('join:driver', driverId);
      if (kDebugMode) {
        print('SocketService: Joined driver room: $driverId');
      }
    }
  }

  void joinVehicleRoom(String vehicleId) {
    _vehicleId = vehicleId;
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
      _socket!.emit('join:vehicle', vehicleId);
      if (kDebugMode) {
        print('SocketService: Joined vehicle room: $vehicleId');
      }
    }
  }

  void joinTripRoom(String tripId) {
    _tripId = tripId;
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
      _socket!.emit('join:trip', tripId);
      if (kDebugMode) {
        print('SocketService: Joined trip room: $tripId');
      }
    }
  }

  /// Emit trip start event
  void emitTripStart(String tripId) {
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
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

  /// Emit driver location update (for real-time tracking during active trip)
  void emitDriverLocationUpdate({
    required String tripId,
    required double latitude,
    required double longitude,
  }) {
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
      _socket!.emit('driver:location:update', {
        'tripId': tripId,
        'latitude': latitude,
        'longitude': longitude,
      });
      if (kDebugMode) {
        print('SocketService: Emitted driver:location:update for trip: $tripId');
      }
    } else {
      if (kDebugMode) {
        print('SocketService: Cannot emit driver location - not connected');
      }
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
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
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
    if (_socket != null && _connectionState == SocketConnectionState.connected) {
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
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    _reconnectAttempts = 0;
    _driverId = null;
    _vehicleId = null;
    _tripId = null;

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setConnectionState(SocketConnectionState.disconnected);

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
