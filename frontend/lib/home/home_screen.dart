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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fullName;
  final PantryService _pantryService = PantryService.instance;
  int _expiringSoonCount = 0;
  int _expiredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNameFromToken();
    _pantryService.addListener(_onPantryChanged);
    _pantryService.loadItems();
  }

  @override
  void dispose() {
    _pantryService.removeListener(_onPantryChanged);
    super.dispose();
  }

  void _onPantryChanged() {
    if (!mounted) return;
    setState(() {
      _expiringSoonCount = _pantryService.expiringSoonCount;
      _expiredCount = _pantryService.expiredCount;
    });
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
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=800&q=80',
                      title: 'Hawaiian Chicken Smoked\nPizza',
                      tags: const ['Mozzarella', 'Salame', '+8'],
                      time: '40 Min',
                      count: '12',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=800&q=80',
                      title: 'Hawaiian Chicken\nPizza',
                      tags: const ['Mozzarella', 'Salame', '+8'],
                      time: '40 Min',
                      count: '12',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
                      title: 'Grilled Chicken\nSalad',
                      tags: const ['Lettuce', 'Chicken', '+5'],
                      time: '25 Min',
                      count: '8',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=800&q=80',
                      title: 'Pasta Carbonara',
                      tags: const ['Pasta', 'Bacon', '+4'],
                      time: '30 Min',
                      count: '10',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=800&q=80',
                      title: 'Avocado Toast',
                      tags: const ['Avocado', 'Egg', '+2'],
                      time: '15 Min',
                      count: '6',
                    ),
                  ],
                ),
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
              _buildTipCard(
                icon: Icons.eco_outlined,
                title: context.tr('Bảo quản rau xanh'),
                message: context.tr(
                  'Rau cần độ ẩm, bọc trong khăn giấy ẩm để giữ tươi lâu.'),
                iconBackground: AppColors.primarySoft,
                iconColor: AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildTipCard(
                icon: Icons.set_meal_outlined,
                title: context.tr('Giữ thịt tươi lâu'),
                message: context.tr(
                  'Chia nhỏ thịt trước khi cấp đông để dễ dùng.'),
                iconBackground: AppColors.surfaceSoft,
                iconColor: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
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

  static Widget _buildRecipeCard({
    required String imageUrl,
    required String title,
    required List<String> tags,
    required String time,
    required String count,
  }) {
    return SizedBox(
      width: 200,
      height: 210,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 88,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text('Pizza', style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tags[i], style: AppTextStyles.caption),
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.access_time,
                  size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(time, style: AppTextStyles.caption),
                const SizedBox(width: 12),
                Icon(Icons.list_alt,
                  size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(count, style: AppTextStyles.caption),
              ],
            )
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
