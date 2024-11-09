import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class DeviceLocationMap extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> packetsStream;

  DeviceLocationMap({required this.packetsStream});

  @override
  _DeviceLocationMapState createState() => _DeviceLocationMapState();
}

class _DeviceLocationMapState extends State<DeviceLocationMap> {
  final Map<String, Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _listenToPackets();
  }

  void _listenToPackets() {
    widget.packetsStream.listen((packets) {
      _updateMarkers(packets);
    });
  }

  void _updateMarkers(List<Map<String, dynamic>> packets) {
    setState(() {
      _markers.clear();
      for (var packet in packets) {
        final deviceId = packet['deviceId'] as String;
        final deviceName = packet['deviceName'] as String? ?? 'Unknown Device';
        final latLng = LatLng(
          packet['location']['latitude'] as double,
          packet['location']['longitude'] as double,
        );

        _markers[deviceId] = Marker(
          markerId: MarkerId(deviceId),
          position: latLng,
          infoWindow: InfoWindow(
            title: deviceName,
            snippet: 'Last seen: ${packet['timestamp']}',
          ),
        );
      }
    });

    // Center map on the latest device if possible
    if (packets.isNotEmpty && _mapController != null) {
      final latest = packets.last;
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(
          latest['location']['latitude'] as double,
          latest['location']['longitude'] as double,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(0, 0),
        zoom: 15,
      ),
      markers: Set<Marker>.of(_markers.values),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
    );
  }
}
