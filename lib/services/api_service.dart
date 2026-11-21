import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/game.dart';

/// Hanya dipakai kalau aplikasi dijalankan di Chrome (Flutter Web) dan
/// request ke FreeToGame diblokir CORS. Di Android/iOS biarkan kosong.
/// Contoh isi (khusus demo): 'https://corsproxy.io/?url='
const String kWebCorsProxy = '';

/// Pesan error yang aman ditampilkan langsung ke pengguna.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Klien untuk FreeToGame API (https://www.freetogame.com/api-doc).
class FreeToGameApi {
  static const _baseUrl = 'https://www.freetogame.com/api';
  static const _timeout = Duration(seconds: 20);

  /// Jumlah game yang ditampilkan di katalog (diurutkan dari yang terpopuler).
  static const popularLimit = 20;

  /// GET /games?platform=...&category=...&sort-by=popularity
  /// Hasil diurutkan dari yang paling populer, lalu dipotong sebanyak [limit].
  Future<List<Game>> fetchGames({
    String platform = 'all',
    String? category,
    int? limit = popularLimit,
  }) async {
    final query = <String, String>{'platform': platform, 'sort-by': 'popularity'};
    if (category != null) query['category'] = category;

    final data = await _getJson('/games', query);
    if (data is List) {
      final games =
          data.whereType<Map<String, dynamic>>().map(Game.fromJson).toList();
      return limit == null ? games : games.take(limit).toList();
    }
    // Kombinasi filter tanpa hasil dibalas {"status":0,...}
    if (data is Map && data['status'] == 0) return [];
    throw const ApiException('Format data dari server tidak sesuai.');
  }

  /// GET /game?id=...
  Future<GameDetail> fetchGameDetail(int id) async {
    final data = await _getJson('/game', {'id': '$id'});
    if (data is Map<String, dynamic> && data['id'] != null) {
      return GameDetail.fromJson(data);
    }
    throw const ApiException('Detail game tidak ditemukan.');
  }

  Uri _buildUri(String path, Map<String, String> query) {
    final target = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    if (kIsWeb && kWebCorsProxy.isNotEmpty) {
      return Uri.parse('$kWebCorsProxy${Uri.encodeComponent(target.toString())}');
    }
    return target;
  }

  Future<dynamic> _getJson(String path, Map<String, String> query) async {
    try {
      final res = await http
          .get(_buildUri(path, query), headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw ApiException(
          'Server membalas dengan kode ${res.statusCode}. Coba lagi sebentar lagi.',
        );
      }
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on SocketException {
      throw const ApiException('Tidak bisa terhubung ke server. Periksa koneksi internetmu.');
    } on http.ClientException {
      throw const ApiException('Tidak bisa terhubung ke server. Periksa koneksi internetmu.');
    } on FormatException {
      throw const ApiException('Data dari server tidak bisa dibaca.');
    }
  }
}
