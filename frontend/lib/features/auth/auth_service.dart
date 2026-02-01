import 'dart:convert';
import '../../core/api/api_client.dart';

class AuthService {
  static Future<String?> loginEmail(String email, String password) async {
    final res = await ApiClient.post("/auth/login-email", {
      "email": email,
      "password": password,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["token"];
    }
    return null;
  }

  static Future<bool> sendOtp(String phone) async {
    final res = await ApiClient.post("/auth/send-otp", {"phoneNumber": phone});

    print("STATUS = ${res.statusCode}");
    print("BODY = ${res.body}");

    return res.statusCode == 200;
  }

  static Future<String?> verifyOtp(String phone, String code) async {
    final res = await ApiClient.post("/auth/verify-otp", {
      "phoneNumber": phone,
      "code": code,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["token"];
    }
    return null;
  }
}
