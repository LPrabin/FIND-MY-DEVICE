import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('find_my_device.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE advertised_packets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId TEXT NOT NULL,
        deviceName TEXT,
        rssi INTEGER,
        timestamp TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        serviceUuids TEXT,
        manufacturerData TEXT,
        serviceData TEXT
      )
    ''');
  }

  Future<int> insertPacket(Map<String, dynamic> packet) async {
    final db = await database;
    return await db.insert('advertised_packets', {
      'deviceId': packet['deviceId'],
      'deviceName': packet['deviceName'],
      'rssi': packet['rssi'],
      'timestamp': packet['timestamp'],
      'latitude': packet['location']['latitude'],
      'longitude': packet['location']['longitude'],
      'serviceUuids': packet['advertisementData']['serviceUuids'].toString(),
      'manufacturerData': packet['advertisementData']['manufacturerData'],
      'serviceData': packet['advertisementData']['serviceData'],
    });
  }

  Future<List<Map<String, dynamic>>> getPackets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('advertised_packets');

    return maps.map((packet) => {
      'deviceId': packet['deviceId'],
      'deviceName': packet['deviceName'],
      'rssi': packet['rssi'],
      'timestamp': packet['timestamp'],
      'location': {
        'latitude': packet['latitude'],
        'longitude': packet['longitude'],
      },
      'advertisementData': {
        'serviceUuids': packet['serviceUuids'],
        'manufacturerData': packet['manufacturerData'],
        'serviceData': packet['serviceData'],
      }
    }).toList();
  }
}
