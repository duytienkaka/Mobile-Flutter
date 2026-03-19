import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/recipe_card.dart';
import 'today_confirm_screen.dart';
import 'today_service.dart';
import 'today_widgets.dart';

class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  final TodayService _service = TodayService.instance;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    // Tự động load cả hai tab khi app khởi động
    _service.loadTab(TodayTabType.full);
    _service.loadTab(TodayTabType.near);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tabType = _selectedTab == 0
        ? TodayTabType.full
        : TodayTabType.near;
    final recipes = tabType == TodayTabType.full
        ? _service.fullRecipes
        : _service.nearRecipes;
    final selectedIndex = _service.selectedIndex(tabType);
    final hasRecipe = selectedIndex >= 0;
    final showLoading = _service.isLoadingFor(tabType) && recipes.isEmpty;
    final tabError = _service.errorFor(tabType);

    if (tabError != null && tabError.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTopSnackBar(
          context,
          tabError.replaceFirst('Exception: ', ''),
          isError: true,
        );
      });
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TodayTabButton(
                label: context.tr('Nguyên liệu\nđã đủ'),
                selected: _selectedTab == 0,
                onTap: () {
                  setState(() => _selectedTab = 0);
                  _service.loadTab(TodayTabType.full);
                },
              ),
            ),
            Expanded(
              child: TodayTabButton(
                label: context.tr('Món ăn dinh dưỡng'),
                selected: _selectedTab == 1,
                onTap: () {
                  setState(() => _selectedTab = 1);
                  _service.loadTab(TodayTabType.near);
                },
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 260,
                  child: showLoading
                      ? const Center(child: CircularProgressIndicator())
                      : recipes.isEmpty
                          ? Center(
                              child: tabType == TodayTabType.full
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppColors.textMuted,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          context.tr('Số lượng thực phẩm Không đủ để đưa ra gợi ý!'),
                                          style: AppTextStyles.caption,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          context.tr('Đang gợi ý 3 món ăn dinh dưỡng từ AI. Không phụ thuộc nguyên liệu trong tủ lạnh.'),
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recipes.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, index) {
                                final recipe = recipes[index];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _service.selectRecipe(tabType, index),
                                      child: _buildRecipeCard(
                                        recipe,
                                        selectedIndex == index,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: recipes.isEmpty
                          ? null
                          : () => _service.loadTab(tabType, refresh: true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(context.tr('Đổi món')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleCook(tabType),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasRecipe
                            ? AppColors.primary
                            : AppColors.surfaceSoft,
                        foregroundColor:
                            hasRecipe ? AppColors.textPrimary : AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Future<void> _handleCook(TodayTabType tab) async {
    final recipe = _service.selectedRecipe(tab) ?? _buildFallbackRecipe();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TodayConfirmScreen(recipe: recipe),
      ),
    );
  }

  TodayRecipe _buildFallbackRecipe() {
    return const TodayRecipe(
      name: 'Goi cuon tom thit',
      timeMinutes: 35,
      imageUrl:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=1200&q=80',
      ingredients: [
        TodayIngredient(name: 'Tom', quantity: 200, unit: 'g'),
        TodayIngredient(name: 'Thit heo', quantity: 200, unit: 'g'),
        TodayIngredient(name: 'Banh trang', quantity: 10, unit: 'cai'),
        TodayIngredient(name: 'Bun tuoi', quantity: 200, unit: 'g'),
        TodayIngredient(name: 'Rau song', quantity: 1, unit: 'bo'),
      ],
      missingIngredients: [
        TodayIngredient(name: 'Banh trang', quantity: 10, unit: 'cai'),
        TodayIngredient(name: 'Rau song', quantity: 1, unit: 'bo'),
      ],
    );
  }

  Widget _buildRecipeCard(TodayRecipe recipe, bool selected) {
    final tags = _buildTags(recipe.ingredients);
    final timeLabel = '${recipe.timeMinutes} Min';
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final adjustedHeight = _adaptiveCardHeight(textScale);
    return Stack(
      children: [
        RecipeCard(
          imageUrl: recipe.imageUrl,
          title: recipe.name,
          tags: tags,
          time: timeLabel,
          count: recipe.ingredients.length,
          showImage: false,
          height: adjustedHeight,
        ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _buildTags(List<TodayIngredient> ingredients) {
    if (ingredients.isEmpty) return const [];
    final names = ingredients.map((e) => e.name).toList();
    if (names.length <= 3) return names;
    return [names[0], names[1], '+${names.length - 2}'];
  }

  double _adaptiveCardHeight(double textScale) {
    final scale = textScale.clamp(1.0, 1.6);
    final reduced = 240 - ((scale - 1.0) * 28);
    return reduced.clamp(214, 240).toDouble();
  }
}
