import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/l10n_keys.dart';
import '../../core/utils/pantry_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/top_snackbar.dart';
import 'shopping_item_model.dart';
import 'shopping_list_model.dart';
import 'shopping_service.dart';
import '../pantry/pantry_service.dart';
import '../pantry/pantry_screen.dart';

class ShoppingListDetailScreen extends StatefulWidget {
	final ShoppingListModel list;

	const ShoppingListDetailScreen({
		super.key,
		required this.list,
	});

	@override
	State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
	static final Set<String> _syncedListIds = <String>{};

	bool _processing = false;
	bool showCompleted = false;
	late ShoppingService service;

	bool get _isSyncedToPantry => _syncedListIds.contains(widget.list.id);

	@override
	void initState() {
		super.initState();
		service = ShoppingService.instance;
		service.loadItemsForList(widget.list.id);
	}

	void _openAddItemSheet() {
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			builder: (_) => _AddShoppingItemSheet(
				service: service,
				listId: widget.list.id,
			),
		);
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
			appBar: AppBar(
				backgroundColor: AppColors.background,
				foregroundColor: AppColors.textPrimary,
				elevation: 0,
				title: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(widget.list.name, style: AppTextStyles.title),
						const SizedBox(height: 2),
						Text(
							_formatDate(widget.list.planDate),
							style: AppTextStyles.caption,
						),
					],
				),
			),
			floatingActionButton: FloatingActionButton(
				onPressed: _openAddItemSheet,
				backgroundColor: AppColors.primary,
				child: const Icon(Icons.add, color: Colors.white),
			),
			body: SafeArea(
				child: hasItems
						? ListView(
								padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
								children: [
									Text(context.tr('Cần mua'), style: AppTextStyles.subtitle),
									const SizedBox(height: 10),
									...toBuyGroups.entries.expand(
										(group) => [
											if (showToBuyGroupHeader)
												Text(context.tr(group.key), style: AppTextStyles.subtitle),
											if (showToBuyGroupHeader) const SizedBox(height: 8),
											...group.value.map((item) => _buildItemTile(item)),
											const SizedBox(height: 12),
										],
									),
									const SizedBox(height: 4),
									GestureDetector(
										onTap: () => setState(() => showCompleted = !showCompleted),
										child: Row(
											children: [
												Expanded(
													child: Text(
														context.trKey(
															L10nKeys.shoppingCompletedItems,
															params: {'count': completedCount},
														),
														style: AppTextStyles.subtitle,
													),
												),
												Icon(showCompleted ? Icons.expand_less : Icons.expand_more),
											],
										),
									),
									const SizedBox(height: 8),
									if (showCompleted)
										...completedGroups.entries.expand(
											(group) => [
												if (showCompletedGroupHeader)
													Text(context.tr(group.key), style: AppTextStyles.subtitle),
												if (showCompletedGroupHeader) const SizedBox(height: 8),
												...group.value.map((item) => _buildItemTile(item)),
												const SizedBox(height: 12),
											],
										),
									const SizedBox(height: 24),
									ElevatedButton.icon(
										onPressed: (_processing || _isSyncedToPantry) ? null : _onConfirmBuy,
										icon: _processing
												? const SizedBox(
														width: 18,
														height: 18,
														child: CircularProgressIndicator(strokeWidth: 2),
													)
												: Icon(_isSyncedToPantry ? Icons.lock : Icons.check_circle),
										label: Text(
												_isSyncedToPantry
													? context.tr('Đã thêm vào tủ lạnh')
													: context.tr('Xác nhận đã mua & thêm vào tủ lạnh'),
										),
										style: ElevatedButton.styleFrom(
											backgroundColor: _isSyncedToPantry ? AppColors.textMuted : AppColors.success,
											foregroundColor: Colors.white,
											padding: const EdgeInsets.symmetric(vertical: 14),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(14),
											),
										),
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

	Widget _buildItemTile(ShoppingItemModel item) {
		final textStyle = item.isChecked
				? AppTextStyles.subtitle.copyWith(
						decoration: TextDecoration.lineThrough,
						color: AppColors.textMuted,
					)
				: AppTextStyles.subtitle;
		String qtyStr = item.quantity % 1 == 0
			? item.quantity.toInt().toString()
			: item.quantity.toStringAsFixed(2);
		return Container(
			margin: const EdgeInsets.only(bottom: 12),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Checkbox(
						value: item.isChecked,
						onChanged: (value) {
							setState(() {
								service.toggleChecked(item.id, value ?? false);
							});
						},
					),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'${item.name} - $qtyStr ${item.unit}',
									style: textStyle,
								),
								Divider(height: 16, color: AppColors.border),
							],
						),
					),
				],
			),
		);
	}

	Future<void> _onConfirmBuy() async {
		if (_isSyncedToPantry) return;
		setState(() => _processing = true);
		try {
			await PantryScope.ensureInitialized();
			// Lấy các item chưa có trong pantry
			final pantry = PantryService.instance;
			await pantry.loadItems();
			final pantryItems = pantry.items;
			final toAdd = service.items.where((item) {
				if (!PantryScope.isPantryManagedIngredient(item.name)) {
					return false;
				}
				return !pantryItems.any((p) =>
						p.name.toLowerCase() == item.name.toLowerCase());
			}).toList();
			// Chỉ thêm tên, các trường khác để trống
			for (final item in toAdd) {
				await pantry.createItem(
					name: item.name,
					category: '',
					quantity: 0,
					unit: '',
				);
			}
			await pantry.loadItems();
			_syncedListIds.add(widget.list.id);
			if (mounted) {
				setState(() {});
			}
			// Đưa item mới lên đầu danh sách
			if (toAdd.isNotEmpty) {
				Navigator.of(context).pushReplacement(
					MaterialPageRoute(builder: (_) => PantryScreen()),
				);
				Future.delayed(const Duration(milliseconds: 500), () {
					showTopSnackBar(
						context,
						'Vui lòng điền thêm thông tin cho nguyên liệu vừa thêm!',
						isError: true,
					);
				});
			}
		} catch (e) {
			showTopSnackBar(
				context,
				'Có lỗi khi thêm vào tủ lạnh: $e',
				isError: true,
			);
		} finally {
			setState(() => _processing = false);
		}
	}
	// ...existing code...

	String _formatDate(DateTime date) {
		final d = date.toLocal();
		final day = d.day.toString().padLeft(2, '0');
		final month = d.month.toString().padLeft(2, '0');
		final year = d.year.toString();
		return '$day/$month/$year';
	}
}

