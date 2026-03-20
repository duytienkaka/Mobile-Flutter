import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';

enum NotificationCategory { food, pantry, planner, system }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String group;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.group,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      group: (json['group'] ?? json['type'] ?? 'system').toString(),
    );
  }
}

NotificationCategory detectNotificationCategory(NotificationItem item) {
  final group = item.group.toLowerCase();
  final text = '${item.title} ${item.body}'.toLowerCase();

  const plannerGroups = {'planner', 'meal_plan', 'schedule'};
  if (plannerGroups.contains(group)) return NotificationCategory.planner;

  final isPlannerText = text.contains('kế hoạch') ||
      text.contains('planner') ||
      text.contains('bữa ăn') ||
      text.contains('thực đơn');
  if (isPlannerText) return NotificationCategory.planner;

  const pantryGroups = {'added', 'pantry'};
  if (pantryGroups.contains(group)) return NotificationCategory.pantry;
  if (text.contains('tủ đồ')) return NotificationCategory.pantry;

  const foodGroups = {'expired', 'near_expiry'};
  if (foodGroups.contains(group)) return NotificationCategory.food;

  final isFoodText = text.contains('hết hạn') ||
      text.contains('thực phẩm') ||
      text.contains('nguyên liệu');
  if (isFoodText) return NotificationCategory.food;

  return NotificationCategory.system;
}

class NotificationService {
  static Future<List<NotificationItem>> fetchNotifications() async {
    final res = await ApiClient.get('/api/notifications', auth: true);
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid response from server.');
  }

  static Future<void> markAsRead(String id) async {
    final res = await ApiClient.put(
      '/api/notifications/$id/read',
      {},
      auth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
  }

  static Future<void> deleteNotification(String id) async {
    final res = await ApiClient.delete('/api/notifications/$id', auth: true);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_extractError(res));
    }
  }

  static Future<int> clearAllNotifications() async {
    final res = await ApiClient.delete('/api/notifications', auth: true);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_extractError(res));
    }
    if (res.body.isEmpty) return 0;
    final data = jsonDecode(res.body);
    if (data is Map && data['deletedCount'] is num) {
      return (data['deletedCount'] as num).toInt();
    }
    return 0;
  }

  static Future<int> unreadCount() async {
    final res = await ApiClient.get('/api/notifications/unread-count', auth: true);
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
    final data = jsonDecode(res.body);
    if (data is int) return data;
    if (data is String) return int.tryParse(data) ?? 0;
    if (data is Map && data['count'] is num) {
      return (data['count'] as num).toInt();
    }
    return 0;
  }

  static String _extractError(dynamic res) {
    try {
      if (res.statusCode == 401) {
        return 'Vui lòng đăng nhập lại.';
      }
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) {
        final message = (data['message'] as String).trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}
    switch (res.statusCode) {
      case 400:
        return 'Dữ liệu không hợp lệ.';
      case 404:
        return 'Không tìm thấy dữ liệu.';
      default:
        return 'Không thể xử lý yêu cầu.';
    }
  }
}

class NotificationBadgeService extends ChangeNotifier {
  static final NotificationBadgeService instance = NotificationBadgeService._();

  NotificationBadgeService._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _started = false;
  bool _refreshing = false;

  void ensureStarted() {
    if (_started) return;
    _started = true;
    refresh();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final count = await NotificationService.unreadCount();
      setUnreadCount(count);
    } catch (_) {
      
    } finally {
      _refreshing = false;
    }
  }

  void setUnreadCount(int count) {
    final normalized = count < 0 ? 0 : count;
    if (_unreadCount == normalized) return;
    _unreadCount = normalized;
    notifyListeners();
  }
}
