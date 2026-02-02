import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SectionContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}