class _AddShoppingItemSheet extends StatefulWidget {
	final ShoppingService service;
	final String listId;

	const _AddShoppingItemSheet({
		required this.service,
		required this.listId,
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
		// Kiểm tra ngày hết hạn
		final now = DateTime.now();
		final today = DateTime(now.year, now.month, now.day);
		final planDate = widget.service.activeListId != null
			? widget.service.lists.firstWhere((l) => l.id == widget.service.activeListId).planDate
			: today;
		if (planDate.isBefore(today)) {
			showTopSnackBar(
				context,
				context.tr('Không thể chọn ngày hết hạn nhỏ hơn ngày hiện tại.'),
				isError: true,
			);
			return;
		}
		setState(() => _saving = true);
		try {
			await widget.service.addManualItem(
				listId: widget.listId,
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
									decoration: InputDecoration(
										labelText: context.tr('Số lượng'),
									),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: TextField(
									controller: _unitCtrl,
									decoration: InputDecoration(
										labelText: context.tr('Đơn vị'),
									),
								),
							),
						],
					),
					const SizedBox(height: 16),
					Row(
						children: [
							Expanded(
								child: OutlinedButton(
									onPressed:
										_saving ? null : () => Navigator.pop(context),
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
												child: CircularProgressIndicator(
													strokeWidth: 2,
												),
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
