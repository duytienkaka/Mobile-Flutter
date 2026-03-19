import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

Future<T?> _showAppAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.44),
    animationStyle: AnimationStyle.noAnimation,
    builder: (dialogContext) => SafeArea(child: Builder(builder: builder)),
  );
}

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Huy',
  String confirmText = 'Xac nhan',
  bool isDanger = false,
  IconData? icon,
  Widget? extraContent,
}) async {
  final result = await _showAppAnimatedDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final accent = isDanger ? AppColors.danger : AppColors.primary;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon ?? Icons.help_outline_rounded, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              if (extraContent != null) ...[
                const SizedBox(height: 12),
                extraContent,
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(cancelText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result == true;
}

Future<String?> showAppInputDialog({
  required BuildContext context,
  required String title,
  required String labelText,
  String? hintText,
  String cancelText = 'Huy',
  String confirmText = 'Luu',
  String? initialValue,
  bool allowEmpty = false,
  TextInputType keyboardType = TextInputType.text,
  IconData? icon,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  String? errorText;

  final result = await _showAppAnimatedDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon ?? Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(null),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Dong',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: labelText,
                      hintText: hintText,
                      errorText: errorText,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) {
                      final value = controller.text.trim();
                      if (!allowEmpty && value.isEmpty) {
                        setLocalState(() => errorText = 'Khong duoc de trong');
                        return;
                      }
                      Navigator.of(dialogContext).pop(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(null),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(cancelText),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final value = controller.text.trim();
                            if (!allowEmpty && value.isEmpty) {
                              setLocalState(() => errorText = 'Khong duoc de trong');
                              return;
                            }
                            Navigator.of(dialogContext).pop(value);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(confirmText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  controller.dispose();
  return result;
}