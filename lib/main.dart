import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:find_my_device/widgets/location_history_page.dart';
import 'package:find_my_device/widgets/login_widget.dart';
import 'package:find_my_device/widgets/registration_widget.dart';
import 'package:flutter/material.dart';
import 'package:find_my_device/services/bluetooth_service.dart';
import 'package:find_my_device/services/location_service.dart';
import 'package:find_my_device/services/audio_service.dart';
import 'package:find_my_device/services/api_service.dart';
import 'package:find_my_device/widgets/device_map_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';

void main() {
  runApp(FindMyDeviceApp());
}

class FindMyDeviceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find My Device',
      initialRoute: '/',
      routes: {
        '/': (context) => AuthenticationWrapper(),
        '/login': (context) => LoginWidget(),
        '/register': (context) => RegistrationWidget(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthentication(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return HomeScreen();
        }

        return LoginWidget();
      },
    );
  }

  Future<bool> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }
}



class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final LocationService _locationService = LocationService();
  final AudioService _audioService = AudioService();
  final ApiService _apiService = ApiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();


  String? deviceId;
  String? deviceName;
  bool _isLoading = true;
  bool _isMapView = false;
  List<Map<String, dynamic>> _savedDevices = [];
  Timer? _uploadTimer;
  @override
  void initState() {
    super.initState();
    _initializeServices();

  }

  Future<void> _initializeServices() async {
    try {
      await _bluetoothService.startPeriodicScanning();
      await _bluetoothService.startPeriodicAdvertising();

      await _loadSavedDevices();

      Timer.periodic(const Duration(seconds: 10), (_) async {
        final position = await _locationService.getCurrentLocation();
        final savedDevices = await _databaseHelper.getPendingDeviceData();

        for (var device in savedDevices) {
          await _apiService.uploadDeviceData({
            'device_id': device['device_id'],
            'rssi': device['rssi'],
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'service_uuids': device['service_uuids'],
            'manufacturer_data': device['manufacturer_data'],
            'device_name': device['device_name']
          });
        }
      });

      // Store scan results in database instead of direct upload
      _bluetoothService.scanResults.listen((result) async {

      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing services: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _loadSavedDevices() async {
    try {
      final devices = await _apiService.getDevices(); // Implement this method in ApiService
      setState(() {
        _savedDevices = devices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading devices: $e')),
      );
    }
  }



  Future<void> _logout() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiService.AUTH_TOKEN_KEY); // Remove auth token

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }




      @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find My Device'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),

          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),


        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isMapView
          ? DeviceMapView(devices: _savedDevices)
          : ListView.builder(
        itemCount: _savedDevices.length,
        itemBuilder: (context, index) {
        final device = _savedDevices[index];
        if (device['device_name'] != null && device['device_name'].toString().isNotEmpty) {
          return ListTile(
            title: Text(device['device_name']),
            subtitle: Text(
                'Last seen: ${device['timestamp']}\nRSSI: ${device['rssi']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active),
                  onPressed: () => _triggerAudioPlayback(device['device_id']),
                ),
                IconButton(
                  icon: const Icon(Icons.location_history),
                  onPressed: () =>
                      _showDeviceLocationHistory(
                          device['device_id'], device['device_name']),
                ),
              ],
            ),
          );
        }
        return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSavedDevices,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Devices',
      ),
    );
  }




  Future<void> _triggerAudioPlayback(String deviceId) async {
    try {
      await _apiService.triggerAudioPlayback(deviceId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio playback triggered')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to trigger audio: $e')),
      );
    }
  }
  Future<void> _showDeviceLocationHistory(String deviceId, String deviceName) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final locationHistory = await _apiService.getDeviceLocations(deviceId, deviceName);
      setState(() {
        _isLoading = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationHistoryPage(
            deviceId: deviceId,
            deviceName: deviceName,
            locationHistory: locationHistory,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading device location history: $e')),
      );
    }
  }


  @override
  void dispose() {
    _uploadTimer?.cancel();
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