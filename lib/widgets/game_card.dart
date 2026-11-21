import 'package:flutter/material.dart';

import '../models/backlog_item.dart';
import '../models/game.dart';
import '../theme.dart';
import 'game_image.dart';
import 'status_pill.dart';

/// Kartu game di halaman Katalog: gambar besar di atas, info di bawah.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.rank,
    required this.backlogItem,
    required this.onTap,
    required this.onAdd,
  });

  final Game game;
  final int rank;
  final BacklogItem? backlogItem;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final item = backlogItem;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GameImage(url: game.thumbnail, label: game.title),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withAlpha(220),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: item != null
                      ? StatusPill(status: item.status, solid: true)
                      : IconButton.filled(
                          onPressed: onAdd,
                          tooltip: 'Tambah ke backlog',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_rounded),
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(game.platformIcon, size: 15, color: AppColors.textDim),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          game.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textDim),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
