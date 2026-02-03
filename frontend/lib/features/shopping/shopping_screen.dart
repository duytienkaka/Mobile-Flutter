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
import 'shopping_item_model.dart';
import 'shopping_service.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final ShoppingService service = ShoppingService.instance;
  bool showCompleted = true;

  @override
  void initState() {
    super.initState();
    service.addListener(_onChanged);
    service.loadItems();
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
    final hasItems = service.items.isNotEmpty;
    final toBuyGroups = service.groupedItems(completed: false);
    final completedGroups = service.groupedItems(completed: true);
    final showToBuyGroupHeader = toBuyGroups.length > 1;
    final showCompletedGroupHeader = completedGroups.length > 1;
    final completedCount = completedGroups.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

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
        child: hasItems
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.tr('Danh sách mua sắm'),
                            style: AppTextStyles.title),
                      ),
                      IconButton(
                      onPressed: _openAddItemSheet,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('Cần mua'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 10),
                  ...toBuyGroups.entries.expand(
                    (group) => [
                      if (showToBuyGroupHeader)
                        Text(context.tr(group.key),
                            style: AppTextStyles.subtitle),
                      if (showToBuyGroupHeader) const SizedBox(height: 8),
                      ...group.value.map(_buildItemTile),
                      const SizedBox(height: 12),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () =>
                        setState(() => showCompleted = !showCompleted),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${context.tr('Đã hoàn thành')} ($completedCount ${context.tr('món')})',
                            style: AppTextStyles.subtitle,
                          ),
                        ),
                        Icon(
                          showCompleted
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showCompleted)
                    ...completedGroups.entries.expand(
                      (group) => [
                        if (showCompletedGroupHeader)
                          Text(context.tr(group.key),
                              style: AppTextStyles.subtitle),
                        if (showCompletedGroupHeader) const SizedBox(height: 8),
                        ...group.value.map(_buildItemTile),
                        const SizedBox(height: 12),
                      ],
                    ),
                ],
              )
            : EmptyState(
                title: context.tr('Danh sách trống'),
                message: context.tr('Nhấn dấu + để thêm món thủ công vào danh sách.'),
                icon: Icons.shopping_cart_outlined,
                actionLabel: context.tr('Thêm món'),
                onAction: _openAddItemSheet,
              ),
      ),
    );
  }

  Future<void> _openAddItemSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddShoppingItemSheet(
        service: service,
      ),
    );
  }

  Widget _buildItemTile(ShoppingItemModel item) {
    final textStyle = item.isChecked
        ? AppTextStyles.subtitle.copyWith(
            decoration: TextDecoration.lineThrough,
            color: AppColors.textMuted,
          )
        : AppTextStyles.subtitle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isChecked,
            onChanged: (value) =>
                service.toggleChecked(item.id, value ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name} - ${item.quantity} ${item.unit}',
                  style: textStyle,
                ),
                const SizedBox(height: 4),
                Text(context.tr(item.sourceDetail),
                  style: AppTextStyles.caption),
                Divider(height: 16, color: AppColors.border),
              ],
            ),
          ),
        ],
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

class _AddShoppingItemSheet extends StatefulWidget {
  final ShoppingService service;

  const _AddShoppingItemSheet({
    required this.service,
  });

  @override
  State<_AddShoppingItemSheet> createState() => _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends State<_AddShoppingItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _qtyCtrl = TextEditingController(text: '1');
    _unitCtrl = TextEditingController(text: 'pcs');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final unit = _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim();
    setState(() => _saving = true);
    try {
      await widget.service.addManualItem(
        name: name,
        quantity: qty,
        unit: unit,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text(context.tr('Thêm món'), style: AppTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: context.tr('Tên món')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: context.tr('Số lượng')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitCtrl,
                  decoration: InputDecoration(labelText: context.tr('Đơn vị')),
                ),
              ),
            ],
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
                      : Text(context.tr('Thêm')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
