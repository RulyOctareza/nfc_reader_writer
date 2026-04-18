import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/core/constants/app_constants.dart';

/// Helper untuk menampilkan [SnackBar] yang konsisten di seluruh aplikasi.
///
/// Menggunakan [ScaffoldMessenger] untuk manajemen queue yang benar.
abstract final class AppSnackBar {
  /// Menampilkan SnackBar sukses (hijau) dengan ikon centang.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF2E7D32),
      duration: AppConstants.snackBarSuccessDurationSeconds,
    );
  }

  /// Menampilkan SnackBar error (merah) dengan ikon error.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFC62828),
      duration: AppConstants.snackBarErrorDurationSeconds,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required int duration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          duration: Duration(seconds: duration),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
