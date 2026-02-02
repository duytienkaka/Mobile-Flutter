import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
	static ThemeData get lightTheme {
		return ThemeData(
			useMaterial3: true,
			colorScheme: ColorScheme.fromSeed(
				seedColor: AppColors.primary,
				primary: AppColors.primary,
				surface: AppColors.surface,
			),
			scaffoldBackgroundColor: AppColors.background,
			appBarTheme: const AppBarTheme(
				backgroundColor: AppColors.background,
				foregroundColor: AppColors.textPrimary,
				elevation: 0,
				centerTitle: false,
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: AppColors.surface,
				contentPadding:
						const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.border),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.border),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.black, width: 1),
				),
			),
			cardTheme: CardThemeData(
				color: AppColors.surface,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(16),
					side: const BorderSide(color: AppColors.border),
				),
				elevation: 0,
			),
			bottomNavigationBarTheme: const BottomNavigationBarThemeData(
				backgroundColor: AppColors.surface,
				selectedItemColor: AppColors.black,
				unselectedItemColor: AppColors.textMuted,
				showSelectedLabels: false,
				showUnselectedLabels: false,
				type: BottomNavigationBarType.fixed,
			),
			chipTheme: ChipThemeData(
				backgroundColor: AppColors.surfaceSoft,
				labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
				side: const BorderSide(color: AppColors.border),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
			),
		);
	}
}