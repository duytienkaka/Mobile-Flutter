import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/features/recipe/recipe_screen.dart';
import 'package:frontend/features/settings/settings_service.dart';
import '../core/storage/token_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/l10n_keys.dart';
import '../core/widgets/app_dialogs.dart';
import '../features/notification/notification_screen.dart';
import '../features/pantry/pantry_screen.dart';
import '../features/pantry/pantry_service.dart';
import '../features/pantry/pantry_item_model.dart';
import '../features/shopping/shopping_screen.dart';
import '../features/navigation/main_bottom_nav.dart';
import '../features/settings/settings_screen.dart';
import '../features/recipe/today/today_confirm_screen.dart';
import '../features/recipe/today/today_service.dart';
import '../features/recipe/planner/planner_service.dart';
import 'home_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  String? fullName;
  String? _avatarUrl;
  final PantryService _pantryService = PantryService.instance;
  final HomeAiService _homeService = HomeAiService.instance;
  final PlannerService _plannerService = PlannerService.instance;

  @override
  void initState() {
    super.initState();
    _loadNameFromToken();
    _loadUserProfile();
    _homeService.addListener(_onHomeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureWeeklyPlan();
      _pantryService.loadItems();
      _homeService.load();
    });
  }

  Future<void> _ensureWeeklyPlan() async {
    try {
      final preferences = await SettingsService.getWeeklyPlanPreferences();
      await _plannerService.ensureWeeklyPlan(
        weeklyBudget: preferences.weeklyBudget,
        nutritionGoal: preferences.nutritionGoal,
      );
    } catch (_) {
      // Keep login/home flow smooth even when weekly auto-plan API is temporarily unavailable.
    }
  }

  @override
  void dispose() {
    _homeService.removeListener(_onHomeChanged);
    super.dispose();
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

  Future<void> _loadUserProfile() async {
    try {
      final profile = await SettingsService.getProfile();
      if (!mounted) return;
      setState(() {
        if (profile.fullName.trim().isNotEmpty) {
          fullName = profile.fullName;
        }
        _avatarUrl = profile.avatarUrl;
      });
    } catch (_) {
      // Keep token-based name fallback and initials when profile fetch fails.
    }
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
      floatingActionButton: MainFab(
        onPressed: () => _openScreen(const PantryScreen()),
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 0,
        onHome: () => _openScreen(const HomeScreen()),
        onRecipe: () => _openScreen(const RecipeScreen()),
        onShopping: () => _openScreen(const ShoppingScreen()),
        onNotifications: () => _openScreen(const NotificationScreen()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(fullName),
              const SizedBox(height: 20),
              Text(
                context.tr('Món bạn có thể nấu'),
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 12),
              SizedBox(height: 302, child: _buildHomeRecipeSection()),
              const SizedBox(height: 18),
              Text(
                context.tr('Sắp hết hạn'),
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 12),
              _buildExpiringSoonSection(),
              const SizedBox(height: 20),
              Text(
                context.tr('Mẹo bảo quản thực phẩm (Daily Tips)'),
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 12),
              _buildHomeTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeRecipeSection() {
    if (_homeService.recipes.isEmpty) {
      final message =
          _homeService.error?.replaceFirst('Exception: ', '') ??
          context.tr('Chưa có kế hoạch');
      return _buildSectionEmpty(
        title: context.tr('Chưa có món gợi ý'),
        message: message,
        icon: Icons.restaurant_menu,
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _homeService.recipes.length,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
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
  // Đã loại bỏ search bar và logic tìm kiếm công thức

  Widget _buildExpiringSoonSection() {
    final today = DateTime.now();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final sectionHeight = (98 + ((textScale - 1) * 28)).clamp(98, 132).toDouble();
    final expiringSoonItems = _pantryService.items.where((item) {
      final expiredAt = item.expiredAt;
      if (expiredAt == null) return false;
      final normalized = _normalizeDate(expiredAt);
      if (normalized.isBefore(_normalizeDate(today))) return false;
      return normalized.difference(_normalizeDate(today)).inDays < 4;
    }).toList();

    if (expiringSoonItems.isEmpty) {
      return _buildSectionEmpty(
        title: context.tr('Không có mục sắp hết hạn'),
        message: context.tr('Tất cả thực phẩm của bạn đang còn hạn sử dụng tốt.'),
        icon: Icons.check_circle_outline,
      );
    }

    return SizedBox(
      height: sectionHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: expiringSoonItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = expiringSoonItems[index];
          return _buildExpiringSoonCard(item);
        },
      ),
    );
  }

  Widget _buildExpiringSoonCard(PantryItemModel item) {
    final expiryDate = item.expiredAt ?? DateTime.now();
    final today = _normalizeDate(DateTime.now());
    final daysLeft = _normalizeDate(expiryDate).difference(today).inDays;

    final bool isUrgent = daysLeft <= 1;
    final bool isWarning = daysLeft == 2;

    final Color badgeBg = isUrgent
        ? const Color(0xFFFEE2E2)
        : (isWarning ? const Color(0xFFFFEDD5) : const Color(0xFFFFF4CC));
    final Color badgeText = isUrgent
        ? const Color(0xFFB42318)
        : (isWarning ? const Color(0xFFC2410C) : const Color(0xFF9A6700));
    final Color borderColor = isUrgent
        ? const Color(0xFFFECACA)
        : (isWarning ? const Color(0xFFFED7AA) : AppColors.border);
    final String statusText = isUrgent
        ? context.tr('Cần dùng ngay')
        : (isWarning ? context.tr('Sắp hết hạn') : context.tr('Nên dùng sớm'));
    final String dayText = daysLeft <= 0
        ? context.tr('Hết hạn hôm nay')
        : 'Còn $daysLeft ngày nữa';

    return GestureDetector(
      onTap: () => _openScreen(const PantryScreen()),
      child: Container(
        width: 232,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: badgeText,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: AppTextStyles.caption.copyWith(
                            color: badgeText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: badgeText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _handleRecipeTap(HomeAiRecipe recipe) async {
    final confirm = await showAppConfirmDialog(
      context: context,
      title: context.tr('Nấu món này?'),
      message: context.tr('Bạn có muốn nấu món này không?'),
      cancelText: context.tr('Huỷ'),
      confirmText: context.tr('Nấu món này'),
      icon: Icons.restaurant_menu_rounded,
    );

    if (!confirm || !mounted) return;

    final todayRecipe = _mapToTodayRecipe(recipe);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TodayConfirmScreen(recipe: todayRecipe),
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

  Widget _buildHomeTipsSection() {
    if (_homeService.isLoading && _homeService.tips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homeService.tips.isEmpty) {
      final message =
          _homeService.error?.replaceFirst('Exception: ', '') ??
          'Hôm nay chưa có mẹo phù hợp.';
      return _buildSectionEmpty(
        title: context.tr('Chưa có mẹo hôm nay'),
        message: message,
        icon: Icons.lightbulb_outline,
      );
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
        : context.trKey(L10nKeys.commonHelloName, params: {'name': name});

    final avatarImage = SettingsService.resolveAvatarUrl(_avatarUrl);
    final initials = (name == null || name.isEmpty) ? 'U' : name[0].toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySoft,
          backgroundImage: avatarImage != null ? NetworkImage(avatarImage) : null,
          child: avatarImage == null
              ? Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: AppTextStyles.subtitle),
              const SizedBox(height: 4),
              Text(
                context.tr('Chào mừng trở lại'),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  Widget _buildSectionEmpty({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAiRecipeCard({
    required String title,
    required List<String> tags,
    required String time,
    required int count,
  }) {
    final displayTags = tags.length <= 2
        ? tags
        : [tags[0], tags[1], '+${tags.length - 2}'];

    return SizedBox(
      width: 212,
      height: 282,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
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
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayTags.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, index) {
                      final tag = displayTags[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(tag, style: AppTextStyles.caption),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$count nguyên liệu',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('Dễ', style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
          ),
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
