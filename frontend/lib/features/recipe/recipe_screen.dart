import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/back_header.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../notification/notification_screen.dart';
import '../pantry/pantry_screen.dart';
import '../shopping/shopping_screen.dart';
import 'planner/planner_tab.dart';
import 'today/today_tab.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MainFab(
        onPressed: () => _openScreen(const PantryScreen()),
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 1,
        onHome: () => _openScreen(const HomeScreen()),
        onRecipe: () => _openScreen(const RecipeScreen()),
        onShopping: () => _openScreen(const ShoppingScreen()),
        onNotifications: () => _openScreen(const NotificationScreen()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: BackHeader(title: context.tr('Công thức')),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _centerTitle(context.tr('Hôm nay ăn gì?')),
                    const SizedBox(height: 10),
                    const TodayTab(),
                    const SizedBox(height: 18),
                    _centerTitle(context.tr('Kế hoạch bữa ăn')),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const PlannerTab(scrollable: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openScreen(Widget screen) {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _centerTitle(String text) {
    return Center(child: Text(text, style: AppTextStyles.subtitle));
  }
}
