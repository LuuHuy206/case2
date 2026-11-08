import 'api_client.dart';

class ApiService {
  static Future<String?> getToken() => ApiClient.getToken();
  static Future<void> saveToken(String token) => ApiClient.saveToken(token);
  static Future<void> clearToken() => ApiClient.clearToken();
}
