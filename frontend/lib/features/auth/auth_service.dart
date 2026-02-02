import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'dart:convert';

class AuthService {
  static String _extractMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      final message = data is Map ? data['message'] : null;
      if (message is String && message.trim().isNotEmpty) return message;
    } catch (_) {}
    return fallback;
  }

  static Future<void> loginEmail(String email, String password) async {
    final res = await ApiClient.post(
      '/auth/login-email',
      {
        'email': email,
        'password': password,
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
          _extractMessage(res.body, 'Email hoặc mật khẩu chưa đúng.'));
    }

    final token = jsonDecode(res.body)['token'];
    await TokenStorage.saveToken(token);
  }

  static Future<void> registerEmail(
      String fullName, String email, String password) async {
    final res = await ApiClient.post(
      '/auth/register-email',
      {
        'fullName': fullName,
        'email': email,
        'password': password,
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
          _extractMessage(res.body, 'Đăng ký không thành công.'));
    }

    final token = jsonDecode(res.body)['token'];
    await TokenStorage.saveToken(token);
  }

  static Future<void> sendOtp(String phone) async {
    throw Exception('Use sendOtpForLogin or sendOtpForRegister');
  }

  static Future<void> sendOtpForRegister(String phone) async {
    final res = await ApiClient.post(
      '/auth/send-otp',
      {'phoneNumber': phone, 'isRegister': true},
    );
    if (res.statusCode != 200) {
      throw Exception(
          _extractMessage(res.body, 'Không thể gửi OTP. Vui lòng thử lại.'));
    }
  }

  static Future<void> sendOtpForLogin(String phone) async {
    final res = await ApiClient.post(
      '/auth/send-otp',
      {'phoneNumber': phone, 'isRegister': false},
    );
    if (res.statusCode != 200) {
      throw Exception(
          _extractMessage(res.body, 'Không thể gửi OTP. Vui lòng thử lại.'));
    }
  }

  static Future<void> registerPhone(
      String fullName, String phone, String otp) async {
    final res = await ApiClient.post(
      '/auth/register-phone',
      {
        'fullName': fullName,
        'phoneNumber': phone,
        'otpCode': otp,
      },
    );

    if (res.statusCode != 200) {
      throw Exception(_extractMessage(
          res.body, 'Đăng ký số điện thoại không thành công.'));
    }

    final token = jsonDecode(res.body)['token'];
    await TokenStorage.saveToken(token);
  }

  static Future<void> loginPhone(String phone, String otp) async {
    final res = await ApiClient.post(
      '/auth/login-phone',
      {
        'phoneNumber': phone,
        'otpCode': otp,
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
          _extractMessage(res.body, 'OTP không đúng hoặc đã hết hạn.'));
    }

    final token = jsonDecode(res.body)['token'];
    await TokenStorage.saveToken(token);
  }
}
