
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:travel_planner/models/checklist_item.dart';
import 'package:travel_planner/models/itinerary_item.dart';
import 'package:travel_planner/models/trip.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'travel_planner.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE checklist_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isChecked INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destination TEXT,
        startDate TEXT,
        endDate TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE itinerary_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        item_order INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Checklist Methods ---
  Future<List<ChecklistItem>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('checklist_items');
    return List.generate(maps.length, (i) {
      return ChecklistItem.fromMap(maps[i]);
    });
  }

  Future<int> insertItem(ChecklistItem item) async {
    final db = await database;
    return await db.insert('checklist_items', item.toMap());
  }

  Future<int> updateItem(ChecklistItem item) async {
    final db = await database;
    return await db.update('checklist_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Trip Methods ---
  Future<Trip?> getTrip(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    } 
    return null;
  }

  Future<Trip> getOrCreateCurrentTrip() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('trips', orderBy: 'id DESC', limit: 1);
    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    } else {
      final newTrip = Trip();
      final id = await db.insert('trips', newTrip.toMap());
      newTrip.id = id;
      return newTrip;
    }
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await database;
    return await db.update('trips', trip.toMap(), where: 'id = ?', whereArgs: [trip.id]);
  }

  // --- Itinerary Methods ---
  Future<List<ItineraryItem>> getItineraryItems(int tripId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'itinerary_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'item_order ASC',
    );
    return List.generate(maps.length, (i) {
      return ItineraryItem.fromMap(maps[i]);
    });
  }

  Future<int> insertItineraryItem(ItineraryItem item) async {
    final db = await database;
    return await db.insert('itinerary_items', item.toMap());
  }

  Future<int> updateItineraryItem(ItineraryItem item) async {
    final db = await database;
    return await db.update('itinerary_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItineraryItem(int id) async {
    final db = await database;
    return await db.delete('itinerary_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateItineraryOrder(List<ItineraryItem> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      item.order = i;
      batch.update('itinerary_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    }
    await batch.commit(noResult: true);
  }
}
