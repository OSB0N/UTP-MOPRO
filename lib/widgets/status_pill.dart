import 'package:flutter/material.dart';

import '../models/backlog_item.dart';
import '../theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.solid = false});

  final BacklogStatus status;

  /// Latar gelap pekat, dipakai saat pill berada di atas gambar.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final tint = color.withAlpha(36);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? Color.alphaBlend(tint, AppColors.bg) : tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(solid ? 200 : 120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
