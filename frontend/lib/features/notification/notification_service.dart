import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_core/signalr_core.dart';

typedef HubUrlProvider = String Function();

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _items = [
    NotificationItem(
      id: '1',
      title: 'Nguyên liệu sắp hết: Gà',
      body: 'Gà của bạn sẽ hết trong 2 ngày. Hãy thêm vào danh sách mua.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationItem(
      id: '2',
      title: 'Có nguyên liệu cần mua cho kế hoạch',
      body: 'Bạn có nguyên liệu chưa có cho kế hoạch bữa tối.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];

  List<NotificationItem> get items => List.unmodifiable(_items);

  // Optional global messenger key to show in-app SnackBar on incoming notification.
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  // SignalR
  HubConnection? _hubConnection;

  /// Provide a function that returns hub url. Defaults to localhost:5074.
  void startRealtime({HubUrlProvider? hubUrlProvider}) async {
    final hubUrl =
        hubUrlProvider?.call() ?? 'http://localhost:5074/hubs/notifications';
    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _hubConnection!.onclose((error) {
        // noop for now
      });

      _hubConnection!.on('ReceiveNotification', (arguments) {
        if (arguments == null || arguments.isEmpty) return;
        final payload = arguments[0] as Map<String, dynamic>;
        final item = NotificationItem(
          id:
              payload['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: payload['title']?.toString() ?? 'Thông báo mới',
          body: payload['body']?.toString() ?? '',
          createdAt:
              DateTime.tryParse(payload['createdAt']?.toString() ?? '') ??
              DateTime.now(),
        );
        add(item);
        // show a quick SnackBar if messenger is available
        try {
          scaffoldMessengerKey?.currentState?.showSnackBar(
            SnackBar(
              content: Text(item.title),
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (_) {}
      });

      await _hubConnection!.start();
    } catch (_) {
      // ignore connection errors; will retry via automatic reconnect
    }
  }

  /// Send a test notification via backend endpoint. Returns true on success.
  Future<bool> sendTestToServer({
    String? title,
    String? body,
    String? baseUrl,
  }) async {
    final base = baseUrl ?? 'http://localhost:5074';
    final uri = Uri.parse('$base/api/notifications/send-test');
    final payload = jsonEncode({
      'title': title ?? 'Thông báo thử',
      'body': body ?? 'Nội dung thử',
    });
    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void markAsRead(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final it = _items[idx];
      if (!it.read) {
        it.read = true;
        notifyListeners();
      }
    }
  }

  void markAllRead() {
    bool changed = false;
    for (var it in _items) {
      if (!it.read) {
        it.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void add(NotificationItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
