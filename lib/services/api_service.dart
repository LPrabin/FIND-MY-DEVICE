import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

class ApiService {
  final String baseUrl = 'http://192.168.1.164:8000/api';
  static const String AUTH_TOKEN_KEY = 'auth_token';

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AUTH_TOKEN_KEY);
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,

  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,

        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AUTH_TOKEN_KEY, data['token']);
        return {'success': true, 'data': data};
      }
      final errorData = jsonDecode(response.body);  // Django returns error details
      return {'success': false, 'error': errorData['detail'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'error': 'Registration error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),  // Django convention
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AUTH_TOKEN_KEY, data['token']);
        return {'success': true, 'data': data};
      }
      final errorData = jsonDecode(response.body);
      return {'success': false, 'error': errorData['detail'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Login error: $e'};
    }
  }





  Future<bool> triggerAudioPlayback(String deviceId) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/devices/$deviceId/trigger-audio/'),  // Django REST convention
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error triggering audio playback: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDeviceLocations(String deviceId, String deviceName) async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId/$deviceName/locations/'),  // Django REST convention
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          // Cast the data array to List<Map<String, dynamic>>
          final List<dynamic> locationsList = responseBody['data'];
          return locationsList.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Failed to get locations: ${responseBody['message']}');
        }

      } else {
        throw Exception('Failed to load device locations: ${response.statusCode}');
      }

    } catch (e) {
      print('Error getting device locations: $e');
      return [];
    }
  }



  Future<bool> uploadDeviceData(Map<String, dynamic> data) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper();
      final List<Map<String, dynamic>> pendingData = await dbHelper.getPendingDeviceData();

      if (pendingData.isEmpty) {
        print('No pending data to upload.');
        return true;
      }

      final String? token = await  _getAuthToken();
      bool allSuccess = true;

      for (var deviceData in pendingData) {
        try {
          // Validate required fields
          if (deviceData['device_id'] == null) {
            print('Skipping invalid data: $deviceData');
            allSuccess = false;
            continue;
          }

          final response = await http.post(
            Uri.parse('$baseUrl/auth/devices/data/'),
            headers: _getHeaders(token),
            body: jsonEncode({
              'serialNumber': deviceData['serialNumber'],
              'device_id': deviceData['device_id']?.toString() ?? '',
              'device_name': (deviceData['device_name']?.toString().isEmpty ?? true) ? 'Unknown' : deviceData['device_name'],
              'rssi': deviceData['rssi']?.toInt() ?? 0,
              'timestamp': deviceData['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
              'latitude': deviceData['latitude']?.toDouble() ?? 0.0,
              'longitude': deviceData['longitude']?.toDouble() ?? 0.0,
            }),
          );

          if (response.statusCode == 201) {
            await dbHelper.markDataAsSynced(deviceData['serialNumber']);
            print('Data uploaded and marked as synced: ${deviceData['serialNumber']}');
          } else {
            allSuccess = false;
            print('Failed to upload device data: ${response.statusCode}');
          }
        } catch (innerError) {
          allSuccess = false;
          print('Error while processing data: $deviceData\nError: $innerError');
        }
      }
      return allSuccess;
    } catch (e) {
      print('Error uploading device data: $e');
      return false;
    }
  }






  Future<List<Map<String, dynamic>>> getDevices() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AUTH_TOKEN_KEY);

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/devices/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error getting devices: $e');
  }
}
  Future<bool> addDevice(String displayName, String deviceId, String deviceName) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/devices/add/'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'device_id': deviceId,
          'device_name': deviceName,
          'display_name': displayName
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error adding device: $e');
      return false;
    }
  }



}