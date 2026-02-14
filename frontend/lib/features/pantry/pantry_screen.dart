import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/ingredient_card.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../notification/notification_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';
import 'pantry_item_model.dart';
import 'pantry_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _CategoryOption {
  final String key;
  final String label;

  const _CategoryOption(this.key, this.label);
}

const List<String> _categoryKeys = ['vegetables', 'fruit', 'meat'];

List<_CategoryOption> _buildCategoryOptions(BuildContext context) {
  return [
    _CategoryOption('all', context.tr('All')),
    _CategoryOption('vegetables', context.tr('Vegetables')),
    _CategoryOption('fruit', context.tr('Fruit')),
    _CategoryOption('meat', context.tr('Meat')),
  ];
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _service = PantryService.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _service.loadItems();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategoryOptions(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MainFab(
        onPressed: () => _openScreen(context, const PantryScreen()),
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: -1,
        onHome: () => _openScreen(context, const HomeScreen()),
        onRecipe: () => _openScreen(context, const RecipeScreen()),
        onShopping: () => _openScreen(context, const ShoppingScreen()),
        onNotifications: () => _openScreen(context, const NotificationScreen()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('Fridge'),
                      style: AppTextStyles.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
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
                      onPressed: () => _openIngredientForm(context),
                      icon: const Icon(Icons.edit_note, size: 20),
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.tr('Search ingredient'),
                          hintStyle: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minHeight: 40,
                            minWidth: 44,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.tune),
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final selected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        categories[index].label,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.black
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: categories.length,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: _service,
                builder: (context, _) {
                  if (_service.isLoading && _service.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = _filteredItems(_service.items, categories);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr('Không có nguyên liệu'),
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => _openIngredientForm(context, item: item),
                        onLongPress: () => _confirmDelete(context, item),
                        child: IngredientCard(
                          name: item.name,
                          quantity: _formatQuantity(item),
                          expiry: _formatExpiry(item.expiredAt),
                          status: _formatStatus(context, item.expiredAt),
                          isExpired: _isExpired(item.expiredAt),
                          isWarning: _isWarning(item.expiredAt),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PantryItemModel> _filteredItems(
    List<PantryItemModel> items,
    List<_CategoryOption> categories,
  ) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final categoryKey = categories[_selectedCategory].key;

    return items.where((item) {
      final name = item.name.toLowerCase();
      final matchQuery = query.isEmpty || name.contains(query);
      final itemCategory = item.category.trim().toLowerCase();
      final matchCategory = categoryKey == 'all' || itemCategory == categoryKey;
      return matchQuery && matchCategory;
    }).toList();
  }

  String _formatQuantity(PantryItemModel item) {
    final amount = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    final unit = item.unit.trim();
    return unit.isEmpty ? amount : '$amount$unit';
  }

  String _formatExpiry(DateTime? date) {
    if (date == null) return 'HSD: --/--/--';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = (date.year % 100).toString().padLeft(2, '0');
    return 'HSD: $dd/$mm/$yy';
  }

  String _formatStatus(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final today = _normalizeDate(DateTime.now());
    final normalized = _normalizeDate(date);
    final diff = normalized.difference(today).inDays;
    if (diff < 0) return context.tr('Đã hết hạn');
    if (diff <= 3) return context.tr('Sắp hết hạn');
    return context.tr('Còn $diff ngày');
  }

  bool _isExpired(DateTime? date) {
    if (date == null) return false;
    final today = _normalizeDate(DateTime.now());
    return _normalizeDate(date).isBefore(today);
  }

  bool _isWarning(DateTime? date) {
    if (date == null) return false;
    final today = _normalizeDate(DateTime.now());
    final normalized = _normalizeDate(date);
    if (normalized.isBefore(today)) return false;
    return normalized.difference(today).inDays <= 3;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _openIngredientForm(
    BuildContext context, {
    PantryItemModel? item,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) =>
          _IngredientFormSheet(service: _service, item: item),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PantryItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Xoá nguyên liệu')),
        content: Text(context.tr('Bạn chắc chắn muốn xoá?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Huỷ')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(context.tr('Xoá')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _service.deleteItem(item.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Không thể xoá'))));
    }
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}

class _IngredientFormSheet extends StatefulWidget {
  final PantryService service;
  final PantryItemModel? item;

  const _IngredientFormSheet({required this.service, this.item});

  @override
  State<_IngredientFormSheet> createState() => _IngredientFormSheetState();
}

class _IngredientFormSheetState extends State<_IngredientFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  late String _categoryKey;
  DateTime? _expiredAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _qtyCtrl = TextEditingController(
      text: widget.item == null
          ? ''
          : (widget.item!.quantity % 1 == 0
                ? widget.item!.quantity.toInt().toString()
                : widget.item!.quantity.toString()),
    );
    _unitCtrl = TextEditingController(text: widget.item?.unit ?? '');
    _expiredAt = widget.item?.expiredAt;
    _categoryKey = _resolveInitialCategory(widget.item?.category);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item == null
                  ? context.tr('Thêm nguyên liệu')
                  : context.tr('Sửa nguyên liệu'),
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: context.tr('Tên nguyên liệu'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('Số lượng'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('Đơn vị'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryKey,
              items: _categoryKeys
                  .map(
                    (key) => DropdownMenuItem(
                      value: key,
                      child: Text(_categoryLabel(context, key)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _categoryKey = value);
              },
              decoration: InputDecoration(
                labelText: context.tr('Loại nguyên liệu'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _expiredAt == null
                            ? context.tr('Chọn ngày hết hạn')
                            : _formatExpiry(_expiredAt),
                        style: AppTextStyles.body,
                      ),
                    ),
                    if (_expiredAt != null)
                      IconButton(
                        onPressed: () => setState(() => _expiredAt = null),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.item != null)
                  TextButton(
                    onPressed: _saving ? null : _deleteItem,
                    child: Text(
                      context.tr('Xoá'),
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(context.tr('Huỷ')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saving ? null : _saveItem,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Lưu')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiredAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _expiredAt = picked);
  }

  Future<void> _saveItem() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Vui lòng nhập tên'))));
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final unit = _unitCtrl.text.trim();

    setState(() => _saving = true);
    try {
      if (widget.item == null) {
        await widget.service.createItem(
          name: name,
          category: _categoryKey,
          quantity: qty,
          unit: unit,
          expiredAt: _expiredAt,
        );
      } else {
        await widget.service.updateItem(
          id: widget.item!.id,
          name: name,
          category: _categoryKey,
          quantity: qty,
          unit: unit,
          expiredAt: _expiredAt,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Không thể lưu'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Xoá nguyên liệu')),
        content: Text(context.tr('Bạn chắc chắn muốn xoá?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Huỷ')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(context.tr('Xoá')),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.item == null) return;
    setState(() => _saving = true);
    try {
      await widget.service.deleteItem(widget.item!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Không thể xoá'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatExpiry(DateTime? date) {
    if (date == null) return 'HSD: --/--/--';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = (date.year % 100).toString().padLeft(2, '0');
    return 'HSD: $dd/$mm/$yy';
  }

  String _resolveInitialCategory(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (_categoryKeys.contains(normalized)) return normalized;
    return _categoryKeys.first;
  }

  String _categoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'vegetables':
        return context.tr('Vegetables');
      case 'fruit':
        return context.tr('Fruit');
      case 'meat':
        return context.tr('Meat');
      default:
        return key;
    }
  }
}
