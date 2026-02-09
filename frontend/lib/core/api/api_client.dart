import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiClient {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5074';
    }
    return 'http://localhost:5074';
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await TokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);

    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(
    String path, {
    bool auth = false,
    Map<String, String>? queryParameters,
  }) async {
    final headers = await _headers(auth: auth);
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(
    String path, {
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
  }

  static Future<http.Response> multipart(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    bool auth = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    );
    if (auth) {
      final token = await TokenStorage.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.addAll(files);
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
}
