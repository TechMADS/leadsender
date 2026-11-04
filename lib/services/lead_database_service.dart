import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lead.dart';

class LeadDatabaseService {
  static const _dbName = 'leadsender.db';
  static const _table = 'leads';
  Database? _db;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            normalized_number TEXT NOT NULL,
            original_number TEXT NOT NULL,
            name TEXT,
            imported_at TEXT NOT NULL,
            last_processed_at TEXT,
            status TEXT NOT NULL,
            notes TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_norm ON $_table(normalized_number)',
        );
      },
    );
  }

  Database get db {
    if (_db == null) throw StateError('DB not initialized');
    return _db!;
  }

  // Future<int> insert(Lead lead) async =>
  //     db.insert(_table, lead.toMap()..remove('id'));

  Future<int> insert(Lead lead) async {
    final map = lead.toMap()..remove('id');
    return db.insert(_table, map);
  }

  Future<void> update(Lead lead) async {
    if (lead.id == null) return;
    await db.update(
      _table,
      lead.toMap(),
      where: 'id = ?',
      whereArgs: [lead.id],
    );
  }

  Future<List<Lead>> all() async {
    final rows = await db.query(_table, orderBy: 'imported_at DESC');
    return rows.map(Lead.fromMap).toList();
  }

  Future<Lead?> findByNumber(String normalized) async {
    final rows = await db.query(
      _table,
      where: 'normalized_number = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Lead.fromMap(rows.first);
  }

  Future<void> deleteById(int id) async =>
      db.delete(_table, where: 'id = ?', whereArgs: [id]);

  Future<void> clearAll() async => db.delete(_table);

  Future<Map<String, int>> stats() async {
    final result = await db.rawQuery(
      'SELECT status, COUNT(*) as c FROM $_table GROUP BY status',
    );
    final map = <String, int>{};
    for (final r in result) {
      map[r['status'] as String] = r['c'] as int;
    }
    return map;
  }
}