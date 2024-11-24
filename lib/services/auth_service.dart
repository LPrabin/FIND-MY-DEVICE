// lib/services/auth_service.dart

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final String baseUrl = 'https://your-api-url.com/api';
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_KEY = 'user_data';

  // Registration with device information
  Future<Map<String, dynamic>> registerDevice({
    required String username,
    required String password,
    required String deviceName,
    required String bluetoothId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'device_name': deviceName,
          'bluetooth_identifier': bluetoothId,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        await _saveAuthData(responseData['token'], responseData['user']);
        return {
          'success': true,
          'data': responseData,
        };
      }

      return {
        'success': false,
        'error': 'Registration failed: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Registration error: $e',
      };
    }
  }

  // Login with credentials
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await _saveAuthData(responseData['token'], responseData['user']);
        return {
          'success': true,
          'data': responseData,
        };
      }

      return {
        'success': false,
        'error': 'Login failed: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Login error: $e',
      };
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    await prefs.setString(USER_KEY, jsonEncode(userData));
  }

  // Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  // Get saved user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(USER_KEY);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(USER_KEY);
  }

  // Get auth headers for API requests
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
