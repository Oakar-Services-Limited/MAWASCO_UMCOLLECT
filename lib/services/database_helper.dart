import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:um_collect/services/offline_queue_notifier.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _dbName = 'um_collect_offline.db';
  static const _dbVersion = 1;

  static const String formsTable = 'forms';
  static const String submissionsTable = 'submissions';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $formsTable (
            id TEXT PRIMARY KEY,
            form_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $submissionsTable (
            id TEXT PRIMARY KEY,
            form_id TEXT NOT NULL,
            form_name TEXT NOT NULL,
            responses TEXT NOT NULL,
            geometry TEXT,
            collected_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            sync_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Forms cache
  Future<void> saveForms(List<dynamic> forms) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final form in forms) {
      final id = form['id']?.toString();
      if (id == null) continue;
      batch.insert(
        formsTable,
        {
          'id': id,
          'form_data': jsonEncode(form),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveForm(Map<String, dynamic> form) async {
    final db = await database;
    final id = form['id']?.toString();
    if (id == null) return;
    await db.insert(
      formsTable,
      {
        'id': id,
        'form_data': jsonEncode(form),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getForms() async {
    final db = await database;
    final rows = await db.query(formsTable, orderBy: 'updated_at DESC');
    return rows
        .map((r) => jsonDecode(r['form_data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>?> getForm(String formId) async {
    final db = await database;
    final rows =
        await db.query(formsTable, where: 'id = ?', whereArgs: [formId], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['form_data'] as String)
        as Map<String, dynamic>;
  }

  // Submissions queue
  Future<void> saveSubmission({
    required String id,
    required String formId,
    required String formName,
    required Map<String, dynamic> responses,
    Map<String, dynamic>? geometry,
  }) async {
    final db = await database;
    await db.insert(
      submissionsTable,
      {
        'id': id,
        'form_id': formId,
        'form_name': formName,
        'responses': jsonEncode(responses),
        'geometry': geometry != null ? jsonEncode(geometry) : null,
        'collected_at': DateTime.now().toIso8601String(),
        'synced': 0,
        'sync_status': 'pending',
        'sync_error': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    OfflineQueueNotifier.instance.refresh();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSubmissions() async {
    final db = await database;
    final rows = await db.query(
      submissionsTable,
      where: 'synced = 0',
      orderBy: 'created_at DESC',
    );
    return rows;
  }

  Future<void> updateSubmissionSyncStatus({
    required String id,
    required bool synced,
    required String syncStatus,
    String? syncError,
  }) async {
    final db = await database;
    await db.update(
      submissionsTable,
      {
        'synced': synced ? 1 : 0,
        'sync_status': syncStatus,
        'sync_error': syncError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSubmission(String id) async {
    final db = await database;
    await db.delete(
      submissionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    OfflineQueueNotifier.instance.refresh();
  }

  Future<void> deleteAllUnsyncedSubmissions() async {
    final db = await database;
    await db.delete(
      submissionsTable,
      where: 'synced = 0',
    );
    OfflineQueueNotifier.instance.refresh();
  }
}

