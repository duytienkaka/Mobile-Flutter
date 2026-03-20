import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/api/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _pushLog('BACKGROUND_MESSAGE_ID=${message.messageId}');
}

void _pushLog(String message) {
  debugPrint('[FCM] $message');
  log('[FCM] $message');
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _pushLog('PERMISSION=${settings.authorizationStatus.name}');

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _pushLog('FCM_TOKEN=$token');
      await _syncTokenToBackend(token);
    } else {
      _pushLog('FCM_TOKEN=null');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _pushLog('FCM_TOKEN_REFRESH=$newToken');
      _syncTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen((message) {
      _pushLog('FOREGROUND_TITLE=${message.notification?.title}');
      _pushLog('FOREGROUND_BODY=${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _pushLog('OPENED_APP_DATA=${message.data}');
    });
  }

  Future<void> _syncTokenToBackend(String token) async {
    final timezone = DateTime.now().timeZoneName;
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

    try {
      final res = await ApiClient.post(
        '/api/notifications/device-token',
        {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'unknown',
          'timeZoneId': timezone,
          'utcOffsetMinutes': offsetMinutes,
        },
        auth: true,
      );

      if (res.statusCode == 200) {
        _pushLog('SYNC_OK');
      } else if (res.statusCode == 401) {
        _pushLog('SYNC_SKIPPED_UNAUTHORIZED');
      } else {
        _pushLog('SYNC_FAILED_STATUS=${res.statusCode}');
      }
    } catch (e) {
      _pushLog('SYNC_ERROR=$e');
    }
  }
}
