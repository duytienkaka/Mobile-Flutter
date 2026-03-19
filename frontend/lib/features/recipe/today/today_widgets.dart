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
		final backgroundColor = selected ? AppColors.textPrimary : AppColors.surfaceSoft;

		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 200),
				   margin: EdgeInsets.zero,
				   height: 48,
				   padding: const EdgeInsets.symmetric(vertical: 0),
				decoration: BoxDecoration(
					color: backgroundColor,
					borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
					border: Border.all(color: AppColors.border),
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