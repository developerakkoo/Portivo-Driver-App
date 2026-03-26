import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  NotificationProvider({NotificationService? service}) : _service = service ?? NotificationService();

  final NotificationService _service;

  int _unreadCount = 0;
  List<DriverInboxNotification> _items = [];
  bool _isLoading = false;
  String? _error;

  int get unreadCount => _unreadCount;
  List<DriverInboxNotification> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _service.fetchUnreadCount();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('NotificationProvider: refreshUnreadCount $e');
      }
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.fetchNotifications();
      _items = result.items;
      _unreadCount = result.unreadCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final ok = await _service.markRead(id);
    if (ok) {
      _items = _items.map((n) {
        if (n.id == id) {
          return DriverInboxNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            read: true,
            createdAt: n.createdAt,
            data: n.data,
          );
        }
        return n;
      }).toList();
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final ok = await _service.markAllRead();
    if (ok) {
      _items = _items
          .map(
            (n) => DriverInboxNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              read: true,
              createdAt: n.createdAt,
              data: n.data,
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// Refresh unread count from API (call after login / home). Push notifications are not used; inbox uses GET /notifications.
  Future<void> syncUnreadBadge() async {
    await refreshUnreadCount();
  }
}
