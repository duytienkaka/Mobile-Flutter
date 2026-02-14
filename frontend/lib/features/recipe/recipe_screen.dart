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
	int selectedTab = 0;
	int selectedRecipeIndex = -1;

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
				title: Text(context.tr('Công thức'), style: AppTextStyles.title),
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						_centerTitle(context.tr('Hôm nay ăn gì?')),
						const SizedBox(height: 10),
						Column(
							children: [
								Row(
									children: [
										Expanded(
											child: _buildAiTab(
												label: context.tr('Nguyên liệu\nđã đủ'),
												selected: selectedTab == 0,
												onTap: () => setState(() => selectedTab = 0),
											),
										),
										Expanded(
											child: _buildAiTab(
												label: context.tr('Nguyên liệu\n gần đủ'),
												selected: selectedTab == 1,
												onTap: () => setState(() => selectedTab = 1),
											),
										),
										Expanded(
											child: _buildAiTab(
												label: context.tr('Món ăn\n dinh dưỡng'),
												selected: selectedTab == 2,
												onTap: () => setState(() => selectedTab = 2),
											),
										),
									],
								),
								Container(
									padding: const EdgeInsets.all(16),
									decoration: BoxDecoration(
										color: AppColors.black,
										borderRadius: const BorderRadius.vertical(
											bottom: Radius.circular(20),
										),
									),
									child: Column(
										children: [
											Container(
												padding: const EdgeInsets.all(12),
												decoration: BoxDecoration(
													color: const Color(0xFFD8DCF1),
													borderRadius: BorderRadius.circular(16),
												),
												child: SizedBox(
													height: 210,
													child: ListView.separated(
														scrollDirection: Axis.horizontal,
														itemCount: 5,
														separatorBuilder: (_, __) => const SizedBox(width: 12),
														itemBuilder: (_, index) => GestureDetector(
															onTap: () => setState(() => selectedRecipeIndex = index),
															child: _buildAiCard(
																selected: selectedRecipeIndex == index,
															),
														),
													),
												),
											),
											const SizedBox(height: 16),
											Row(
												children: [
													Expanded(
														child: OutlinedButton(
															onPressed: () {},
															style: OutlinedButton.styleFrom(
																backgroundColor: AppColors.surface,
																foregroundColor: AppColors.textPrimary,
																side: BorderSide(color: AppColors.border),
																padding:
																	const EdgeInsets.symmetric(vertical: 12),
																shape: RoundedRectangleBorder(
																	borderRadius: BorderRadius.circular(12),
																),
															),
															child: Text(context.tr('Đổi món')),
														),
													),
													const SizedBox(width: 12),
													Expanded(
														child: ElevatedButton(
															onPressed: () {},
															style: ElevatedButton.styleFrom(
																backgroundColor: selectedRecipeIndex >= 0
																	? AppColors.primary
																	: const Color(0xFFCFCFCF),
																foregroundColor: selectedRecipeIndex >= 0
																	? AppColors.black
																	: AppColors.surface,
																padding:
																	const EdgeInsets.symmetric(vertical: 12),
																shape: RoundedRectangleBorder(
																	borderRadius: BorderRadius.circular(12),
																),
															),
															child: Text(context.tr('Nấu món này')),
														),
													),
												],
											),
										],
									),
								),
							],
						),
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
		);
	}

	void _openScreen(Widget screen) {
		if (!mounted) return;
		Navigator.of(context).pushReplacement(
			MaterialPageRoute(builder: (_) => screen),
		);
	}

	Widget _buildAiCard({bool selected = false}) {
		return SizedBox(
			width: 170,
			child: Container(
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					color: AppColors.surface,
					borderRadius: BorderRadius.circular(18),
					border: Border.all(
						color: selected ? AppColors.primary : AppColors.border,
						width: selected ? 1.6 : 1,
					),
					boxShadow: selected
							? [
								BoxShadow(
									color: AppColors.shadow,
									blurRadius: 12,
									offset: const Offset(0, 8),
								),
							]
							: [],
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Container(
							height: 120,
							decoration: BoxDecoration(
								color: AppColors.surfaceSoft,
								borderRadius: BorderRadius.circular(14),
							),
						),
						const SizedBox(height: 10),
						Text(
							context.tr('Món gì đây'),
							style: AppTextStyles.subtitle.copyWith(
								fontWeight: FontWeight.w700,
							),
						),
						const SizedBox(height: 8),
						Row(
							children: [
								Icon(Icons.access_time,
									size: 12, color: AppColors.textMuted),
								const SizedBox(width: 4),
								Text('40’', style: AppTextStyles.caption),
								const SizedBox(width: 10),
								Icon(Icons.list_alt,
									size: 12, color: AppColors.textMuted),
								const SizedBox(width: 4),
								Text('12', style: AppTextStyles.caption),
							],
						),
					],
				),
			),
		);
	}

	Widget _buildAiTab({
		required String label,
		required bool selected,
		required VoidCallback onTap,
	}) {
		final textColor = selected ? AppColors.surface : AppColors.textSecondary;

		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 200),
				margin: EdgeInsets.only(top: selected ? 0 : 6),
				padding: const EdgeInsets.symmetric(vertical: 12),
				decoration: BoxDecoration(
					color: selected ? AppColors.black : const Color(0xFFD9D9D9),
					borderRadius: const BorderRadius.vertical(
						top: Radius.circular(22),
					),
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

  Widget _centerTitle(String text) {
    return Center(child: Text(text, style: AppTextStyles.subtitle));
  }
}
