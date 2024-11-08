import 'package:flutter/material.dart';
import 'package:find_my_device/services/bluetooth_service.dart';

class SavedPacketsPage extends StatelessWidget {
  final BluetoothService bluetoothService;

  SavedPacketsPage({required this.bluetoothService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved Packets')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: bluetoothService.getSavedPackets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No saved packets found.'));
          } else {
            final packets = snapshot.data!;
            return ListView.builder(
              itemCount: packets.length,
              itemBuilder: (context, index) {
                final packet = packets[index];
                return ListTile(
                  title: Text('Device: ${packet['deviceId']}'),
                  subtitle: Text('Location: ${packet['location']} at ${packet['timestamp']}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}