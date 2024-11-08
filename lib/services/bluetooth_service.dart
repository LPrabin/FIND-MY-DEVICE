import 'package:find_my_device/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class BluetoothService {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  StreamController<ScanResult> _scanResultsController = StreamController<ScanResult>.broadcast();
  static const platform = MethodChannel('com.example.find_my_device/bluetooth');
  Stream<ScanResult> get scanResults => _scanResultsController.stream;
  final LocationService _locationService = LocationService();
  Timer? _advertisingTimer;

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
      print('Advertising started successfully');
    } on PlatformException catch (e) {
      print('Failed to start advertising: ${e.message}');
    }
  }

  Future<void> startScanning() async {
    if (await FlutterBluePlus.isSupported) {
      FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
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

  Future<void> saveAdvertisedPacket(ScanResult scanResult) async {
    try {
      final Position position = await _locationService.getCurrentLocation();
      final packetData = {
        'deviceId': scanResult.device.remoteId.toString(),
        'deviceName': scanResult.device.platformName,
        'rssi': scanResult.rssi,
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'advertisementData': {
          'serviceUuids': scanResult.advertisementData.serviceUuids,
          'manufacturerData': scanResult.advertisementData.manufacturerData.toString(),
          'serviceData': scanResult.advertisementData.serviceData.toString(),
        }
      };

      final prefs = await SharedPreferences.getInstance();
      List<String> savedPackets = prefs.getStringList('advertisedPackets') ?? [];
      savedPackets.add(jsonEncode(packetData));
      await prefs.setStringList('advertisedPackets', savedPackets);

      print('Packet saved successfully: ${packetData['deviceId']}');
    } catch (e) {
      print('Error saving packet: $e');
    }
  }

  void stopPeriodicAdvertising() {
    _advertisingTimer?.cancel();
    _advertisingTimer = null;
  }

  Future<List<Map<String, dynamic>>> getSavedPackets() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPackets = prefs.getStringList('advertisedPackets') ?? [];
    return savedPackets.map((packet) =>
    Map<String, dynamic>.from(jsonDecode(packet))
    ).toList();
  }

  void dispose() {
    stopPeriodicAdvertising();
    _scanResultsController.close();
  }
}
