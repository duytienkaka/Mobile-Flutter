import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
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
                        child: Text('Shopping List',
                            style: AppTextStyles.title),
                      ),
                      IconButton(
                      onPressed: _openAddItemSheet,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('To Buy', style: AppTextStyles.subtitle),
                  const SizedBox(height: 10),
                  ...toBuyGroups.entries.expand(
                    (group) => [
                      if (showToBuyGroupHeader)
                        Text(group.key, style: AppTextStyles.subtitle),
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
                            'Completed ($completedCount items)',
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
                          Text(group.key, style: AppTextStyles.subtitle),
                        if (showCompletedGroupHeader) const SizedBox(height: 8),
                        ...group.value.map(_buildItemTile),
                        const SizedBox(height: 12),
                      ],
                    ),
                ],
              )
            : EmptyState(
                title: 'Danh sách trống',
                message: 'Nhấn dấu + để thêm món thủ công vào danh sách.',
                icon: Icons.shopping_cart_outlined,
                actionLabel: 'Thêm món',
                onAction: _openAddItemSheet,
              ),
      ),
    );
  }

  Future<void> _openAddItemSheet() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'pcs');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
            Text('Add item', style: AppTextStyles.title),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                      const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration:
                      const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final qty =
                        double.tryParse(qtyCtrl.text.trim()) ?? 1;
                      final unit = unitCtrl.text.trim().isEmpty
                          ? 'pcs'
                          : unitCtrl.text.trim();
                      await service.addManualItem(
                        name: name,
                        quantity: qty,
                        unit: unit,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
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
                Text(item.sourceDetail, style: AppTextStyles.caption),
                const Divider(height: 16, color: AppColors.border),
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
