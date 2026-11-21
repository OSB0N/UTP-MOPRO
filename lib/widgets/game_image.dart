import 'package:flutter/material.dart';

import '../theme.dart';

const _palettes = <List<Color>>[
  [Color(0xFF5B6CFF), Color(0xFF8A4DFF)],
  [Color(0xFFFF5C8A), Color(0xFFFF9A5C)],
  [Color(0xFF2EC4B6), Color(0xFF3A86FF)],
  [Color(0xFFFFB347), Color(0xFFFF5C8A)],
  [Color(0xFF43E97B), Color(0xFF38A3A5)],
];

/// Gambar jaringan dengan placeholder saat loading.
/// Kalau gambar gagal dimuat dan [label] diisi (judul game), yang tampil adalah
/// gambar pengganti berwarna berisi inisial judul, jadi setiap game tetap punya visual.
/// Ukuran mengikuti widget induk (SizedBox / AspectRatio / Stack).
class GameImage extends StatelessWidget {
  const GameImage({
    super.key,
    required this.url,
    this.label = '',
    this.fit = BoxFit.cover,
  });

  final String url;
  final String label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _Fallback(label: label);
    return Image.network(
      url,
      fit: fit,
      // Di Chrome (Flutter Web) gambar dari domain lain sering diblokir CORS.
      // Dengan strategi ini, Flutter beralih memakai elemen <img> milik browser.
      // Di Android/iOS parameter ini diabaikan.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: AppColors.surfaceHigh),
      errorBuilder: (context, error, stack) => _Fallback(label: label),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.label});

  final String label;

  String get _initials {
    final words = label.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const ColoredBox(
        color: AppColors.surfaceHigh,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, color: AppColors.textDim),
        ),
      );
    }

    final colors = _palettes[label.hashCode.abs() % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white.withAlpha(225),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
