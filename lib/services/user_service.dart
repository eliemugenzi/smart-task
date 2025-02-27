// services/user_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttask/utils/constants.dart';

class UserService {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.get(
        '${Constants.baseUrl}/auth/users',
        options: Options(
          headers: {'Authorization': 'Bearer $token'}, // Assuming Bearer token auth
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data["data"]);
      } else {
        throw Exception('Failed to fetch users: ${response.data['message'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception('Failed to fetch users: ${errorData['message'] ?? 'Server error: ${e.response!.statusMessage}'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}