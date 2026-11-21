String _s(dynamic v) => v?.toString() ?? '';

/// Data game dari endpoint daftar: GET /api/games
class Game {
  final int id;
  final String title;
  final String thumbnail;
  final String shortDescription;
  final String gameUrl;
  final String genre;
  final String platform;
  final String publisher;
  final String developer;
  final String releaseDate;

  const Game({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.shortDescription,
    required this.gameUrl,
    required this.genre,
    required this.platform,
    required this.publisher,
    required this.developer,
    required this.releaseDate,
  });

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: (json['id'] as num).toInt(),
        title: _s(json['title']),
        thumbnail: _s(json['thumbnail']),
        shortDescription: _s(json['short_description']),
        gameUrl: _s(json['game_url']),
        genre: _s(json['genre']),
        platform: _s(json['platform']),
        publisher: _s(json['publisher']),
        developer: _s(json['developer']),
        releaseDate: _s(json['release_date']),
      );

  /// Label platform yang lebih singkat: PC, Browser, atau PC + Web.
  String get platformShort {
    final p = platform.toLowerCase();
    final hasPc = p.contains('pc');
    final hasWeb = p.contains('browser');
    if (hasPc && hasWeb) return 'PC + Web';
    if (hasWeb) return 'Browser';
    return 'PC';
  }
}

/// Data lengkap satu game dari endpoint detail: GET /api/game?id=...
class GameDetail {
  final int id;
  final String title;
  final String status;
  final String description;
  final String publisher;
  final String developer;
  final String releaseDate;
  final Map<String, String> requirements;
  final List<String> screenshots;

  const GameDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    required this.publisher,
    required this.developer,
    required this.releaseDate,
    required this.requirements,
    required this.screenshots,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    final reqs = <String, String>{};
    final rawReq = json['minimum_system_requirements'];
    if (rawReq is Map) {
      rawReq.forEach((key, value) {
        final text = _s(value).trim();
        if (text.isNotEmpty) reqs[key.toString()] = text;
      });
    }

    final shots = <String>[];
    final rawShots = json['screenshots'];
    if (rawShots is List) {
      for (final e in rawShots) {
        if (e is Map && e['image'] != null) shots.add(e['image'].toString());
      }
    }

    return GameDetail(
      id: (json['id'] as num).toInt(),
      title: _s(json['title']),
      status: _s(json['status']),
      description: _s(json['description']),
      publisher: _s(json['publisher']),
      developer: _s(json['developer']),
      releaseDate: _s(json['release_date']),
      requirements: reqs,
      screenshots: shots,
    );
  }
}
