// services/auth_service.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttask/utils/constants.dart';

class AuthService {
  final Dio _dio = Dio();

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${Constants.baseUrl}/auth/signup',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 201) { // Assuming 201 Created for successful signup
        final prefs = await SharedPreferences.getInstance();
        final responseData = response.data;
           await prefs.setString('token', responseData['data']['access_token'] ?? ''); // Store token if provided
        await prefs.setString('user', jsonEncode(responseData['data']['user'])); // Store user data for reference
      } else {
        throw Exception('Signup failed: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${Constants.baseUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) { // Assuming 200 OK for successful login
        final prefs = await SharedPreferences.getInstance();
        final responseData = response.data;
        await prefs.setString('token', responseData['data']['access_token'] ?? ''); // Store token if provided
        await prefs.setString('user', jsonEncode(responseData['data']['user'])); // Store user data for reference
      } else {
        throw Exception('Login failed: ${response.data['message'] ?? 'Invalid credentials'}');
      }
    } on DioException catch (e) {
      if (e.response!= null) {
        final errorData = e.response!.data;
                print('Login failed: ${errorData}');

        throw Exception('Login failed: ${errorData['message'] ?? 'Server error: ${e.response!.statusMessage}'}');
      } else {
      throw Exception('Network error: ${e.message}');

      }
    }
    catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}