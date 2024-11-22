import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class DeviceMapView extends StatefulWidget {
  final List<Map<String, dynamic>> devices;

  DeviceMapView({required this.devices});

  @override
  _DeviceMapViewState createState() => _DeviceMapViewState();
}

class _DeviceMapViewState extends State<DeviceMapView> {
  late GoogleMapController mapController;
  Map<MarkerId, Marker> markers = {};

  final LocationSmoother _smoother = LocationSmoother();
  final KalmanFilter _kalmanFilter = KalmanFilter();

  @override
  void initState() {
    super.initState();
    _createMarkers(widget.devices);
  }

  void _createMarkers(List<Map<String, dynamic>> devices) {

    devices.forEach((device) {
      final Id = device['id']?.toString() ?? 'unknown';
      final deviceId = device['device_id']?.toString() ?? 'unknown';
      final serialNumber = device['serial_number']?.toString() ?? 'unknown';
      final deviceName = device['device_name']?.toString() ?? 'Unknown Device';
      final rssi = device['rssi']?.toInt() ?? 0;
      final timestamp = device['timestamp']?.toString() ?? 'unknown';
      final latitude = device['latitude'] as double?;
      final longitude = device['longitude'] as double?;

      if (latitude != null && longitude != null) {
        final List<Map<String, dynamic>> history = [
          {
            'latitude': latitude,
            'longitude': longitude,
            'rssi': rssi,
            'timestamp': DateTime.now().toIso8601String(), // Add timestamp
          }
        ];

        // If there's existing history in the device data, add it
        if (device['history'] != null && device['history'] is List) {
          history.addAll(device['history'].cast<Map<String, dynamic>>());
        }

        // Apply smoothing to historical locations
        final smoothedLocation = _smoother.smoothLocations(history);
        final filteredRssi = _kalmanFilter.update(rssi.toDouble());

        // Calculate distance based on RSSI
        final distance = calculateDistance(filteredRssi.toInt(), -59, 2.0); // Example values for measuredPower and pathLossExponent

        markers[MarkerId(Id)] = Marker(
          markerId: MarkerId(Id),
          position: LatLng(smoothedLocation.latitude, smoothedLocation.longitude),
          infoWindow: InfoWindow(title: '$deviceName ($distance m)'),

        );
      print(distance);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.devices.isNotEmpty
            ? LatLng(widget.devices.first['latitude'], widget.devices.first['longitude'])
            : LatLng(0, 0),
        zoom: 12,
      ),
      markers: Set<Marker>.of(markers.values),
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
      },
    );
  }

  double calculateDistance(int rssi, int measuredPower, double pathLossExponent) {
    return pow(10, (measuredPower - rssi) / (10 * pathLossExponent)).toDouble();
  }
}

class LocationSmoother {
  Position smoothLocations(List<Map<String, dynamic>> readings) {
    print(readings);
    if (readings.isEmpty) {
      return Position(latitude: 0.0, longitude: 0.0);
    }
    final weights = List.generate(readings.length,
            (i) => 1.0 / pow(2, readings.length - i - 1));

    double weightedLat = 0.0;
    double weightedLng = 0.0;
    double totalWeight = weights.reduce((a, b) => a + b);

    for (int i = 0; i < readings.length; i++) {
      weightedLat += readings[i]['latitude'] * weights[i];
      weightedLng += readings[i]['longitude'] * weights[i];
    }

    return Position(
        latitude: weightedLat / totalWeight,
        longitude: weightedLng / totalWeight
    );
  }
}

class KalmanFilter {
  double _estimate = 0.0;
  double _errorEstimate = 1.0;
  double _q = 0.1; // Process noise
  double _r = 0.1; // Measurement noise

  double update(double measurement) {
    double errorPrediction = _errorEstimate + _q;
    double kalmanGain = errorPrediction / (errorPrediction + _r);
    _estimate += kalmanGain * (measurement - _estimate);
    _errorEstimate = (1 - kalmanGain) * errorPrediction;
    return _estimate;
  }
}

class Position {
  final double latitude;
  final double longitude;

  Position({required this.latitude, required this.longitude});
}
