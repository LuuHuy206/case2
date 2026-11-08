import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  static Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(
      '/auth/register',
      {'fullName': fullName, 'email': email, 'password': password},
      auth: false,
    );
    final token = (res['token'] ?? '').toString();
    if (token.isNotEmpty) {
      await ApiClient.saveToken(token);
    }
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = (res['token'] ?? '').toString();
    if (token.isNotEmpty) {
      await ApiClient.saveToken(token);
    }
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  static Future<UserModel> getCurrentUser() async {
    final res = await ApiClient.get('/auth/me');
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  static Future<UserModel> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final res = await ApiClient.put('/auth/me', {
      'fullName': fullName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.put('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
