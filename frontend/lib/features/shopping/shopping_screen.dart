import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../notification/notification_screen.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_screen.dart';
import 'shopping_list_detail_screen.dart';
import 'shopping_list_model.dart';
import 'shopping_service.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final ShoppingService service = ShoppingService.instance;

  @override
  void initState() {
    super.initState();
    service.addListener(_onChanged);
    service.loadLists();
  }

  @override
  void dispose() {
    service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lists = service.lists;
    final hasLists = lists.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
          MainFab(onPressed: () => _openScreen(const PantryScreen())),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 3,
        onHome: () => _openScreen(const HomeScreen()),
        onRecipe: () => _openScreen(const RecipeScreen()),
        onShopping: () => _openScreen(const ShoppingScreen()),
        onNotifications: () => _openScreen(const NotificationScreen()),
      ),
      body: SafeArea(
        child: hasLists
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('Danh sách mua sắm'),
                          style: AppTextStyles.title,
                        ),
                      ),
                      IconButton(
                        onPressed: _openAddListSheet,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...lists.map(_buildListTile),
                ],
              )
            : EmptyState(
                title: context.tr('Chưa có danh sách'),
                message: context.tr('Nhấn dấu + để tạo danh sách mua sắm.'),
                icon: Icons.shopping_cart_outlined,
                actionLabel: context.tr('Tạo danh sách'),
                onAction: _openAddListSheet,
              ),
      ),
    );
  }

  Future<void> _openAddListSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddShoppingListSheet(service: service),
    );
  }

  Widget _buildListTile(ShoppingListModel list) {
    final dateText = _formatDate(list.planDate);
    final doneText =
        '${list.completedCount}/${list.itemCount} ${context.tr('Đã hoàn thành')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _openListDetail(list),
        child: Row(
          children: [
            Icon(Icons.event_note, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(list.name, style: AppTextStyles.subtitle),
                  const SizedBox(height: 4),
                  Text(
                    '$dateText • ${list.itemCount} ${context.tr('món')} • $doneText',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  void _openListDetail(ShoppingListModel list) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingListDetailScreen(list: list),
      ),
    );
  }

  void _openScreen(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _AddShoppingListSheet extends StatefulWidget {
  final ShoppingService service;

  const _AddShoppingListSheet({
    required this.service,
  });

  @override
  State<_AddShoppingListSheet> createState() => _AddShoppingListSheetState();
}

class _AddShoppingListSheetState extends State<_AddShoppingListSheet> {
  late final TextEditingController _nameCtrl;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.service.createList(
        name: name,
        planDate: _selectedDate,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(_selectedDate);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('Tạo danh sách'), style: AppTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: context.tr('Tên danh sách')),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _saving ? null : _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(labelText: context.tr('Chọn ngày')),
              child: Text(dateText, style: AppTextStyles.subtitle),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(context.tr('Huỷ')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Tạo')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }
}
