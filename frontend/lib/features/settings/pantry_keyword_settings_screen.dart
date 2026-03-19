import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/pantry_scope.dart';
import '../../core/widgets/app_dialogs.dart';

class PantryKeywordSettingsScreen extends StatefulWidget {
  const PantryKeywordSettingsScreen({super.key});

  @override
  State<PantryKeywordSettingsScreen> createState() =>
      _PantryKeywordSettingsScreenState();
}

class _PantryKeywordSettingsScreenState
    extends State<PantryKeywordSettingsScreen> {
  bool _loading = true;
  List<PantryKeywordRule> _rules = const [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadRules();
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchCtrl.text.trim().toLowerCase();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _loadRules() async {
    await PantryScope.ensureInitialized();
    if (!mounted) return;
    setState(() {
      _rules = PantryScope.getRules();
      _loading = false;
    });
  }

  Future<void> _toggleRule(PantryKeywordRule rule, bool enabled) async {
    await PantryScope.setKeywordEnabled(rule.key, enabled);
    if (!mounted) return;
    setState(() {
      _rules = PantryScope.getRules();
    });
    _showMessage(
      enabled
          ? 'Đã loại "${rule.label}" khỏi phạm vi tủ lạnh.'
          : 'Đã cho phép "${rule.label}" đi qua phạm vi tủ lạnh.',
    );
  }

  Future<void> _deleteCustomRule(PantryKeywordRule rule) async {
    if (!rule.isCustom) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Xóa từ khóa',
      message: 'Bạn có chắc muốn xóa "${rule.label}" không?',
      cancelText: 'Huỷ',
      confirmText: 'Xóa',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed) return;
    final removed = await PantryScope.removeCustomKeyword(rule.key);
    if (!mounted) return;
    if (!removed) {
      _showMessage('Không thể xóa từ khóa này.', isError: true);
      return;
    }

    setState(() {
      _rules = PantryScope.getRules();
    });
    _showMessage('Đã xóa "${rule.label}".');
  }

  Future<void> _addKeyword() async {
    final keyword = await _showAddKeywordSheet();

    if (keyword == null) return;

    final rule = await PantryScope.addKeyword(keyword);
    if (rule == null) {
      if (!mounted) return;
      _showMessage('Từ khóa không hợp lệ.', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _rules = PantryScope.getRules();
    });
    _showMessage('Đã thêm từ khóa "${rule.label}".');
  }

  Future<String?> _showAddKeywordSheet() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle.noAnimation,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.kitchen_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thêm gia vị mặc định',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Từ khóa gia vị',
                    hintText: 'Ví dụ: nước tương, bơ lạt...',
                  ),
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) return;
                    Navigator.of(sheetContext).pop(trimmed);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final trimmed = controller.text.trim();
                          if (trimmed.isEmpty) return;
                          Navigator.of(sheetContext).pop(trimmed);
                        },
                        child: const Text('Thêm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _resetDefaults() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Khôi phục mặc định',
      message: 'Bạn có chắc muốn khôi phục danh sách gia vị mặc định không?',
      cancelText: 'Huỷ',
      confirmText: 'Khôi phục',
      icon: Icons.restore_rounded,
    );

    if (!confirmed) return;
    await PantryScope.resetToDefault();
    if (!mounted) return;
    _searchCtrl.clear();
    setState(() {
      _rules = PantryScope.getRules();
      _searchQuery = '';
    });
    _showMessage('Đã khôi phục danh sách mặc định.');
  }

  List<PantryKeywordRule> get _filteredRules {
    if (_searchQuery.isEmpty) return _rules;
    return _rules
        .where(
          (rule) => rule.label.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách gia vị mặc định'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _resetDefaults,
            tooltip: 'Khôi phục mặc định',
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Text(
                    'Bật để loại khỏi phạm vi tủ lạnh, tắt để xử lý như nguyên liệu bình thường.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Tìm từ khóa gia vị...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _addKeyword,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._filteredRules.map((rule) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              rule.label,
                              style: AppTextStyles.body,
                            ),
                          ),
                          if (rule.isCustom)
                            IconButton(
                              onPressed: () => _deleteCustomRule(rule),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Xóa từ khóa',
                            ),
                          Switch(
                            value: rule.enabled,
                            onChanged: (value) => _toggleRule(rule, value),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_filteredRules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Không tìm thấy từ khóa phù hợp.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
