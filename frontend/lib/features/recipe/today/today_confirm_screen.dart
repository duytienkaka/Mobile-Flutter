import 'package:flutter/material.dart';
import 'package:frontend/core/utils/pantry_scope.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../pantry/pantry_item_model.dart';
import '../../pantry/pantry_service.dart';
import '../../shopping/shopping_list_detail_screen.dart';
import '../../shopping/shopping_screen.dart';
import '../../shopping/shopping_service.dart';
import 'today_instruction_screen.dart';
import 'today_service.dart';

class TodayConfirmScreen extends StatefulWidget {
  final TodayRecipe recipe;

  const TodayConfirmScreen({super.key, required this.recipe});

  @override
  State<TodayConfirmScreen> createState() => _TodayConfirmScreenState();
}

class _TodayConfirmScreenState extends State<TodayConfirmScreen> {
  bool _saving = false;
  bool _scopeReady = false;
  final Set<String> _addedKeys = {};
  int _servings = 1;
  List<String> _missingKeys = [];

  @override
  void initState() {
    super.initState();
    _initializeScope();
  }

  Future<void> _initializeScope() async {
    await PantryScope.ensureInitialized();
    if (!mounted) return;
    setState(() => _scopeReady = true);
    _calculateMissing();
  }

  void _calculateMissing() {
    final pantryItems = PantryService.instance.items;
    final missingKeys = <String>[];

    for (final ing in widget.recipe.ingredients) {
      if (!PantryScope.isPantryManagedIngredient(ing.name)) continue;

      final requiredQty = ing.quantity * _servings;
      final availableQty = _sumAvailableInRequiredUnit(
        pantryItems: pantryItems,
        ingredientName: ing.name,
        requiredUnit: ing.unit,
      );

      if (availableQty < requiredQty) {
        missingKeys.add(ing.key);
      }
    }

    if (!mounted) return;
    setState(() => _missingKeys = missingKeys);
  }

