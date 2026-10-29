import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  NotificationService get service => _service;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _lastKnownCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    fetchNotifications();
  }

  Future<void> fetchNotifications({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getNotifications(page: page, limit: limit);

    if (response.success && response.data != null) {
      final newUnread = response.data!.where((n) => !n.isRead).length;
      if (newUnread > 0 && response.data!.length > _lastKnownCount && _lastKnownCount > 0) {
        // Play notification alert sound & vibration
        try {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.heavyImpact();
        } catch (_) {}
      }
      _notifications = response.data!;
      _lastKnownCount = _notifications.length;
      _errorMessage = null;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load notifications.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
    await _service.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _service.markAllAsRead();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _lastKnownCount = _notifications.length;
    notifyListeners();
    await _service.deleteNotification(id);
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _lastKnownCount = 0;
    notifyListeners();
    await _service.clearAllNotifications();
  }
}
