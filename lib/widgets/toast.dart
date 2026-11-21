import 'package:flutter/material.dart';

import '../theme.dart';

/// Snackbar singkat, opsional dengan tombol aksi (mis. "Batal").
void showToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: AppColors.accent,
              onPressed: onAction ?? () {},
            ),
    ),
  );
}
