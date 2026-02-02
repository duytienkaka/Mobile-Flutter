import 'dart:convert';
import '../../core/api/api_client.dart';

class AuthService {
  // ĐĂNG NHẬP EMAIL/PASSWORD
  static Future<Map<String, dynamic>> loginEmail(
      String email, String password) async {
    try {
      final res = await ApiClient.post("/auth/login-email", {
        "email": email,
        "password": password,
      });

      print("LOGIN STATUS: ${res.statusCode}");
      print("LOGIN RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "token": data["token"]};
      } else {
        // Try to parse error as JSON, fallback to plain text
        try {
          final error = jsonDecode(res.body);
          return {"success": false, "message": error["message"] ?? error.toString()};
        } catch (_) {
          return {"success": false, "message": res.body};
        }
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      return {"success": false, "message": "Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không."};
    }
  }

  // ĐĂNG KÝ EMAIL
  static Future<Map<String, dynamic>> registerEmail(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final res = await ApiClient.post("/auth/register-email", {
        "fullName": fullName,
        "email": email,
        "password": password,
      });

      print("REGISTER STATUS: ${res.statusCode}");
      print("REGISTER RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "token": data["token"]};
      } else {
        try {
          final error = jsonDecode(res.body);
          return {"success": false, "message": error["message"] ?? error.toString()};
        } catch (_) {
          return {"success": false, "message": res.body};
        }
      }
    } catch (e) {
      print("REGISTER ERROR: $e");
      return {"success": false, "message": "Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không."};
    }
  }

  // ĐĂNG KÝ SỐ ĐIỆN THOẠI (GỬI OTP)
  static Future<Map<String, dynamic>> registerPhone(
      String fullName, String phone) async {
    try {
      final res = await ApiClient.post("/auth/register-phone", {
        "fullName": fullName,
        "phoneNumber": phone,
      });

      print("REGISTER PHONE STATUS: ${res.statusCode}");
      print("REGISTER PHONE RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        return {"success": true};
      } else {
        try {
          final error = jsonDecode(res.body);
          return {"success": false, "message": error["message"] ?? "Không thể gửi OTP"};
        } catch (_) {
          return {"success": false, "message": res.body};
        }
      }
    } catch (e) {
      print("REGISTER PHONE ERROR: $e");
      return {"success": false, "message": "Không thể kết nối đến server"};
    }
  }

  // GỬI OTP (CHO ĐĂNG NHẬP)
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res =
          await ApiClient.post("/auth/send-otp", {"phoneNumber": phone});

      if (res.statusCode == 200) {
        return {"success": true};
      }

      try {
        final err = jsonDecode(res.body);
        return {"success": false, "message": err["message"] ?? res.body};
      } catch (_) {
        return {"success": false, "message": res.body};
      }
    } catch (e) {
      return {"success": false, "message": "Không thể kết nối server"};
    }
  }

  // XÁC THỰC OTP
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String code) async {
    try {
      final res = await ApiClient.post("/auth/verify-otp", {
        "phoneNumber": phone,
        "code": code,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "token": data["token"]};
      } else {
        try {
          final err = jsonDecode(res.body);
          return {"success": false, "message": err["message"] ?? "OTP không hợp lệ"};
        } catch (_) {
          return {"success": false, "message": res.body};
        }
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }
}
