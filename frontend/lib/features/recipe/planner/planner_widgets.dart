import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/top_snackbar.dart';
import 'planner_service.dart';

class WeekDayChip extends StatelessWidget {
	final DateTime date;
	final bool selected;
	final VoidCallback onTap;

	const WeekDayChip({
		super.key,
		required this.date,
		required this.selected,
		required this.onTap,
	});

	static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

	@override
	Widget build(BuildContext context) {
		final label = _dayLabels[date.weekday - 1];
		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 200),
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
				decoration: BoxDecoration(
					color: selected ? AppColors.primary : AppColors.surface,
					borderRadius: BorderRadius.circular(14),
					border: Border.all(color: AppColors.border),
				),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(
							label,
							style: AppTextStyles.caption.copyWith(
								color:
										selected ? AppColors.black : AppColors.textSecondary,
							),
						),
						const SizedBox(height: 4),
						Text(
							'${date.day}',
							style: AppTextStyles.subtitle.copyWith(
								color:
										selected ? AppColors.black : AppColors.textPrimary,
							),
						),
					],
				),
			),
		);
	}
}

class MealPlanCard extends StatelessWidget {
	final MealPlanEntry entry;
	final VoidCallback onEdit;
	final VoidCallback onDelete;

	const MealPlanCard({
		super.key,
		required this.entry,
		required this.onEdit,
		required this.onDelete,
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: Row(
					children: [
						Container(
							width: 44,
							height: 44,
							decoration: BoxDecoration(
								color: AppColors.primarySoft,
								borderRadius: BorderRadius.circular(12),
							),
							child: Icon(entry.mealType.icon, color: AppColors.black),
						),
						const SizedBox(width: 12),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(entry.mealType.label, style: AppTextStyles.caption),
									const SizedBox(height: 4),
									Text(entry.recipeName, style: AppTextStyles.subtitle),
									const SizedBox(height: 4),
									Text(
										'${entry.servings} suất',
										style: AppTextStyles.caption,
									),
									if (entry.note != null && entry.note!.trim().isNotEmpty)
										Padding(
											padding: const EdgeInsets.only(top: 4),
											child: Text(
												entry.note!,
												style: AppTextStyles.caption,
											),
										),
								],
							),
						),
						Column(
							children: [
								IconButton(
									onPressed: onEdit,
									icon: const Icon(Icons.edit_outlined),
								),
								IconButton(
									onPressed: onDelete,
									icon: const Icon(Icons.delete_outline),
								),
							],
						),
					],
				),
			),
		);
	}
}

class PlannerEntrySheet extends StatefulWidget {
	final MealPlanEntry? entry;
	final DateTime initialDate;

	const PlannerEntrySheet({
		super.key,
		this.entry,
		required this.initialDate,
	});

	@override
	State<PlannerEntrySheet> createState() => _PlannerEntrySheetState();
}

class _PlannerEntrySheetState extends State<PlannerEntrySheet> {
	late DateTime selectedDate;
	late MealType mealType;
	final recipeCtrl = TextEditingController();
	final noteCtrl = TextEditingController();
	final servingsCtrl = TextEditingController();

	@override
	void initState() {
		super.initState();
		selectedDate = widget.entry?.date ?? widget.initialDate;
		mealType = widget.entry?.mealType ?? MealType.lunch;
		recipeCtrl.text = widget.entry?.recipeName ?? '';
		noteCtrl.text = widget.entry?.note ?? '';
		servingsCtrl.text =
				widget.entry?.servings.toString() ?? '2';
	}

	@override
	void dispose() {
		recipeCtrl.dispose();
		noteCtrl.dispose();
		servingsCtrl.dispose();
		super.dispose();
	}

	Future<void> _pickDate() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: selectedDate,
			firstDate: DateTime(2020),
			lastDate: DateTime(2035),
		);
		if (picked == null) return;
		setState(() => selectedDate = picked);
	}

	void _submit() {
		final name = recipeCtrl.text.trim();
		if (name.isEmpty) {
			showTopSnackBar(context, 'Vui lòng nhập tên món ăn.', isError: true);
			return;
		}
		final servings = int.tryParse(servingsCtrl.text.trim()) ?? 1;
		final entry = MealPlanEntry(
			id: widget.entry?.id ?? PlannerService.instance.createId(),
			date: selectedDate,
			mealType: mealType,
			recipeName: name,
			servings: servings <= 0 ? 1 : servings,
			note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
		);
		Navigator.pop(context, entry);
	}

	@override
	Widget build(BuildContext context) {
		final isEdit = widget.entry != null;
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
					Text(
						isEdit ? 'Sửa kế hoạch' : 'Thêm kế hoạch',
						style: AppTextStyles.title,
					),
					const SizedBox(height: 16),
					Text('Ngày', style: AppTextStyles.caption),
					const SizedBox(height: 6),
					InkWell(
						onTap: _pickDate,
						child: Container(
							padding: const EdgeInsets.symmetric(
								horizontal: 14,
								vertical: 12,
							),
							decoration: BoxDecoration(
								color: AppColors.surface,
								borderRadius: BorderRadius.circular(12),
								border: Border.all(color: AppColors.border),
							),
							child: Row(
								children: [
									const Icon(Icons.calendar_today, size: 18),
									const SizedBox(width: 8),
									Text(
										'${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
										style: AppTextStyles.body,
									),
								],
							),
						),
					),
					const SizedBox(height: 12),
					Text('Bữa ăn', style: AppTextStyles.caption),
					const SizedBox(height: 6),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 12),
						decoration: BoxDecoration(
							color: AppColors.surface,
							borderRadius: BorderRadius.circular(12),
							border: Border.all(color: AppColors.border),
						),
						child: DropdownButtonHideUnderline(
							child: DropdownButton<MealType>(
								value: mealType,
								items: MealType.values
									.map(
										(type) => DropdownMenuItem(
											value: type,
											child: Text(type.label),
										),
									)
									.toList(),
								onChanged: (value) {
									if (value == null) return;
									setState(() => mealType = value);
								},
							),
						),
					),
					const SizedBox(height: 12),
					TextField(
						controller: recipeCtrl,
						decoration: const InputDecoration(
							labelText: 'Tên món ăn',
							hintText: 'Ví dụ: Cơm gà',
						),
					),
					const SizedBox(height: 12),
					TextField(
						controller: servingsCtrl,
						keyboardType: TextInputType.number,
						decoration: const InputDecoration(
							labelText: 'Số suất',
						),
					),
					const SizedBox(height: 12),
					TextField(
						controller: noteCtrl,
						maxLines: 2,
						decoration: const InputDecoration(
							labelText: 'Ghi chú',
							hintText: 'Ghi chú thêm nếu cần',
						),
					),
					const SizedBox(height: 18),
					Row(
						children: [
							Expanded(
								child: OutlinedButton(
									onPressed: () => Navigator.pop(context),
									child: const Text('Huỷ'),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: PrimaryButton(
									label: isEdit ? 'Lưu thay đổi' : 'Thêm món',
									onPressed: _submit,
								),
							),
						],
					),
				],
			),
		);
	}
}