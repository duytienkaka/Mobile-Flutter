import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.home_outlined, 0),
          _navItem(Icons.inventory_2_outlined, 1),
          _navItem(Icons.restaurant_menu, 2, isCenter: true),
          _navItem(Icons.shopping_cart_outlined, 3),
          _navItem(Icons.notifications_none, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, {bool isCenter = false}) {
    final selected = currentIndex == index;
    final bg = selected ? AppColors.black : Colors.transparent;
    final fg = selected ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: isCenter ? 46 : 40,
        height: isCenter ? 46 : 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}