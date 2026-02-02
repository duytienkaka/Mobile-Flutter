import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class HeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const HeaderBar({
    super.key,
    required this.title,
    this.onBack,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(title, style: AppTextStyles.title)),
        if (actionIcon != null)
          IconButton(onPressed: onAction, icon: Icon(actionIcon))
      ],
    );
  }
}