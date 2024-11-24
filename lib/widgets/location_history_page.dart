import 'dart:math';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'device_map_view.dart';

class LocationHistoryPage extends StatelessWidget {
  final String deviceId;
  final String deviceName;
  final List<Map<String, dynamic>> locationHistory;

  LocationHistoryPage({
    required this.deviceId,
    required this.deviceName,
    required this.locationHistory,
  });
  double calculateDistance(int rssi, int measuredPower, double pathLossExponent) {
    return pow(10, (measuredPower - rssi) / (10 * pathLossExponent)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location History'),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              // Navigate to map view with location history
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceMapView(devices: locationHistory),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_active),
            onPressed: () {
              // Trigger audio playback
              _triggerAudioPlayback(context, deviceId);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: locationHistory.length,
        itemBuilder: (context, index) {
          final location = locationHistory[index];
          final rssi = location['rssi']?.toInt() ?? 0;
          final distance = calculateDistance(rssi, -59, 2.0);
          return ListTile(
            title: Text('Location ${index + 1}, $deviceName)'),
            subtitle: Text(
              'Estimated Distance: ${distance.toStringAsFixed(2)} meters\n'
                  'Timestamp: ${location['timestamp']}',

            ),
          );
        },
      ),
    );
  }

  void _triggerAudioPlayback(BuildContext context, String deviceId) async {
    try {
      // Assuming _apiService is available in your context
      final apiService = ApiService();
      await apiService.triggerAudioPlayback(deviceId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio playback triggered')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to trigger audio: $e')),
      );
    }
  }
}
