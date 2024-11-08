import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://your-api-url.com';

  Future<void> uploadDeviceData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/device-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Data uploaded successfully');
      } else {
        throw Exception('Failed to upload data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading device data: $e');
    }
  }

  Future<void> triggerAudioPlayback(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trigger-audio/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Audio playback triggered');
      } else {
        throw Exception('Failed to trigger audio playback: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering audio playback: $e');
    }
  }
}
