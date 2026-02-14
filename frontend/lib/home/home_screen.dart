import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/features/recipe/recipe_screen.dart';
import '../core/storage/token_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/l10n/app_localizations.dart';
import '../features/notification/notification_screen.dart';
import '../features/pantry/pantry_screen.dart';
import '../features/pantry/pantry_service.dart';
import '../features/shopping/shopping_screen.dart';
import '../features/navigation/main_bottom_nav.dart';
import '../features/settings/settings_screen.dart';
import '../features/recipe/today/today_instruction_screen.dart';
import '../features/recipe/today/today_service.dart';
import 'home_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fullName;
  final PantryService _pantryService = PantryService.instance;
  final HomeAiService _homeService = HomeAiService.instance;
  int _expiringSoonCount = 0;
  int _expiredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNameFromToken();
    _pantryService.addListener(_onPantryChanged);
    _pantryService.loadItems();
    _homeService.addListener(_onHomeChanged);
    _homeService.load();
  }

  @override
  void dispose() {
    _pantryService.removeListener(_onPantryChanged);
    _homeService.removeListener(_onHomeChanged);
    super.dispose();
  }

  void _onPantryChanged() {
    if (!mounted) return;
    setState(() {
      _expiringSoonCount = _pantryService.expiringSoonCount;
      _expiredCount = _pantryService.expiredCount;
    });
  }

  void _onHomeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadNameFromToken() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    final name = _readJwtClaim(token, 'unique_name');
    if (!mounted) return;
    setState(() => fullName = name);
  }

  String? _readJwtClaim(String token, String claimKey) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = _decodeBase64Url(parts[1]);
    if (payload == null) return null;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data[claimKey] is String) {
        final value = data[claimKey] as String;
        return value.trim().isEmpty ? null : value;
      }
    } catch (_) {}
    return null;
  }

  String? _decodeBase64Url(String input) {
    try {
      final normalized = base64Url.normalize(input);
      return utf8.decode(base64Url.decode(normalized));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MainFab(onPressed: () => _openScreen(const PantryScreen())),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 0,
        onHome: () => _openScreen(const HomeScreen()),
        onRecipe: () => _openScreen(const RecipeScreen()),
        onShopping: () => _openScreen(const ShoppingScreen()),
        onNotifications: () => _openScreen(const NotificationScreen()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(fullName),
              const SizedBox(height: 20),
              Text(context.tr('Món bạn có thể nấu'),
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: _buildHomeRecipeSection(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: context.tr('Sắp hết hạn'),
                      value: '$_expiringSoonCount',
                      background: AppColors.surfaceSoft,
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      label: context.tr('Đã hết hạn'),
                      value: '$_expiredCount',
                      background: AppColors.surface,
                      icon: Icons.error_outline,
                      iconColor: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(context.tr('Mẹo bảo quản thực phẩm (Daily Tips)'),
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              _buildHomeTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeRecipeSection() {
    if (_homeService.isLoading && _homeService.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homeService.recipes.isEmpty) {
      final message = _homeService.error?.replaceFirst('Exception: ', '')
          ?? context.tr('Chưa có kế hoạch');
      return Center(
        child: Text(message, style: AppTextStyles.caption),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _homeService.recipes.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, index) {
        final recipe = _homeService.recipes[index];
        return GestureDetector(
          onTap: () => _handleRecipeTap(recipe),
          child: _buildAiRecipeCard(
            title: recipe.name,
            tags: recipe.tags,
            time: '${recipe.timeMinutes} Min',
            count: recipe.ingredientCount,
          ),
        );
      },
    );
  }

  Future<void> _handleRecipeTap(HomeAiRecipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Nấu món này?')),
        content: Text(context.tr('Bạn có muốn nấu món này không?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('Huỷ')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('Nấu món này')),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final todayRecipe = _mapToTodayRecipe(recipe);
    final missing = _findMissingIngredients(todayRecipe.ingredients);
    if (missing.isNotEmpty) {
      await TodayService.instance.addMissingIngredients(missing);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Đã thêm nguyên liệu thiếu vào danh sách mua sắm.'))),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TodayInstructionScreen(recipe: todayRecipe),
      ),
    );
  }

  TodayRecipe _mapToTodayRecipe(HomeAiRecipe recipe) {
    final ingredients = recipe.ingredients
        .map((name) => TodayIngredient(name: name, quantity: 1, unit: ''))
        .toList();
    return TodayRecipe(
      name: recipe.name,
      timeMinutes: recipe.timeMinutes,
      imageUrl: '',
      ingredients: ingredients,
      missingIngredients: const [],
    );
  }

  List<TodayIngredient> _findMissingIngredients(List<TodayIngredient> requiredItems) {
    final pantryNames = _pantryService.items
        .map((item) => _normalizeName(item.name))
        .where((name) => name.isNotEmpty)
        .toSet();

    final missing = <TodayIngredient>[];
    for (final item in requiredItems) {
      final normalized = _normalizeName(item.name);
      if (normalized.isEmpty) continue;
      if (!pantryNames.contains(normalized)) {
        missing.add(item);
      }
    }

    return missing;
  }

  String _normalizeName(String value) {
    final trimmed = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in trimmed.runes) {
      final char = String.fromCharCode(rune);
      if (_isLetterOrDigit(char)) {
        buffer.write(char);
      } else {
        buffer.write(' ');
      }
    }
    final cleaned = buffer.toString();
    return cleaned.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).join(' ');
  }

  bool _isLetterOrDigit(String value) {
    final code = value.codeUnitAt(0);
    if (code >= 48 && code <= 57) return true;
    if (code >= 65 && code <= 90) return true;
    if (code >= 97 && code <= 122) return true;
    if (code > 127) return true;
    return false;
  }

  Widget _buildHomeTipsSection() {
    if (_homeService.isLoading && _homeService.tips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homeService.tips.isEmpty) {
      final message = _homeService.error?.replaceFirst('Exception: ', '')
          ?? 'Hôm nay chưa có mẹo phù hợp.';
      return Text(message, style: AppTextStyles.caption);
    }

    return Column(
      children: _homeService.tips.map((tip) {
        final icon = _tipIcon(tip.category);
        final iconColor = _tipIconColor(tip.category);
        final background = _tipBackground(tip.category);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTipCard(
            icon: icon,
            title: tip.title,
            message: tip.message,
            iconBackground: background,
            iconColor: iconColor,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(String? name) {
    final displayName = (name == null || name.trim().isEmpty)
      ? context.tr('Xin chào')
      : '${context.tr('Xin chào')} $name';

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.person, color: AppColors.surface),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(displayName, style: AppTextStyles.subtitle),
              const SizedBox(height: 4),
                Text(context.tr('Chào mừng trở lại'),
                  style: AppTextStyles.caption),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  static Widget _buildAiRecipeCard({
    required String title,
    required List<String> tags,
    required String time,
    required int count,
  }) {
    return SizedBox(
      width: 200,
      height: 210,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFDE68A), Color(0xFFFFEDD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text('AI gợi ý', style: AppTextStyles.caption),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'từ tủ lạnh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(time, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Nguyên liệu chính',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(tag, style: AppTextStyles.caption),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('$count nguyên liệu', style: AppTextStyles.caption),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('Dễ', style: AppTextStyles.caption),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatCard({
    required String label,
    required String value,
    required Color background,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.title),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  static Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String message,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.body),
              ],
            ),
          )
        ],
      ),
    );
  }

  static IconData _tipIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Icons.apple_outlined;
      case 'vegetable':
        return Icons.eco_outlined;
      case 'meat':
        return Icons.set_meal_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  static Color _tipIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return AppColors.warning;
      case 'vegetable':
        return AppColors.success;
      case 'meat':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  static Color _tipBackground(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return const Color(0xFFFFF4CC);
      case 'vegetable':
        return AppColors.primarySoft;
      case 'meat':
        return AppColors.surfaceSoft;
      default:
        return AppColors.surface;
    }
  }

  void _openScreen(Widget screen) {
    if (!mounted) return;
    if (screen is HomeScreen) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
