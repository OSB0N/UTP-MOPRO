import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/backlog_item.dart';

/// Lapisan akses data backlog.
/// Android/iOS memakai SQLite (sqflite). Di Chrome (Flutter Web) sqflite tidak
/// didukung, jadi otomatis memakai SharedPreferences dengan isi data yang sama.
abstract class BacklogDao {
  Future<List<BacklogItem>> getAll();
  Future<void> upsert(BacklogItem item);
  Future<void> delete(int gameId);

  static BacklogDao create() => kIsWeb ? PrefsBacklogDao() : SqliteBacklogDao();
}

class SqliteBacklogDao implements BacklogDao {
  static const _table = 'backlog';

  Future<Database>? _opening;
  Future<Database> get _database => _opening ??= _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'game_backlog.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          game_id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          thumbnail TEXT NOT NULL,
          genre TEXT NOT NULL,
          platform TEXT NOT NULL,
          short_description TEXT NOT NULL,
          game_url TEXT NOT NULL,
          status TEXT NOT NULL,
          rating INTEGER NOT NULL DEFAULT 0,
          note TEXT NOT NULL DEFAULT '',
          added_at INTEGER NOT NULL
        )
      '''),
    );
  }

  @override
  Future<List<BacklogItem>> getAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'added_at DESC');
    return rows.map(BacklogItem.fromMap).toList();
  }

  @override
  Future<void> upsert(BacklogItem item) async {
    final db = await _database;
    await db.insert(
      _table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(int gameId) async {
    final db = await _database;
    await db.delete(_table, where: 'game_id = ?', whereArgs: [gameId]);
  }
}

class PrefsBacklogDao implements BacklogDao {
  static const _key = 'backlog_items';

  Future<List<BacklogItem>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BacklogItem.fromMap(Map<String, Object?>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Gagal membaca backlog: $e');
      return [];
    }
  }

  Future<void> _write(List<BacklogItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((i) => i.toMap()).toList()));
  }

  @override
  Future<List<BacklogItem>> getAll() async {
    final items = await _read();
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  @override
  Future<void> upsert(BacklogItem item) async {
    final items = await _read();
    final index = items.indexWhere((i) => i.gameId == item.gameId);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await _write(items);
  }

  @override
  Future<void> delete(int gameId) async {
    final items = await _read();
    items.removeWhere((i) => i.gameId == gameId);
    await _write(items);
  }
}
