import 'package:flutter/material.dart';
import 'package:find_my_device/pages/SavedPacketsPage.dart';
import 'package:find_my_device/services/bluetooth_service.dart';
import 'package:find_my_device/services/location_service.dart';
import 'package:find_my_device/services/audio_service.dart';
import 'package:find_my_device/services/ApiService.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;

void main() {
  runApp(FindMyDeviceApp());
}

class FindMyDeviceApp extends StatefulWidget {
  @override
  _FindMyDeviceAppState createState() => _FindMyDeviceAppState();
}

class _FindMyDeviceAppState extends State<FindMyDeviceApp> {
  final BluetoothService _bluetoothService = BluetoothService();
  final LocationService _locationService = LocationService();
  final AudioService _audioService = AudioService();
  final ApiService _apiService = ApiService();

  List<flutter_blue.ScanResult> _nearbyDevices = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _bluetoothService.startPeriodicAdvertising();
    await _bluetoothService.startScanning();
    _bluetoothService.scanResults.listen((result) {
      setState(() {
        _nearbyDevices.add(result);
      });
      _uploadDeviceData(result);
    });
  }

  Future<void> _uploadDeviceData(flutter_blue.ScanResult result) async {
    final position = await _locationService.getCurrentLocation();
    final data = {
      'deviceId': result.device.remoteId.toString(),
      'rssi': result.rssi,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _apiService.uploadDeviceData(data);
  }

  Future<void> _triggerAudioPlayback(String deviceId) async {
    await _apiService.triggerAudioPlayback(deviceId);
  }

  Future<void> displaySavedPackets() async {
    final savedPackets = await _bluetoothService.getSavedPackets();
    savedPackets.forEach((packet) {
      print(
          'Device: ${packet['deviceId']} at ${packet['location']} at ${packet['timestamp']}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Find My Device')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _nearbyDevices.length,
                itemBuilder: (context, index) {
                  final device = _nearbyDevices[index].device;
                  return ListTile(
                    title: Text(device.platformName.isNotEmpty
                        ? device.platformName
                        : 'Unknown Device'),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: ElevatedButton(
                      onPressed: () =>
                          _triggerAudioPlayback(device.remoteId.toString()),
                      child: Text('Play Sound'),
                    ),
                  );
                },
              ),
            ),
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SavedPacketsPage(bluetoothService: _bluetoothService),
                    ),
                  );
                },
                child: Text('View Saved Packets'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}


















/*implementation provides a more complete structure for your Flutter app. Here's what each part does:

1. The `BluetoothService` now includes methods for starting and stopping scanning, and a stream for scan results.
2. The `LocationService` includes proper permission checks before accessing location.
3. The `AudioService` includes error handling and a method to stop audio playback.
4. The `ApiService` includes error handling for API calls.
5. The main app (`FindMyDeviceApp`) now initializes services, listens for nearby devices, uploads device data, and provides a UI to display nearby devices and trigger audio playback.

Remember to replace 'your_project_name' in the import statements with your actual project name.

This implementation still requires:
1. Proper error handling UI for permission denials and other errors.
2. A mechanism for user authentication.
3. Background service implementation for continuous scanning when the app is not in the foreground.
4. Potential optimizations for battery usage and data transfer.

You'll also need to implement the corresponding [Spring Boot](https://spring.io/projects/spring-boot) backend to handle the API calls for uploading device data and triggering audio playback.
</MESSAGE>
*/
/*

*/