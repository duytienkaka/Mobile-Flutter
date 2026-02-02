import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/tab_filter_pill.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../notification/notification_screen.dart';
import '../pantry/pantry_screen.dart';
import '../shopping/shopping_screen.dart';
import 'planner/planner_tab.dart';

class RecipeScreen extends StatefulWidget {
	const RecipeScreen({super.key});

	@override
	State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
	int selectedTab = 0;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
			floatingActionButton:
					MainFab(onPressed: () => _openScreen(const PantryScreen())),
			bottomNavigationBar: MainBottomBar(
				currentIndex: 1,
				onHome: () => _openScreen(const HomeScreen()),
				onRecipe: () => _openScreen(const RecipeScreen()),
				onShopping: () => _openScreen(const ShoppingScreen()),
				onNotifications: () => _openScreen(const NotificationScreen()),
			),
			appBar: AppBar(
				backgroundColor: AppColors.background,
				automaticallyImplyLeading: false,
				title: Text('Recipe', style: AppTextStyles.title),
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						_centerTitle('Hôm nay ăn gì?'),
						const SizedBox(height: 10),
						Container(
							padding: const EdgeInsets.all(14),
							decoration: BoxDecoration(
								color: AppColors.black,
								borderRadius: BorderRadius.circular(18),
							),
							child: Column(
								children: [
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Expanded(
												child: TabFilterPill(
													label: 'Nguyên liệu\nđã đủ',
													selected: selectedTab == 0,
													onTap: () => setState(() => selectedTab = 0),
												),
											),
											const SizedBox(width: 8),
											Expanded(
												child: TabFilterPill(
													label: 'Nguyên liệu\n gần đủ',
													selected: selectedTab == 1,
													onTap: () => setState(() => selectedTab = 1),
												),
											),
											const SizedBox(width: 8),
											Expanded(
												child: TabFilterPill(
													label: 'Món ăn\n dinh dưỡng',
													selected: selectedTab == 2,
													onTap: () => setState(() => selectedTab = 2),
												),
											),
										],
									),
									const SizedBox(height: 12),
									Row(
										children: [
											Expanded(child: _buildAiCard()),
											const SizedBox(width: 10),
											Expanded(child: _buildAiCard()),
											const SizedBox(width: 10),
											Expanded(child: _buildAiCard()),
										],
									),
									const SizedBox(height: 12),
									Row(
										children: [
											Expanded(
												child: OutlinedButton(
													onPressed: () {},
													style: OutlinedButton.styleFrom(
														side: const BorderSide(color: AppColors.border),
													),
													child: const Text('Đổi món'),
												),
											),
											const SizedBox(width: 10),
											Expanded(
												child: PrimaryButton(
													label: 'Nấu món này',
													onPressed: () {},
												),
											),
										],
									),
								],
							),
						),
						const SizedBox(height: 18),
						_centerTitle('Kế hoạch bữa ăn'),
						const SizedBox(height: 10),
						Container(
							decoration: BoxDecoration(
								color: AppColors.surface,
								borderRadius: BorderRadius.circular(16),
								border: Border.all(color: AppColors.border),
							),
							child: SizedBox(
								height: 780,
								child: const PlannerTab(),
							),
						),
					],
				),
			),
		);
	}

	void _openScreen(Widget screen) {
		if (!mounted) return;
		Navigator.of(context).pushReplacement(
			MaterialPageRoute(builder: (_) => screen),
		);
	}

	Widget _buildAiCard() {
		return Container(
			padding: const EdgeInsets.all(10),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						height: 80,
						decoration: BoxDecoration(
							color: AppColors.surfaceSoft,
							borderRadius: BorderRadius.circular(10),
						),
					),
					const SizedBox(height: 6),
					Text('Món gợi ý', style: AppTextStyles.caption),
					const SizedBox(height: 4),
					Row(
						children: [
							const Icon(Icons.access_time,
								size: 12, color: AppColors.textMuted),
							const SizedBox(width: 4),
							Text('40’', style: AppTextStyles.caption),
							const SizedBox(width: 8),
							const Icon(Icons.list_alt,
								size: 12, color: AppColors.textMuted),
							const SizedBox(width: 4),
							Text('12', style: AppTextStyles.caption),
						],
					),
				],
			),
		);
	}

	Widget _centerTitle(String text) {
		return Center(child: Text(text, style: AppTextStyles.subtitle));
	}
}