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
  final int unreadCount;

  const MainBottomBar({
    super.key,
    required this.currentIndex,
    required this.onHome,
    required this.onRecipe,
    required this.onShopping,
    required this.onNotifications,
    this.unreadCount = 0,
  });

  Color _colorFor(int index) {
    return currentIndex == index
        ? AppColors.textPrimary
        : AppColors.textSecondary;
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
            Stack(
              children: [
                IconButton(
                  onPressed: onNotifications,
                  icon: Icon(Icons.notifications_none, color: _colorFor(4)),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
