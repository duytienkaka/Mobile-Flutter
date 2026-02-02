import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MainFab extends StatelessWidget {
	final VoidCallback onPressed;

	const MainFab({super.key, required this.onPressed});

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: 64,
			height: 64,
			child: FloatingActionButton(
				onPressed: onPressed,
				backgroundColor: AppColors.success,
				foregroundColor: AppColors.surface,
				elevation: 6,
				shape: const CircleBorder(),
				child: const Icon(Icons.add, size: 32),
			),
		);
	}
}

class MainBottomBar extends StatelessWidget {
	final int currentIndex;
	final VoidCallback onHome;
	final VoidCallback onRecipe;
	final VoidCallback onShopping;
	final VoidCallback onNotifications;

	const MainBottomBar({
		super.key,
		required this.currentIndex,
		required this.onHome,
		required this.onRecipe,
		required this.onShopping,
		required this.onNotifications,
	});

	Color _colorFor(int index) {
		return currentIndex == index ? AppColors.black : AppColors.textMuted;
	}

	@override
	Widget build(BuildContext context) {
		return BottomAppBar(
			shape: const CircularNotchedRectangle(),
			notchMargin: 8,
			color: AppColors.surface,
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						IconButton(
							onPressed: onHome,
							icon: Icon(Icons.home, color: _colorFor(0)),
						),
						IconButton(
							onPressed: onRecipe,
							icon: Icon(Icons.restaurant_menu, color: _colorFor(1)),
						),
						const SizedBox(width: 48),
						IconButton(
							onPressed: onShopping,
							icon: Icon(Icons.shopping_cart_outlined, color: _colorFor(3)),
						),
						IconButton(
							onPressed: onNotifications,
							icon: Icon(Icons.notifications_none, color: _colorFor(4)),
						),
					],
				),
			),
		);
	}
}
