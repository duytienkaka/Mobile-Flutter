import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_localizations.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';

class NotificationScreen extends StatelessWidget {
	const NotificationScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
			floatingActionButton:
					MainFab(onPressed: () => _openScreen(context, const PantryScreen())),
			bottomNavigationBar: MainBottomBar(
				currentIndex: 4,
				onHome: () => _openScreen(context, const HomeScreen()),
				onRecipe: () => _openScreen(context, const RecipeScreen()),
				onShopping: () => _openScreen(context, const ShoppingScreen()),
				onNotifications: () => _openScreen(context, const NotificationScreen()),
			),
			appBar: AppBar(
				backgroundColor: AppColors.background,
				automaticallyImplyLeading: false,
				title: Text(context.tr('Thông báo'), style: AppTextStyles.title),
			),
			body: Center(
				child: Text(context.tr('Màn hình thông báo'),
						style: AppTextStyles.subtitle),
			),
		);
	}

	void _openScreen(BuildContext context, Widget screen) {
		Navigator.of(context).pushReplacement(
			MaterialPageRoute(builder: (_) => screen),
		);
	}
}