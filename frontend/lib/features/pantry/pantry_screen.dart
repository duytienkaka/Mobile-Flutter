import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/l10n_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/ingredient_card.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../home/home_screen.dart';
import '../navigation/main_bottom_nav.dart';
import '../notification/notification_screen.dart';
import '../recipe/recipe_screen.dart';
import '../shopping/shopping_screen.dart';
import 'pantry_item_model.dart';
import 'pantry_service.dart';

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

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

const List<String> _categoryKeys = [
  'vegetable',
  'fruit',
  'meat',
  'leftover',
  'other',
];

List<_CategoryOption> _buildCategoryOptions(BuildContext context) {
  return [
    _CategoryOption('all', context.tr('All')),
    _CategoryOption('vegetable', context.tr('Vegetables')),
    _CategoryOption('fruit', context.tr('Fruit')),
    _CategoryOption('meat', context.tr('Meat')),
    _CategoryOption('leftover', context.tr('Thức ăn cũ')),
    _CategoryOption('other', context.tr('Khác')),
  ];
}

class _PantryScreenState extends State<PantryScreen> {
  Future<void> _scanBarcode() async {
    String? barcode;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final value =
                      capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                  if (value == null || value.isEmpty) return;
                  barcode = value;
                  Navigator.of(context).pop();
                },
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 56,
                left: 24,
                right: 24,
                child: Text(
                  'Canh ma vach vao khung de quet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (barcode == null) return;

    final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
    final response = await http.get(Uri.parse(url));
    String? productName;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1 && data['product'] != null) {
        productName = data['product']['product_name'] ?? '';
      }
    }

    final nameCtrl = TextEditingController(text: productName ?? '');
    final qtyCtrl = TextEditingController(text: '1');
    DateTime? expiredAt;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Thêm sản phẩm',
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(controller: nameCtrl, label: 'Tên sản phẩm'),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: qtyCtrl,
                        label: 'Số lượng',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                expiredAt == null
                                    ? 'Chọn hạn sử dụng'
                                    : 'HSD: ${expiredAt!.day}/${expiredAt!.month}/${expiredAt!.year}',
                                style: AppTextStyles.body.copyWith(
                                  color: expiredAt == null
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setLocalState(() => expiredAt = picked);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Huỷ'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('Thêm'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final name = nameCtrl.text.trim();
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1;
    if (name.isEmpty) return;

    // Kiểm tra trùng tên + hạn sử dụng
    final PantryItemModel? existing = _service.items.firstWhereOrNull(
      (item) =>
          item.name.toLowerCase() == name.toLowerCase() &&
          ((item.expiredAt == null && expiredAt == null) ||
              (item.expiredAt != null &&
                  expiredAt != null &&
                  item.expiredAt!.year == expiredAt!.year &&
                  item.expiredAt!.month == expiredAt!.month &&
                  item.expiredAt!.day == expiredAt!.day)),
    );
    if (existing != null) {
      await _service.updateItem(
        id: existing.id,
        name: existing.name,
        category: existing.category,
        quantity: existing.quantity + qty,
        unit: existing.unit,
        expiredAt: existing.expiredAt,
      );
    } else {
      await _service.createItem(
        name: name,
        category: '',
        quantity: qty,
        unit: '',
        expiredAt: expiredAt,
      );
    }
    _service.loadItems();
    showTopSnackBar(context, 'Đã thêm sản phẩm vào tủ lạnh!', isError: false);
  }

  bool _hasShownMissingInfoSnackbar = false;
  final PantryService _service = PantryService.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedCategory = 0;
  bool _sortByNameAsc = false;

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
      floatingActionButton: FloatingActionButton(
        heroTag: 'pantry_action',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        tooltip: 'Thêm hoặc quét',
        onPressed: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Nhập thủ công'),
                  onTap: () => Navigator.pop(context, 'manual'),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Quét barcode'),
                  onTap: () => Navigator.pop(context, 'scan'),
                ),
              ],
            ),
          );
          if (result == 'manual') {
            _openIngredientForm(context);
          } else if (result == 'scan') {
            _scanBarcode();
          }
        },
        child: const Icon(Icons.add, size: 32),
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
                      context.tr('Tủ lạnh'),
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
                  const SizedBox(width: 8),
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
                      onPressed: () => _confirmClearAll(context),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      color: AppColors.danger,
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
                      onPressed: () {
                        setState(() => _sortByNameAsc = !_sortByNameAsc);
                      },
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
                separatorBuilder: (_, _) => const SizedBox(width: 10),
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

    // Đưa các item thiếu thông tin lên đầu
    final filtered = items.where((item) {
      final name = item.name.toLowerCase();
      final matchQuery = query.isEmpty || name.contains(query);
      final itemCategory = _normalizeCategoryKey(item.category);
      final matchCategory = categoryKey == 'all' || itemCategory == categoryKey;
      return matchQuery && matchCategory;
    }).toList();

    // Đưa các item thiếu thông tin lên đầu
    filtered.sort((a, b) {
      bool aMissing =
          a.quantity == 0 || a.unit.trim().isEmpty || a.category.trim().isEmpty;
      bool bMissing =
          b.quantity == 0 || b.unit.trim().isEmpty || b.category.trim().isEmpty;
      if (aMissing && !bMissing) return -1;
      if (!aMissing && bMissing) return 1;
      if (_sortByNameAsc) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasMissing = filtered.any(
        (item) =>
            item.quantity == 0 ||
            item.unit.trim().isEmpty ||
            item.category.trim().isEmpty,
      );
      if (hasMissing && !_hasShownMissingInfoSnackbar) {
        _hasShownMissingInfoSnackbar = true;
        showTopSnackBar(
          context,
          context.tr('Một số nguyên liệu cần điền đủ thông tin!'),
          isError: false,
        );
      }
      if (!hasMissing && _hasShownMissingInfoSnackbar) {
        _hasShownMissingInfoSnackbar = false;
      }
    });

    return filtered;
  }

  String _formatQuantity(PantryItemModel item) {
    final amount = item.quantity % 1 == 0
      ? item.quantity.toInt().toString()
      : item.quantity.toStringAsFixed(2);
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
      return context.trKey(L10nKeys.pantryExpiryDays, params: {'days': diff});
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
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.tr('Xoá nguyên liệu'),
      message: context.tr('Bạn chắc chắn muốn xoá?'),
      cancelText: context.tr('Huỷ'),
      confirmText: context.tr('Xoá'),
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed) return;
    try {
      await _service.deleteItem(item.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Không thể xoá'))));
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    if (_service.items.isEmpty) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.tr('Dọn tủ lạnh'),
      message: context.tr('Xoá toàn bộ nguyên liệu trong tủ lạnh?'),
      cancelText: context.tr('Huỷ'),
      confirmText: context.tr('Xoá hết'),
      isDanger: true,
      icon: Icons.delete_sweep_outlined,
    );

    if (!confirmed) return;

    try {
      await _service.clearAllItems();
      if (!mounted) return;
        showTopSnackBar(
          context,
          context.tr('Đã dọn toàn bộ tủ lạnh'),
          isError: false,
        );
    } catch (_) {
      if (!mounted) return;
        showTopSnackBar(
          context,
          context.tr('Không thể dọn tủ lạnh'),
          isError: true,
        );
    }
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ScanOverlay extends StatefulWidget {
  const _ScanOverlay();

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanOverlayPainter(progress: _controller),
      willChange: true,
      child: const SizedBox.expand(),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Animation<double> progress;

  _ScanOverlayPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    final frameWidth = size.width * 0.78;
    final frameHeight = frameWidth * 0.58;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    final background = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(16)),
      );
    final overlayPath = Path.combine(PathOperation.difference, background, cutout);
    canvas.drawPath(overlayPath, overlayPaint);

    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(16)),
      framePaint,
    );

    final cornerPaint = Paint()
      ..color = const Color(0xFF5BE37D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    final left = frameRect.left;
    final right = frameRect.right;
    final top = frameRect.top;
    final bottom = frameRect.bottom;

    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    canvas.drawLine(Offset(right, top), Offset(right - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), cornerPaint);

    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerLength), cornerPaint);

    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLength, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), cornerPaint);

    final scanY = frameRect.top + 10 + progress.value * (frameRect.height - 20);
    final scanRect = Rect.fromLTWH(frameRect.left + 6, scanY - 1.2, frameRect.width - 12, 2.4);
    final scanPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x005BE37D), Color(0xFF5BE37D), Color(0x005BE37D)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(scanRect)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(scanRect.left, scanY),
      Offset(scanRect.right, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

String _normalizeCategoryKey(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'vegetables':
    case 'vegetable':
      return 'vegetable';
    case 'fruit':
      return 'fruit';
    case 'meat':
      return 'meat';
    case 'leftover':
    case 'leftover_food':
    case 'thuc_an_cu':
      return 'leftover';
    case 'bun_banh_trang':
    case 'noodle_rice_paper':
    case 'starch':
      return 'noodle_rice_paper';
    default:
      return normalized;
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
              initialValue: _categoryKey,
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
      showTopSnackBar(
        context,
        context.tr('Vui lòng nhập tên'),
        isError: true,
      );
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
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.tr('Xoá nguyên liệu'),
      message: context.tr('Bạn chắc chắn muốn xoá?'),
      cancelText: context.tr('Huỷ'),
      confirmText: context.tr('Xoá'),
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed || widget.item == null) return;
    setState(() => _saving = true);
    try {
      await widget.service.deleteItem(widget.item!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        context.tr('Không thể xoá'),
        isError: true,
      );
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
    final normalized = _normalizeCategoryKey(value);
    if (_categoryKeys.contains(normalized)) return normalized;
    return _categoryKeys.first;
  }

  String _normalizeCategoryKey(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'vegetables':
      case 'vegetable':
        return 'vegetable';
      case 'fruit':
        return 'fruit';
      case 'meat':
        return 'meat';
      case 'leftover':
      case 'leftover_food':
      case 'thuc_an_cu':
        return 'leftover';
      case 'bun_banh_trang':
      case 'noodle_rice_paper':
      case 'starch':
        return 'noodle_rice_paper';
      default:
        return normalized;
    }
  }

  String _categoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'vegetable':
        return context.tr('Vegetables');
      case 'fruit':
        return context.tr('Fruit');
      case 'meat':
        return context.tr('Meat');
      case 'leftover':
        return context.tr('Thức ăn cũ');
      case 'noodle_rice_paper':
        return context.tr('Bún/Bánh tráng');
      default:
        return key;
    }
  }
}
