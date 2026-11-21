import 'game.dart';

/// Status sebuah game di backlog.
enum BacklogStatus { antre, dimainkan, tamat }

/// Satu baris data di penyimpanan lokal (tabel `backlog`).
/// Data dasar game ikut disimpan supaya backlog tetap tampil saat offline.
class BacklogItem {
  final int gameId;
  final String title;
  final String thumbnail;
  final String genre;
  final String platform;
  final String shortDescription;
  final String gameUrl;
  final BacklogStatus status;
  final int rating; // 0 = belum dinilai, 1-5 bintang
  final String note;
  final int addedAt; // epoch millis

  const BacklogItem({
    required this.gameId,
    required this.title,
    required this.thumbnail,
    required this.genre,
    required this.platform,
    required this.shortDescription,
    required this.gameUrl,
    required this.status,
    required this.rating,
    required this.note,
    required this.addedAt,
  });

  factory BacklogItem.fromGame(Game game) => BacklogItem(
        gameId: game.id,
        title: game.title,
        thumbnail: game.thumbnail,
        genre: game.genre,
        platform: game.platform,
        shortDescription: game.shortDescription,
        gameUrl: game.gameUrl,
        status: BacklogStatus.antre,
        rating: 0,
        note: '',
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );

  BacklogItem copyWith({BacklogStatus? status, int? rating, String? note}) =>
      BacklogItem(
        gameId: gameId,
        title: title,
        thumbnail: thumbnail,
        genre: genre,
        platform: platform,
        shortDescription: shortDescription,
        gameUrl: gameUrl,
        status: status ?? this.status,
        rating: rating ?? this.rating,
        note: note ?? this.note,
        addedAt: addedAt,
      );

  Map<String, Object?> toMap() => {
        'game_id': gameId,
        'title': title,
        'thumbnail': thumbnail,
        'genre': genre,
        'platform': platform,
        'short_description': shortDescription,
        'game_url': gameUrl,
        'status': status.name,
        'rating': rating,
        'note': note,
        'added_at': addedAt,
      };

  factory BacklogItem.fromMap(Map<String, Object?> map) => BacklogItem(
        gameId: map['game_id'] as int,
        title: map['title'] as String,
        thumbnail: map['thumbnail'] as String,
        genre: map['genre'] as String,
        platform: map['platform'] as String,
        shortDescription: map['short_description'] as String,
        gameUrl: map['game_url'] as String,
        status: BacklogStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => BacklogStatus.antre,
        ),
        rating: map['rating'] as int,
        note: map['note'] as String,
        addedAt: map['added_at'] as int,
      );

  /// Dipakai untuk membuka halaman detail dari daftar backlog.
  Game toGame() => Game(
        id: gameId,
        title: title,
        thumbnail: thumbnail,
        shortDescription: shortDescription,
        gameUrl: gameUrl,
        genre: genre,
        platform: platform,
        publisher: '',
        developer: '',
        releaseDate: '',
      );
}
