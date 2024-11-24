import 'package:find_my_device/database/database_helper.dart';
import 'package:find_my_device/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';


class BluetoothService {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  StreamController<ScanResult> _scanResultsController = StreamController<
      ScanResult>.broadcast();
  static const platform = MethodChannel('com.example.find_my_device/bluetooth');

  Stream<ScanResult> get scanResults => _scanResultsController.stream;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final LocationService _locationService = LocationService();
  final _packetStreamController = StreamController<
      List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get packetStream =>
      _packetStreamController.stream;
  Timer? _advertisingTimer;
  Timer? _scanningTimer;

  BluetoothService() {
    platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'advertisementData') {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
            call.arguments);
        _handleAdvertisementData(data);
      }
    });
  }



  Future<void> startPeriodicAdvertising() async {
    // Start initial advertising
    await startAdvertising();

    // Set up timer for periodic advertising
    _advertisingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await startAdvertising();
    });
  }

  Future<void> startAdvertising() async {
    try {
      await platform.invokeMethod('startAdvertising');
      print('Advertising started successfully:');
    } on PlatformException catch (e) {
      print('Failed to start advertising: ${e.message}');
    }
  }

  Future<void> startScanning(
      {Duration duration = const Duration(seconds: 10)}) async {
    if (await FlutterBluePlus.isSupported) {
      FlutterBluePlus.startScan(timeout: duration,);
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          _scanResultsController.add(r);
          saveAdvertisedPacket(r);
        }
      });
    } else {
      print('Bluetooth is not available on this device');
    }
  }

  Future<void> startPeriodicScanning(
      {Duration interval = const Duration(minutes: 1)}) async {
    // Start initial scanning
    await startScanning();

    // Set up timer for periodic scanning
    _scanningTimer = Timer.periodic(interval, (timer) async {
      await startScanning();
    });
  }

  void stopPeriodicScanning() {
    _scanningTimer?.cancel();
    _scanningTimer = null;
  }

  Future<void> saveAdvertisedPacket(ScanResult scanResult) async {
    try {
      final Position position = await _locationService.getCurrentLocation();

      // Prepare device data for database
      final deviceData = {
        'device_id': scanResult.device.remoteId.toString(),
        'device_name': scanResult.device.platformName,
        'rssi': scanResult.rssi,
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'serviceUuids': jsonEncode(scanResult.advertisementData.serviceUuids),
        'manufacturerData': scanResult.advertisementData.manufacturerData
            .toString(),
        'serviceData': scanResult.advertisementData.serviceData.toString(),

      };

      // Insert or update device in database
      await _databaseHelper.insertOrUpdateDevice(deviceData);
      print(
          'Device saved successfully: ${deviceData['device_id']} ${deviceData['device_name']}${deviceData['rssi']}${deviceData['timestamp']}${deviceData['latitude']}${deviceData['longitude']}${deviceData['serviceUuids']}${deviceData['manufacturerData']}${deviceData['serviceData']}');
    } catch (e) {
      print('Error saving device: $e');
    }
  }

  void stopPeriodicAdvertising() {
    _advertisingTimer?.cancel();
    _advertisingTimer = null;
  }

  Future<List<Map<String, dynamic>>> getSavedDevices() async {
    return await _databaseHelper.getAllDevices();
  }

  Future<Map<String, dynamic>?> getDevice(String device_id) async {
    return await _databaseHelper.getDevice(device_id);
  }


  void dispose() {
    stopPeriodicAdvertising();
    stopPeriodicScanning();
    _scanResultsController.close();
    _packetStreamController.close();
  }



  void _handleAdvertisementData(Map<String, dynamic> data) async {
    // Extract the necessary information from the advertisement data
    final deviceId = data['remoteId'];
    final deviceName = data['platformName']; // Log the received advertisement data
    print(
        'Received advertisement data: $data'); // Check if the device name and service UUIDs are not null
    if (deviceName != null && deviceId != null) {
      // Prepare the device data for adding to the database or further processing
      final deviceData = {
        'deviceName': deviceName,
        'deviceId': deviceId,
        // Add any additional fields you need

      };
      _addDevice(deviceData);
    }
  }

  void _addDevice(Map<String, dynamic> deviceData) {
    // Implement your logic to add the device, such as saving to a database
    print('Adding device: ${deviceData['deviceName']}');
  }
}

