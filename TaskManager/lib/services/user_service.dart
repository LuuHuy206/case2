import '../models/user.dart';
import 'api_client.dart';

class UserService {
  static Future<List<UserModel>> searchUsers(String query) async {
    final res = await ApiClient.get('/users/search', queryParams: {'q': query});
    final list = res['users'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  static Future<UserModel> getUserById(String id) async {
    final res = await ApiClient.get('/users/\$id');
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }
}
