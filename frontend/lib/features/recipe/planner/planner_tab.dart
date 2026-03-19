import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tab_filter_pill.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import 'planner_service.dart';
import 'planner_widgets.dart';
import '../../settings/settings_service.dart';

class PlannerTab extends StatefulWidget {
	final bool scrollable;

	const PlannerTab({super.key, this.scrollable = true});

	@override
	State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
	final PlannerService service = PlannerService.instance;
	late DateTime weekStart;
	late DateTime selectedDate;
	bool showWeekView = false;
	bool _weeklyActionLoading = false;
	double? _weeklyBudget;
	String _nutritionGoal = 'balanced';

	@override
	void initState() {
		super.initState();
		weekStart = service.weekStartFor(DateTime.now());
		selectedDate = DateTime.now();
		service.addListener(_handleUpdate);
		_loadWeeklyPreferences();
		service.loadWeek(weekStart);
	}

	@override
	void dispose() {
		service.removeListener(_handleUpdate);
		super.dispose();
	}

	void _handleUpdate() {
		if (mounted) setState(() {});
	}

	void _changeWeek(int offset) {
		setState(() {
			weekStart = weekStart.add(Duration(days: offset * 7));
			selectedDate = weekStart;
		});
		service.loadWeek(weekStart);
	}

	Future<void> _loadWeeklyPreferences() async {
		final prefs = await SettingsService.getWeeklyPlanPreferences();
		if (!mounted) return;
		setState(() {
			_weeklyBudget = prefs.weeklyBudget;
			_nutritionGoal = prefs.nutritionGoal.trim().isEmpty
				? 'balanced'
				: prefs.nutritionGoal.trim();
		});
	}

	Future<void> _saveWeeklyPreferences() {
		return SettingsService.saveWeeklyPlanPreferences(
			weeklyBudget: _weeklyBudget,
			nutritionGoal: _nutritionGoal,
		);
	}

	Future<void> _runWeeklyPlan({required bool regenerateAuto}) async {
		setState(() => _weeklyActionLoading = true);
		try {
			final status = await service.ensureWeeklyPlan(
				weeklyBudget: _weeklyBudget,
				nutritionGoal: _nutritionGoal,
				regenerateAutoSlots: regenerateAuto,
			);
			await service.loadWeek(weekStart);
			if (!mounted) return;
			final message = regenerateAuto
				? 'Đã tạo lại ${status.createdCount} bữa tự động và thay ${status.replacedAutoCount} bữa auto cũ.'
				: (status.createdCount > 0
					? 'Đã tạo tự động ${status.createdCount} bữa cho tuần này.'
					: 'Tuần này đã có đủ kế hoạch.');
			showTopSnackBar(context, message, isError: false);
		} catch (e) {
			if (!mounted) return;
			showTopSnackBar(
				context,
				e.toString().replaceAll('Exception: ', ''),
				isError: true,
			);
		} finally {
			if (mounted) setState(() => _weeklyActionLoading = false);
		}
	}

