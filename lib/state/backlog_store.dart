import 'package:flutter/foundation.dart';

import '../models/backlog_item.dart';
import '../models/game.dart';
import '../services/backlog_dao.dart';

/// Sumber data backlog untuk seluruh layar.
/// Perubahan langsung tampil di UI (update di memori), lalu disimpan ke storage.
class BacklogStore extends ChangeNotifier {
  BacklogStore._();
  static final BacklogStore instance = BacklogStore._();

  final BacklogDao _dao = BacklogDao.create();
  List<BacklogItem> _items = const [];
  bool _loaded = false;

  List<BacklogItem> get items => _items;
  bool get loaded => _loaded;

  int count(BacklogStatus status) =>
      _items.where((i) => i.status == status).length;

  BacklogItem? find(int gameId) {
    for (final item in _items) {
      if (item.gameId == gameId) return item;
    }
    return null;
  }

  bool contains(int gameId) => find(gameId) != null;

  Future<void> load() async {
    try {
      _items = await _dao.getAll();
    } catch (e) {
      debugPrint('Gagal memuat backlog: $e');
      _items = const [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(Game game) async {
    if (contains(game.id)) return;
    await save(BacklogItem.fromGame(game));
  }

  Future<void> save(BacklogItem item) async {
    final next = [..._items];
    final index = next.indexWhere((i) => i.gameId == item.gameId);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.add(item);
    }
    next.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    _items = next;
    notifyListeners();
    await _guard(() => _dao.upsert(item));
  }

  Future<void> remove(int gameId) async {
    _items = _items.where((i) => i.gameId != gameId).toList();
    notifyListeners();
    await _guard(() => _dao.delete(gameId));
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      debugPrint('Gagal menyimpan backlog: $e');
    }
  }
}
