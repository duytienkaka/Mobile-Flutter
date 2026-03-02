import 'dart:convert';
import '../../core/api/api_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
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
    );
  }
}

class NotificationService {
  static Future<List<NotificationItem>> fetchNotifications() async {
    final res = await ApiClient.get('/notifications', auth: true);
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
    final res = await ApiClient.post(
      '/notifications/read/$id',
      null,
      auth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
  }

  static Future<int> unreadCount() async {
    final res = await ApiClient.get('/notifications/unread-count', auth: true);
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
    final data = jsonDecode(res.body);
    if (data is int) return data;
    if (data is String) return int.tryParse(data) ?? 0;
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
