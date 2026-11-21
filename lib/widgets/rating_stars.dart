import 'package:flutter/material.dart';

import '../theme.dart';

/// Bintang 1-5. Kalau [onChanged] diisi, bintang bisa diketuk.
/// Mengetuk bintang yang sama dua kali mengembalikan rating ke 0.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.onChanged,
  });

  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? AppColors.star : AppColors.textDim,
        );
        if (onChanged == null) return icon;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged!(rating == i + 1 ? 0 : i + 1),
          child: Padding(padding: const EdgeInsets.all(2), child: icon),
        );
      }),
    );
  }
}
