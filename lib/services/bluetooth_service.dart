import 'package:find_my_device/database/database_helper.dart';
import 'package:find_my_device/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';


class BluetoothService {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  StreamController<ScanResult> _scanResultsController = StreamController<ScanResult>.broadcast();
  static const platform = MethodChannel('com.example.find_my_device/bluetooth');
  Stream<ScanResult> get scanResults => _scanResultsController.stream;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final LocationService _locationService = LocationService();
  final _packetStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get packetStream => _packetStreamController.stream;
  Timer? _advertisingTimer;
  Timer? _scanningTimer;

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

  Future<void> startScanning({Duration duration = const Duration(seconds:10)}) async {
    if (await FlutterBluePlus.isSupported) {
      FlutterBluePlus.startScan(timeout: duration, );
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          _scanResultsController.add(r);
          savedPackets(r);
        }
      });
    } else {
      print('Bluetooth is not available on this device');
    }
  }

  Future<void> startPeriodicScanning({Duration interval = const Duration(minutes: 1)}) async {
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

  Future<void> savedPackets(ScanResult scanResult) async {
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


      await _databaseHelper.insertPacket(packetData);
      print('Packet saved successfully: ${packetData['deviceId']}');
      final allpackets = await getSavedPackets();
      _packetStreamController.add(allpackets);
    } catch (e) {
      print('Error saving packet: $e');
    }
  }

  void stopPeriodicAdvertising() {
    _advertisingTimer?.cancel();
    _advertisingTimer = null;
  }

  Future<List<Map<String, dynamic>>> getSavedPackets() async {
   return await _databaseHelper.getPackets();
  }

  void dispose() {
    stopPeriodicAdvertising();
    stopPeriodicScanning();
    _scanResultsController.close();
    _packetStreamController.close();
  }
}