	Future<void> _openWeeklyPreferencesSheet() async {
		final budgetCtrl = TextEditingController(
			text: _weeklyBudget == null ? '' : _weeklyBudget!.toStringAsFixed(0),
		);
		var goal = _nutritionGoal;

		final applied = await showModalBottomSheet<bool>(
			context: context,
			isScrollControlled: true,
			backgroundColor: AppColors.surface,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) {
				return StatefulBuilder(
					builder: (context, setInnerState) {
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
									Text('Cấu hình Auto Plan tuần', style: AppTextStyles.title),
									const SizedBox(height: 12),
									TextField(
										controller: budgetCtrl,
										keyboardType: const TextInputType.numberWithOptions(decimal: true),
										decoration: const InputDecoration(
											labelText: 'Ngân sách tuần (tuỳ chọn)',
											hintText: 'Ví dụ: 700000',
										),
									),
									const SizedBox(height: 12),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 12),
										decoration: BoxDecoration(
											color: AppColors.surface,
											borderRadius: BorderRadius.circular(12),
											border: Border.all(color: AppColors.border),
										),
										child: DropdownButtonHideUnderline(
											child: DropdownButton<String>(
												value: goal,
												items: const [
													DropdownMenuItem(value: 'balanced', child: Text('Cân bằng')),
													DropdownMenuItem(value: 'weight_loss', child: Text('Giảm cân')),
													DropdownMenuItem(value: 'muscle_gain', child: Text('Tăng cơ')),
												],
												onChanged: (value) {
													if (value == null) return;
													setInnerState(() => goal = value);
												},
											),
										),
									),
									const SizedBox(height: 16),
									Row(
										children: [
											Expanded(
												child: OutlinedButton(
													onPressed: () => Navigator.pop(context, false),
													child: Text(context.tr('Huỷ')),
												),
											),
											const SizedBox(width: 12),
											Expanded(
												child: ElevatedButton(
													onPressed: () => Navigator.pop(context, true),
													child: const Text('Lưu cấu hình'),
												),
											),
										],
									),
								],
							),
						);
					},
				);
			},
		);

		if (applied != true) return;
		final parsedBudget = double.tryParse(budgetCtrl.text.trim());
		setState(() {
			_weeklyBudget = (parsedBudget == null || parsedBudget <= 0) ? null : parsedBudget;
			_nutritionGoal = goal;
		});
		await _saveWeeklyPreferences();
		if (!mounted) return;
		showTopSnackBar(context, 'Đã lưu cấu hình Auto Plan tuần.', isError: false);
	}

	Widget _buildWeeklyAutoBanner() {
		final status = service.weeklyStatus;
		final hasAuto = status?.hasAutoGeneratedThisWeek == true;
		final subtitle = hasAuto
			? 'Tuần này đã có kế hoạch auto. Bạn có thể cập nhật cấu hình rồi tạo bổ sung nếu còn slot trống.'
			: 'Bạn có thể tạo kế hoạch tuần tự động dựa trên pantry, ngân sách và mục tiêu dinh dưỡng.';

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: AppColors.surfaceSoft,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text('Auto Plan tuần', style: AppTextStyles.subtitle),
					const SizedBox(height: 4),
					Text(subtitle, style: AppTextStyles.caption),
					const SizedBox(height: 10),
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							OutlinedButton.icon(
								onPressed: _weeklyActionLoading ? null : _openWeeklyPreferencesSheet,
								icon: const Icon(Icons.tune, size: 18),
								label: const Text('Cấu hình'),
							),
							ElevatedButton.icon(
								onPressed: _weeklyActionLoading ? null : () => _runWeeklyPlan(regenerateAuto: false),
								icon: const Icon(Icons.auto_awesome, size: 18),
								label: const Text('Tạo tuần này'),
							),
						],
					),
				],
			),
		);
	}

	Future<void> _openEntrySheet({MealPlanEntry? entry}) async {
		final result = await showModalBottomSheet<MealPlanEntry>(
			context: context,
			isScrollControlled: true,
			backgroundColor: AppColors.surface,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (_) => PlannerEntrySheet(
				entry: entry,
				initialDate: entry?.date ?? selectedDate,
			),
		);
		if (result == null) return;
		try {
			if (entry == null) {
				await service.createPlan(result);
				if (!mounted) return;
				showTopSnackBar(
					context,
					context.tr('Đã thêm kế hoạch.'),
					isError: false,
				);
			} else {
				await service.updatePlan(result);
			}
		} catch (e) {
			if (!mounted) return;
			showTopSnackBar(
				context,
				e.toString().replaceAll('Exception: ', ''),
				isError: true,
			);
		}
	}

	Future<void> _confirmDelete(MealPlanEntry entry) async {
		final confirmed = await showAppConfirmDialog(
			context: context,
			title: context.tr('Xoá kế hoạch'),
			message: context.tr('Bạn chắc chắn muốn xoá món này?'),
			cancelText: context.tr('Huỷ'),
			confirmText: context.tr('Xoá'),
			isDanger: true,
			icon: Icons.delete_outline_rounded,
		);
		if (confirmed) {
			try {
				await service.removePlan(entry.id);
			} catch (e) {
				if (!mounted) return;
				showTopSnackBar(
					context,
					e.toString().replaceAll('Exception: ', ''),
					isError: true,
				);
			}
		}
	}

	Widget _buildWeekSelector() {
		final end = weekStart.add(const Duration(days: 6));
		final label =
				'${weekStart.day}/${weekStart.month} - ${end.day}/${end.month}';
		return Row(
			children: [
				IconButton(
					onPressed: () => _changeWeek(-1),
					icon: const Icon(Icons.chevron_left),
				),
				Expanded(
					child: Center(
						child: Text(label, style: AppTextStyles.subtitle),
					),
				),
				IconButton(
					onPressed: () => _changeWeek(1),
					icon: const Icon(Icons.chevron_right),
				),
			],
		);
	}

	Widget _buildDayPlans(DateTime date) {
		final plans = service.entriesForDate(date);
		if (plans.isEmpty) {
			return EmptyState(
				title: context.tr('Chưa có kế hoạch'),
				message: context.tr('Thêm món ăn cho ngày này để bắt đầu.'),
				icon: Icons.event_note,
			);
		}
		return Column(
			children: plans
					.map(
						(entry) => Padding(
							padding: const EdgeInsets.only(bottom: 12),
							child: MealPlanCard(
								entry: entry,
								onEdit: () => _openEntrySheet(entry: entry),
								onDelete: () => _confirmDelete(entry),
							),
						),
					)
					.toList(),
		);
	}

	Widget _buildWeekPlans() {
		final days = service.daysOfWeek(weekStart);
		return Column(
			children: days.map((day) {
				final plans = service.entriesForDate(day);
				return Padding(
					padding: const EdgeInsets.only(bottom: 16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							SectionHeader(
								title:
									'${day.day}/${day.month}/${day.year}',
							),
							const SizedBox(height: 10),
							if (plans.isEmpty)
								Text(
									context.tr('Chưa có kế hoạch'),
									style: AppTextStyles.caption,
								),
							...plans.map(
								(entry) => Padding(
									padding:
										const EdgeInsets.only(bottom: 10),
									child: MealPlanCard(
										entry: entry,
										onEdit: () => _openEntrySheet(entry: entry),
										onDelete: () => _confirmDelete(entry),
									),
								),
							),
						],
					),
				);
			}).toList(),
		);
	}

	@override
	Widget build(BuildContext context) {
		final days = service.daysOfWeek(weekStart);
		final content = Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
						Row(
							children: [
								Expanded(
									child: Text(
										context.tr('Lịch kế hoạch'),
										style: AppTextStyles.title,
									),
								),
								IconButton(
									onPressed: () => _openEntrySheet(),
									icon: const Icon(Icons.add_circle_outline),
								),
							],
						),
						const SizedBox(height: 10),
						_buildWeeklyAutoBanner(),
						const SizedBox(height: 12),
						_buildWeekSelector(),
						const SizedBox(height: 12),
						SizedBox(
							height: 78,
							child: ListView.separated(
								scrollDirection: Axis.horizontal,
								itemBuilder: (context, index) {
									final day = days[index];
									final isSelected =
											service.normalizeDate(day) ==
													service.normalizeDate(selectedDate);
									return WeekDayChip(
										date: day,
										selected: isSelected,
										onTap: () =>
												setState(() => selectedDate = day),
									);
								},
								separatorBuilder: (_, _) => const SizedBox(width: 10),
								itemCount: days.length,
							),
						),
						const SizedBox(height: 16),
						Row(
							children: [
								TabFilterPill(
									label: context.tr('Theo ngày'),
									selected: !showWeekView,
									onTap: () =>
											setState(() => showWeekView = false),
								),
								const SizedBox(width: 8),
								TabFilterPill(
									label: context.tr('Theo tuần'),
									selected: showWeekView,
									onTap: () =>
											setState(() => showWeekView = true),
								),
							],
						),
						const SizedBox(height: 16),
						if (showWeekView) _buildWeekPlans() else _buildDayPlans(selectedDate),
			],
		);

		if (!widget.scrollable) {
			return SafeArea(
				child: Padding(
					padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
					child: content,
				),
			);
		}

		return SafeArea(
			child: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
				child: content,
			),
		);
	}
}