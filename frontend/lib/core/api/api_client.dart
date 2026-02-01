import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const baseUrl = "http://localhost:5178";

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) {
    return http.post(
      Uri.parse("$baseUrl$path"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }
}
