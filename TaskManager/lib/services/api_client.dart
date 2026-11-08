import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiClient {
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer \$token';
      }
    }
    return headers;
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {
        body = {'message': response.body};
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['message'] ?? 'Lỗi kết nối máy chủ (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}\$path')
        .replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers());
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data, {bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}\$path');
    final res = await http.post(uri, headers: await _headers(auth: auth), body: jsonEncode(data));
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}\$path');
    final res = await http.put(uri, headers: await _headers(), body: jsonEncode(data));
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}\$path');
    final res = await http.patch(uri, headers: await _headers(), body: jsonEncode(data));
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}\$path');
    final res = await http.delete(uri, headers: await _headers());
    return _decodeResponse(res);
  }
}
