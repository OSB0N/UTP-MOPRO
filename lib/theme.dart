import 'package:flutter/material.dart';

import 'models/backlog_item.dart';
import 'models/game.dart';

/// Palet warna aplikasi: biru malam + pink sebagai aksen utama,
/// dan tiga warna status (Antre, Main, Tamat).
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0F1738);
  static const surface = Color(0xFF182252);
  static const surfaceHigh = Color(0xFF222E66);
  static const outline = Color(0xFF34428A);
  static const text = Color(0xFFEEF1FF);
  static const textDim = Color(0xFFA3AEDD);
  static const accent = Color(0xFFFF5C8A);
  static const onAccent = Color(0xFF0F1738);
  static const danger = Color(0xFFFF7A7A);
  static const star = Color(0xFFFFC53D);

  static const antre = Color(0xFF6EC6FF);
  static const dimainkan = Color(0xFFFFC53D);
  static const tamat = Color(0xFF5EE0A0);
}

extension BacklogStatusUi on BacklogStatus {
  String get label => switch (this) {
        BacklogStatus.antre => 'Antre',
        BacklogStatus.dimainkan => 'Main',
        BacklogStatus.tamat => 'Tamat',
      };

  IconData get icon => switch (this) {
        BacklogStatus.antre => Icons.schedule_rounded,
        BacklogStatus.dimainkan => Icons.sports_esports_rounded,
        BacklogStatus.tamat => Icons.emoji_events_rounded,
      };

  Color get color => switch (this) {
        BacklogStatus.antre => AppColors.antre,
        BacklogStatus.dimainkan => AppColors.dimainkan,
        BacklogStatus.tamat => AppColors.tamat,
      };
}

extension GameUi on Game {
  IconData get platformIcon =>
      platformShort == 'Browser' ? Icons.public_rounded : Icons.computer_rounded;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent,
      surfaceTintColor: Colors.transparent,
      height: 68,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
    ),
  );
}

InputDecoration fieldDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textDim),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AppColors.outline, 0),
    enabledBorder: border(AppColors.outline, 0),
    focusedBorder: border(AppColors.accent, 1.5),
  );
}

ButtonStyle segmentedStyle() => SegmentedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textDim,
      selectedBackgroundColor: AppColors.accent,
      selectedForegroundColor: AppColors.onAccent,
      side: const BorderSide(color: AppColors.outline),
    );
