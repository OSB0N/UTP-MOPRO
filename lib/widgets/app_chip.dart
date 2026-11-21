import 'package:flutter/material.dart';

import '../theme.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? color : AppColors.outline),
      labelStyle: TextStyle(
        color: selected ? AppColors.onAccent : AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
