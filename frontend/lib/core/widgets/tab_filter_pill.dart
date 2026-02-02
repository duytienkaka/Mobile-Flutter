import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TabFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const TabFilterPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}