import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/utils/error_handler.dart';
import 'api_service.dart';

class DriverInboxNotification {
  DriverInboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  factory DriverInboxNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parsed;
    final raw = json['createdAt'];
    if (raw is String) {
      parsed = DateTime.tryParse(raw);
    }
    return DriverInboxNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: parsed ?? DateTime.now(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null),
    );
  }
}

class NotificationService {
  NotificationService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<int> fetchUnreadCount() async {
    try {
      final res = await _api.get(
        ApiConfig.notifications,
        queryParameters: {'page': 1, 'limit': 1},
      );
      if (res.data['success'] == true && res.data['data'] is Map) {
        final data = res.data['data'] as Map;
        final n = data['unreadCount'];
        if (n is int) return n;
        if (n is num) return n.toInt();
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'NotificationService: fetchUnreadCount');
    } catch (e, st) {
      ErrorHandler.logError(e, context: 'NotificationService: fetchUnreadCount');
      if (kDebugMode) {
        print(st);
      }
    }
    return 0;
  }

  Future<({List<DriverInboxNotification> items, int unreadCount})> fetchNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _api.get(
        ApiConfig.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      if (res.data['success'] == true && res.data['data'] is Map) {
        final data = res.data['data'] as Map;
        final list = data['notifications'];
        if (list is! List) {
          return (items: <DriverInboxNotification>[], unreadCount: 0);
        }
        final items = list
            .whereType<Map>()
            .map((e) => DriverInboxNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final n = data['unreadCount'];
        final unread = n is int ? n : (n is num ? n.toInt() : 0);
        return (items: items, unreadCount: unread);
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'NotificationService: fetchNotifications');
      rethrow;
    }
    return (items: <DriverInboxNotification>[], unreadCount: 0);
  }

  Future<bool> markRead(String id) async {
    try {
      final res = await _api.put(ApiConfig.notificationRead(id));
      return res.data['success'] == true;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'NotificationService: markRead');
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      final res = await _api.put(ApiConfig.notificationsReadAll);
      return res.data['success'] == true;
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'NotificationService: markAllRead');
      return false;
    }
  }
}
