import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/l10n_keys.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    service.loadLists();
  }

  @override
  Widget build(BuildContext context) {
    final lists = service.lists;
    final hasLists = lists.isNotEmpty;
    final totalItems = lists.fold<int>(0, (sum, item) => sum + item.itemCount);
    final completedItems = lists.fold<int>(
      0,
      (sum, item) => sum + item.completedCount,
    );
    final pendingItems = (totalItems - completedItems).clamp(0, totalItems);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MainFab(
        onPressed: () => _openScreen(const PantryScreen()),
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 3,
        onHome: () => _openScreen(const HomeScreen()),
        onRecipe: () => _openScreen(const RecipeScreen()),
        onShopping: () => _openScreen(const ShoppingScreen()),
        onNotifications: () => _openScreen(const NotificationScreen()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: BackHeader(
                title: context.tr('Danh sách mua sắm'),
                trailing: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _openAddListSheet,
                    icon: const Icon(Icons.add),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: hasLists
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _buildOverviewCard(
                          totalLists: lists.length,
                          pendingItems: pendingItems,
                          completedItems: completedItems,
                        ),
                        const SizedBox(height: 14),
                        ...lists.map(_buildListTile),
                      ],
                    )
                  : EmptyState(
                      title: context.tr('Chưa có danh sách'),
                      message: context.tr(
                        'Nhấn dấu + để tạo danh sách mua sắm.',
                      ),
                      icon: Icons.shopping_cart_outlined,
                      actionLabel: context.tr('Tạo danh sách'),
                      onAction: _openAddListSheet,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required int totalLists,
    required int pendingItems,
    required int completedItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, AppColors.surface],
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Tổng quan tuần này'),
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    '$totalLists danh sách • $pendingItems cần mua • $completedItems đã mua',
                  ),
                  style: AppTextStyles.caption.copyWith(
                    fontStyle: FontStyle.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final pending = (list.itemCount - list.completedCount).clamp(
      0,
      list.itemCount,
    );
    final progress = list.itemCount == 0
        ? 0.0
        : list.completedCount / list.itemCount;
    final isDone = list.itemCount > 0 && list.completedCount == list.itemCount;
    final doneText = context.trKey(
      L10nKeys.shoppingCompletedProgress,
      params: {'completed': list.completedCount, 'total': list.itemCount},
    );
    return Dismissible(
      key: ValueKey(list.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.red, size: 32),
      ),
      onDismissed: (_) {
        service.deleteList(list.id);
        showTopSnackBar(context, context.tr('Đã xóa danh sách mua sắm!'));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openListDetail(list),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDone ? Icons.task_alt : Icons.event_note,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(list.name, style: AppTextStyles.subtitle),
                          const SizedBox(height: 3),
                          Text(
                            context.tr(dateText),
                            style: AppTextStyles.caption.copyWith(
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success.withOpacity(0.14)
                            : AppColors.warning.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isDone
                            ? context.tr('Hoàn tất')
                            : context.tr('Đang mua'),
                        style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.normal,
                          color: isDone ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.trKey(
                    L10nKeys.shoppingListMeta,
                    params: {
                      'date': dateText,
                      'count': list.itemCount,
                      'doneText': doneText,
                    },
                  ),
                  style: AppTextStyles.caption.copyWith(
                    fontStyle: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.surfaceSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      context.tr('$pending còn lại'),
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.normal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
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
      MaterialPageRoute(builder: (_) => ShoppingListDetailScreen(list: list)),
    );
  }

  void _openScreen(Widget screen) {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}

class _AddShoppingListSheet extends StatefulWidget {
  final ShoppingService service;

  const _AddShoppingListSheet({required this.service});

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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickedDay = DateTime(picked.year, picked.month, picked.day);
      if (pickedDay.isBefore(today)) {
        showTopSnackBar(
          context,
          context.tr('Không thể chọn ngày hết hạn nhỏ hơn ngày hiện tại.'),
          isError: true,
        );
        return;
      }
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.service.createList(name: name, planDate: _selectedDate);
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
