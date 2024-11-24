import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const _database_version = 1;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'device_database.db');
    return await openDatabase(
      path,
      version: _database_version,

      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE devices(
            serialNumber INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT ,
            device_name TEXT DEFAULT 'Unknown',
            rssi INTEGER,
            timestamp TEXT,
            latitude REAL,
            longitude REAL,
            serviceUuids TEXT,
            manufacturerData TEXT,
            serviceData TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

      },
      onUpgrade: _onUpgrade,


    );
  }

  Future<void> insertOrUpdateDevice(Map<String, dynamic> device) async {
    final Database db = await database;
    await db.insert(
      'devices',
      device,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllDevices() async {
    final Database db = await database;
    return await db.query('devices');
  }

  Future<Map<String, dynamic>?> getDevice(String device_id) async {
    final Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'devices',
      where: 'device_id = ?',
      whereArgs: [device_id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getPendingDeviceData() async {
    final db = await database;
    return await db.query(
      'devices',
      where: 'synced = ?',
      whereArgs: [0], // 0 means not synced
    );
  }

  Future<void> markDataAsSynced(int serialNumber) async {
    final db = await database;
    await db.update(
      'devices',
      {'synced': 1},
      where: 'serialNumber = ?',
      whereArgs: [serialNumber],
    );
  }


  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {

    }
  }



}