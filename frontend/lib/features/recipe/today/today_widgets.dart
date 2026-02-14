import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TodayTabButton extends StatelessWidget {
	final String label;
	final bool selected;
	final VoidCallback onTap;

	const TodayTabButton({
		super.key,
		required this.label,
		required this.selected,
		required this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		final textColor = selected ? AppColors.surface : AppColors.textSecondary;

		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 200),
				margin: EdgeInsets.only(top: selected ? 0 : 6),
				padding: const EdgeInsets.symmetric(vertical: 12),
				decoration: BoxDecoration(
					color: selected ? AppColors.black : const Color(0xFFD9D9D9),
					borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
				),
				child: Center(
					child: Text(
						label,
						textAlign: TextAlign.center,
						style: AppTextStyles.caption.copyWith(
							fontWeight: FontWeight.w700,
							color: textColor,
						),
					),
				),
			),
		);
	}
}