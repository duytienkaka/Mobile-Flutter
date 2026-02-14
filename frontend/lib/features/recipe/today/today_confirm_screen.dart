import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
  final Set<String> _addedKeys = {};
  int _servings = 2;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final missingKeys = recipe.missingIngredients
      .map((item) => item.key)
      .toSet();
    final hasMissing = missingKeys.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Xác nhận nấu')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(recipe),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Nguyên liệu'), style: AppTextStyles.subtitle),
                  Text(
                    '${recipe.ingredients.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildIngredientList(recipe.ingredients, missingKeys),
              if (hasMissing) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addAllMissing,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add),
                  label: Text(context.tr('Thêm tất cả')),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ElevatedButton(
          onPressed: _saving ? null : _confirmCook,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('Bắt đầu nấu')),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(TodayRecipe recipe) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(recipe),
          const SizedBox(height: 14),
          Text(recipe.name, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            context.tr('Món gợi ý'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.auto_awesome, context.tr('Dễ')),
              const SizedBox(width: 10),
              _buildInfoChip(
                Icons.access_time,
                '${recipe.timeMinutes} Min',
              ),
              const SizedBox(width: 10),
              _buildInfoChip(Icons.local_fire_department, '384 kcal'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                context.tr('Số suất'),
                style: AppTextStyles.caption,
              ),
              const SizedBox(width: 10),
              _buildServingsControl(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(TodayRecipe recipe) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -18,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('AI gợi ý', style: AppTextStyles.caption),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildAvatarChip('32'),
                    const SizedBox(width: 6),
                    _buildAvatarChip('26'),
                    const SizedBox(width: 6),
                    _buildAvatarChip('12+'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Được nhiều người nấu'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }


  Widget _buildServingsControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildServingsButton(Icons.remove, () {
            if (_servings <= 1) return;
            setState(() => _servings -= 1);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('$_servings', style: AppTextStyles.caption),
          ),
          _buildServingsButton(Icons.add, () {
            setState(() => _servings += 1);
          }),
        ],
      ),
    );
  }

  Widget _buildServingsButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
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
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.name, style: AppTextStyles.body),
                  ),
                  Text(
                    _formatQuantity(item),
                    style: AppTextStyles.caption,
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
      return Icon(
        Icons.check_circle,
        size: 20,
        color: AppColors.success,
      );
    }

    return IconButton(
      onPressed: _saving ? null : () => _addSingleMissing(item),
      icon: const Icon(Icons.add_circle),
      color: AppColors.primary,
      iconSize: 22,
      tooltip: context.tr('Thêm vào mua sắm'),
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
    setState(() => _saving = true);
    try {
      await TodayService.instance.cookRecipe(widget.recipe, addMissing: false);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TodayInstructionScreen(recipe: widget.recipe),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSingleMissing(TodayIngredient item) async {
    setState(() => _saving = true);
    try {
      await TodayService.instance.addMissingIngredient(item);
      if (!mounted) return;
      setState(() => _addedKeys.add(item.key));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addAllMissing() async {
    setState(() => _saving = true);
    try {
      await TodayService.instance.addMissingIngredients(
        widget.recipe.missingIngredients,
      );
      if (!mounted) return;
      setState(() {
        _addedKeys.addAll(
          widget.recipe.missingIngredients.map((item) => item.key),
        );
      });
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
