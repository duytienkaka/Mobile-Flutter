import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';
import 'package:frontend/features/shopping/shopping_list_detail_screen.dart';
import 'package:frontend/features/shopping/shopping_screen.dart';
import 'package:frontend/features/shopping/shopping_service.dart';
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
        // Tabs row: no extra container, just the Row for visual consistency
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
        // ...existing code...
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
                  child: showLoading
                      ? const Center(child: CircularProgressIndicator())
                      : recipes.isEmpty
                          ? Center(
                              child: tabType == TodayTabType.near
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          context.tr('Chưa có kế hoạch'),
                                          style: AppTextStyles.caption,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.tr('Đang gợi ý 3 món ăn dinh dưỡng từ AI. Không phụ thuộc nguyên liệu trong tủ lạnh.'),
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      context.tr('Chưa có kế hoạch'),
                                      style: AppTextStyles.caption,
                                    ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recipes.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, index) => GestureDetector(
                                onTap: () =>
                                    _service.selectRecipe(tabType, index),
                                child: _buildRecipeCard(
                                  recipes[index],
                                  selectedIndex == index,
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
                      onPressed: recipes.isEmpty
                          ? null
                          : () => _service.loadTab(tabType, refresh: true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.black,
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
                            : const Color(0xFFD9D9D9),
                        foregroundColor:
                            hasRecipe ? AppColors.black : AppColors.surface,
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
    if (tab == TodayTabType.full && recipe.missingIngredients.isNotEmpty) {
      // Nếu là tab "Nguyên liệu đã đủ" nhưng vẫn còn nguyên liệu thiếu (trường hợp hiếm),
      // thì chuyển sang shopping list và mở list đầu tiên (nếu có)
      // Đầu tiên, đảm bảo đã thêm các nguyên liệu thiếu vào shopping list
      await TodayService.instance.addMissingIngredients(recipe.missingIngredients);
      // Load lại danh sách shopping list
      final shoppingService = await _getShoppingService(context);
      await shoppingService.loadLists();
      if (!mounted) return;
      if (shoppingService.lists.isNotEmpty) {
        final list = shoppingService.lists.first;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoppingListDetailScreen(list: list),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoppingScreen(),
          ),
        );
      }
      showTopSnackBar(context, 'Đã thêm thực phẩm cần mua vào giỏ hàng!', isError: false);
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TodayConfirmScreen(recipe: recipe),
        ),
      );
    }
  }

  // Helper để lấy ShoppingService instance từ context hoặc singleton
  Future<ShoppingService> _getShoppingService(BuildContext context) async {
    // Nếu đã có instance thì trả về luôn
    return ShoppingService.instance;
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
    return Stack(
      children: [
        RecipeCard(
          imageUrl: recipe.imageUrl,
          title: recipe.name,
          tags: tags,
          time: timeLabel,
          count: recipe.ingredients.length,
          showImage: false,
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
}
