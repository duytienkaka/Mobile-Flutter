import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class SettingsService {
  static Future<UserProfile> getProfile() async {
    final res = await ApiClient.get('/users/me', auth: true);
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }
    throw Exception('Không thể lấy thông tin hồ sơ.');
  }

  static Future<UserProfile> updateProfile({
    required String fullName,
  }) async {
    final res = await ApiClient.put(
      '/users/me',
      {'fullName': fullName},
      auth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }
    throw Exception('Cập nhật hồ sơ thất bại.');
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await ApiClient.put(
      '/users/me/password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      auth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
  }

  static Future<UserProfile> uploadAvatar(File file) async {
    final multipart = await http.MultipartFile.fromPath('avatar', file.path);
    final res = await ApiClient.multipart(
      '/users/me/avatar',
      files: [multipart],
      auth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res));
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }
    throw Exception('Cập nhật ảnh đại diện thất bại.');
  }

  static String? resolveAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${ApiClient.baseUrl}$url';
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
