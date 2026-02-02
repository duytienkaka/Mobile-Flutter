import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tab_filter_pill.dart';
import '../../../core/widgets/top_snackbar.dart';
import 'planner_service.dart';
import 'planner_widgets.dart';

class PlannerTab extends StatefulWidget {
	const PlannerTab({super.key});

	@override
	State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
	final PlannerService service = PlannerService.instance;
	late DateTime weekStart;
	late DateTime selectedDate;
	bool showWeekView = false;

	@override
	void initState() {
		super.initState();
		weekStart = service.weekStartFor(DateTime.now());
		selectedDate = DateTime.now();
		service.addListener(_handleUpdate);
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
				showTopSnackBar(context, 'Đã thêm kế hoạch.', isError: false);
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
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Xoá kế hoạch'),
				content: const Text('Bạn chắc chắn muốn xoá món này?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Huỷ'),
					),
					TextButton(
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Xoá'),
					),
				],
			),
		);
		if (confirmed == true) {
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
			return const EmptyState(
				title: 'Chưa có kế hoạch',
				message: 'Thêm món ăn cho ngày này để bắt đầu.',
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
									'Chưa có kế hoạch',
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
		return SafeArea(
			child: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Expanded(
									child: Text(
										'Lịch kế hoạch',
										style: AppTextStyles.title,
									),
								),
								IconButton(
									onPressed: () => _openEntrySheet(),
									icon: const Icon(Icons.add_circle_outline),
								),
							],
						),
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
								separatorBuilder: (_, __) => const SizedBox(width: 10),
								itemCount: days.length,
							),
						),
						const SizedBox(height: 16),
						Row(
							children: [
								TabFilterPill(
									label: 'Theo ngày',
									selected: !showWeekView,
									onTap: () =>
											setState(() => showWeekView = false),
								),
								const SizedBox(width: 8),
								TabFilterPill(
									label: 'Theo tuần',
									selected: showWeekView,
									onTap: () =>
											setState(() => showWeekView = true),
								),
							],
						),
						const SizedBox(height: 16),
						if (showWeekView) _buildWeekPlans() else _buildDayPlans(selectedDate),
					],
				),
			),
		);
	}
}