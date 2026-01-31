import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/call_log_entry.dart';
import '../models/roulette_contact.dart';

/// Service for managing local SQLite database
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'phone_roulette.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create roulette_contacts table
    await db.execute('''
      CREATE TABLE roulette_contacts (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        closeness INTEGER DEFAULT 3
      )
    ''');

    // Create call_log table
    await db.execute('''
      CREATE TABLE call_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create cancelled_calls table (bailed/chickened out)
    await db.execute('''
      CREATE TABLE cancelled_calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        redeemed INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add cancelled_calls table
      await db.execute('''
        CREATE TABLE cancelled_calls (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          contact_id TEXT NOT NULL,
          contact_name TEXT NOT NULL,
          phone_number TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          redeemed INTEGER DEFAULT 0
        )
      ''');
    }
  }

  // ==================== Roulette Contacts ====================

  /// Get all selected contacts for roulette
  Future<List<RouletteContact>> getRouletteContacts() async {
    final db = await database;
    final maps = await db.query('roulette_contacts', orderBy: 'display_name');
    return maps.map((map) => RouletteContact.fromMap(map)).toList();
  }

  /// Check if a contact is selected for roulette
  Future<bool> isContactSelected(String contactId) async {
    final db = await database;
    final result = await db.query(
      'roulette_contacts',
      where: 'id = ?',
      whereArgs: [contactId],
    );
    return result.isNotEmpty;
  }

  /// Get IDs of all selected contacts
  Future<Set<String>> getSelectedContactIds() async {
    final db = await database;
    final maps = await db.query('roulette_contacts', columns: ['id']);
    return maps.map((map) => map['id'] as String).toSet();
  }

  /// Add a contact to the roulette
  Future<void> addContact(RouletteContact contact) async {
    final db = await database;
    await db.insert(
      'roulette_contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove a contact from the roulette
  Future<void> removeContact(String contactId) async {
    final db = await database;
    await db.delete(
      'roulette_contacts',
      where: 'id = ?',
      whereArgs: [contactId],
    );
  }

  /// Update contact's closeness rating
  Future<void> updateCloseness(String contactId, int closeness) async {
    final db = await database;
    await db.update(
      'roulette_contacts',
      {'closeness': closeness},
      where: 'id = ?',
      whereArgs: [contactId],
    );
  }

  // ==================== Call Log ====================

  /// Log a call
  Future<void> logCall(String contactId, String contactName) async {
    final db = await database;
    final entry = CallLogEntry(
      contactId: contactId,
      contactName: contactName,
      timestamp: DateTime.now(),
    );
    await db.insert('call_log', entry.toMap());
  }

  /// Get all call log entries, most recent first
  Future<List<CallLogEntry>> getCallLog({int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'call_log',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => CallLogEntry.fromMap(map)).toList();
  }

  /// Get total number of calls made
  Future<int> getTotalCallCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM call_log');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get call counts per contact
  Future<Map<String, int>> getCallCountsByContact() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT contact_id, contact_name, COUNT(*) as count 
      FROM call_log 
      GROUP BY contact_id 
      ORDER BY count DESC
    ''');

    final counts = <String, int>{};
    for (final row in results) {
      final name = row['contact_name'] as String;
      final count = row['count'] as int;
      counts[name] = count;
    }
    return counts;
  }

  /// Get unique contacts called count
  Future<int> getUniqueContactsCalledCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT contact_id) as count FROM call_log',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== Cancelled Calls (Shame Tracking) ====================

  /// Log a cancelled/bailed call
  Future<void> logCancelledCall(
    String contactId,
    String contactName,
    String phoneNumber,
  ) async {
    final db = await database;
    await db.insert('cancelled_calls', {
      'contact_id': contactId,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'redeemed': 0,
    });
  }

  /// Get all pending (unredeemed) cancelled calls
  Future<List<Map<String, dynamic>>> getPendingCancelledCalls() async {
    final db = await database;
    return await db.query(
      'cancelled_calls',
      where: 'redeemed = 0',
      orderBy: 'timestamp DESC',
    );
  }

  /// Redeem a cancelled call (mark as called)
  Future<void> redeemCancelledCall(int cancelledCallId) async {
    final db = await database;
    await db.update(
      'cancelled_calls',
      {'redeemed': 1},
      where: 'id = ?',
      whereArgs: [cancelledCallId],
    );
  }

  /// Get total cancelled calls count
  Future<int> getTotalCancelledCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cancelled_calls',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get pending (unredeemed) cancelled calls count
  Future<int> getPendingCancelledCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cancelled_calls WHERE redeemed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