  @override
  Widget build(BuildContext context) {
    if (!_scopeReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recipe = widget.recipe;
    final hasMissing = _missingKeys.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF4),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildTopHero(recipe),
            DraggableScrollableSheet(
              initialChildSize: 0.60,
              minChildSize: 0.60,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.60, 1.0],
              builder: (context, scrollController) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD0D5DD),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          recipe.name,
                          style: AppTextStyles.title.copyWith(
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildAvatarCluster(),
                            const Spacer(),
                            Text(
                              '126+ người đã thử',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF98A2B3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('Công thức gợi ý trong ngày'),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF98A2B3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatItem(Icons.restaurant, context.tr('Dễ')),
                            _buildStatItem(
                              Icons.access_time,
                              '${recipe.timeMinutes} min',
                            ),
                            _buildStatItem(
                              Icons.local_fire_department_outlined,
                              '384 kcal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              context.tr('Nguyên liệu'),
                              style: AppTextStyles.subtitle.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${recipe.ingredients.length}',
                              style: AppTextStyles.subtitle.copyWith(
                                color: const Color(0xFF98A2B3),
                              ),
                            ),
                            const Spacer(),
                            _buildServingsControl(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('Bạn cần bao nhiêu suất?'),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF98A2B3),
                          ),
                        ),
                        if (hasMissing) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _saving ? null : _addAllMissing,
                              icon: const Icon(Icons.playlist_add),
                              label: Text(context.tr('Thêm tất cả vào mua sắm')),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildIngredientList(recipe.ingredients, _missingKeys.toSet()),
                        const SizedBox(height: 12),
                        SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _confirmCook,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDE047),
                                foregroundColor: const Color(0xFF111827),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      context.tr('Nấu món này'),
                                      style: AppTextStyles.subtitle.copyWith(
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHero(TodayRecipe recipe) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      height: 232,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE6A7), Color(0xFFFFD089)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -12,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTopIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _buildTopIconButton(
                        icon: Icons.shopping_cart_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShoppingScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('Xác nhận nấu ăn'),
                      style: AppTextStyles.title.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7A5200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('Vuốt lên để mở toàn bộ nguyên liệu'),
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF7A5200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF374151), size: 20),
      ),
    );
  }

  Widget _buildAvatarCluster() {
    Widget avatar(Color color, String text) {
      return Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        avatar(const Color(0xFF9CA3AF), 'A'),
        Transform.translate(
          offset: const Offset(-12, 0),
          child: avatar(const Color(0xFF6B7280), 'B'),
        ),
        Transform.translate(
          offset: const Offset(-24, 0),
          child: avatar(const Color(0xFF4B5563), 'C'),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF4C400)),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildServingsControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildServingsButton(Icons.remove, () {
            if (_servings <= 1) return;
            setState(() => _servings -= 1);
            _calculateMissing();
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$_servings',
              style: AppTextStyles.subtitle.copyWith(fontSize: 18),
            ),
          ),
          _buildServingsButton(Icons.add, () {
            setState(() => _servings += 1);
            _calculateMissing();
          }),
        ],
      ),
    );
  }

  Widget _buildServingsButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 18, color: const Color(0xFF111827)),
      ),
    );
  }

  Widget _buildIngredientList(
    List<TodayIngredient> items,
    Set<String> missingKeys,
  ) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          missingKeys.contains(item.key)
                              ? context.tr('Cần mua thêm')
                              : context.tr('Đã có trong tủ'),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF98A2B3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatQuantity(_scaledIngredient(item)),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildIngredientAction(item, missingKeys),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildIngredientAction(
    TodayIngredient item,
    Set<String> missingKeys,
  ) {
    final isMissing = missingKeys.contains(item.key);
    final isAdded = _addedKeys.contains(item.key);

    if (!isMissing || isAdded) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.check,
          size: 18,
          color: AppColors.textMuted,
        ),
      );
    }

    return InkWell(
      onTap: _saving ? null : () => _addSingleMissing(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFFDE047),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.add,
          size: 20,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  String _formatQuantity(TodayIngredient item) {
    final qty = item.quantity.toStringAsFixed(
      item.quantity == item.quantity.roundToDouble() ? 0 : 1,
    );
    if (item.unit.trim().isEmpty) return qty;
    return '$qty ${item.unit}';
  }

  Future<void> _confirmCook() async {
    await PantryScope.ensureInitialized();
    setState(() => _saving = true);
    try {
      final scaledRecipe = _scaledRecipe();
      final pantryItems = PantryService.instance.items;
      final missing = <TodayIngredient>[];

      for (final ing in scaledRecipe.ingredients) {
        if (!PantryScope.isPantryManagedIngredient(ing.name)) continue;

        final availableQty = _sumAvailableInRequiredUnit(
          pantryItems: pantryItems,
          ingredientName: ing.name,
          requiredUnit: ing.unit,
        );

        if (availableQty < ing.quantity) {
          missing.add(ing);
        }
      }

      if (missing.isNotEmpty) {
        final shoppingService = ShoppingService.instance;
        await shoppingService.loadLists();
        final newList = await shoppingService.createList(
          name: scaledRecipe.name,
          planDate: DateTime.now(),
        );

        if (newList != null) {
          for (final ingredient in missing) {
            await shoppingService.addManualItem(
              listId: newList.id,
              name: ingredient.name,
              quantity: ingredient.quantity <= 0 ? 1 : ingredient.quantity,
              unit: ingredient.unit,
            );
          }
        } else {
          await TodayService.instance.addMissingIngredients(missing);
        }

        if (!mounted) return;
        showTopSnackBar(
          context,
          context.tr('Đã thêm nguyên liệu thiếu vào danh sách mua sắm.'),
          isError: false,
        );

        if (newList != null) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ShoppingListDetailScreen(list: newList),
            ),
          );
        } else {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ShoppingScreen()),
          );
        }
        return;
      }

      await TodayService.instance.cookRecipe(scaledRecipe, addMissing: false);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TodayInstructionScreen(
            recipe: scaledRecipe,
            servings: _servings,
          ),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        err.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSingleMissing(TodayIngredient item) async {
    await PantryScope.ensureInitialized();
    if (!PantryScope.isPantryManagedIngredient(item.name)) {
      return;
    }

    setState(() => _saving = true);
    try {
      await TodayService.instance.addMissingIngredient(_scaledIngredient(item));
      if (!mounted) return;
      setState(() => _addedKeys.add(item.key));
    } catch (err) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        err.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addAllMissing() async {
    await PantryScope.ensureInitialized();
    setState(() => _saving = true);
    try {
      final scaledMissing = widget.recipe.missingIngredients
          .where((item) => PantryScope.isPantryManagedIngredient(item.name))
          .map(_scaledIngredient)
          .toList();

      if (scaledMissing.isEmpty) {
        if (mounted) {
          showTopSnackBar(
            context,
            'Không có nguyên liệu thuộc phạm vi tủ lạnh cần thêm.',
            isError: false,
          );
        }
        return;
      }

      await TodayService.instance.addMissingIngredients(scaledMissing);
      if (!mounted) return;
      setState(() {
        _addedKeys.addAll(widget.recipe.missingIngredients.map((item) => item.key));
      });
    } catch (err) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        err.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TodayIngredient _scaledIngredient(TodayIngredient item) {
    return TodayIngredient(
      name: item.name,
      quantity: item.quantity * _servings,
      unit: item.unit,
    );
  }

  TodayRecipe _scaledRecipe() {
    return TodayRecipe(
      name: widget.recipe.name,
      timeMinutes: widget.recipe.timeMinutes,
      imageUrl: widget.recipe.imageUrl,
      ingredients: widget.recipe.ingredients.map(_scaledIngredient).toList(),
      missingIngredients: widget.recipe.missingIngredients.map(_scaledIngredient).toList(),
    );
  }

  double _sumAvailableInRequiredUnit({
    required List<PantryItemModel> pantryItems,
    required String ingredientName,
    required String requiredUnit,
  }) {
    var total = 0.0;
    for (final item in pantryItems) {
      if (item.name.toLowerCase() != ingredientName.toLowerCase()) {
        continue;
      }

      final converted = _convertQuantityOrZero(
        quantity: item.quantity,
        fromUnit: item.unit,
        toUnit: requiredUnit,
      );
      total += converted;
    }
    return total;
  }

  double _convertQuantityOrZero({
    required double quantity,
    required String fromUnit,
    required String toUnit,
  }) {
    final normalizedFrom = fromUnit.trim().toLowerCase();
    final normalizedTo = toUnit.trim().toLowerCase();

    if (normalizedFrom == normalizedTo) {
      return quantity;
    }

    final fromWeight = _weightFactor(normalizedFrom);
    final toWeight = _weightFactor(normalizedTo);
    if (fromWeight != null && toWeight != null) {
      return quantity * fromWeight / toWeight;
    }

    final fromVolume = _volumeFactor(normalizedFrom);
    final toVolume = _volumeFactor(normalizedTo);
    if (fromVolume != null && toVolume != null) {
      return quantity * fromVolume / toVolume;
    }

    return 0;
  }

  double? _weightFactor(String unit) {
    switch (unit) {
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        return 1000;
      case 'g':
      case 'gr':
      case 'gram':
      case 'grams':
        return 1;
      case 'mg':
        return 0.001;
      default:
        return null;
    }
  }

  double? _volumeFactor(String unit) {
    switch (unit) {
      case 'l':
      case 'lit':
      case 'liter':
      case 'litre':
        return 1000;
      case 'ml':
        return 1;
      default:
        return null;
    }
  }
}
