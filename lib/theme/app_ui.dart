import 'package:flutter/material.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:traavaalay/theme/app_tokens.dart';

class AppUi {
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.success,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static ButtonStyle warningButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.warning,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.danger,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static ButtonStyle subtleOutlinedStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  );

  static InputDecoration inputDecoration({
    required String label,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  static BoxDecoration iconBadgeDecoration({
    Color background = AppColors.mutedSurface,
    Color border = AppColors.border,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: border),
    );
  }
}
