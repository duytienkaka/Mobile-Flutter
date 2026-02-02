import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
	static const title = TextStyle(
		fontSize: 20,
		fontWeight: FontWeight.w700,
		color: AppColors.textPrimary,
	);

	static const subtitle = TextStyle(
		fontSize: 14,
		fontWeight: FontWeight.w600,
		color: AppColors.textSecondary,
	);

	static const body = TextStyle(
		fontSize: 13,
		fontWeight: FontWeight.w400,
		color: AppColors.textPrimary,
	);

	static const caption = TextStyle(
		fontSize: 11,
		fontWeight: FontWeight.w500,
		color: AppColors.textMuted,
	);
}