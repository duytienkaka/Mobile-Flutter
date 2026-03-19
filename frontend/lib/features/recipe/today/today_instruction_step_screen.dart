import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/l10n_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../planner/planner_service.dart';
import '../recipe_screen.dart';

class TodayInstructionStepScreen extends StatefulWidget {
	final String recipeName;
	final int servings;
	final List<String> steps;
	final int initialIndex;

	const TodayInstructionStepScreen({
		super.key,
		required this.recipeName,
		this.servings = 1,
		required this.steps,
		required this.initialIndex,
	});

	@override
	State<TodayInstructionStepScreen> createState() => _TodayInstructionStepScreenState();
}

class _TodayInstructionStepScreenState extends State<TodayInstructionStepScreen> {
	late int _index;
	bool _finishing = false;

	@override
	void initState() {
		super.initState();
		_index = widget.initialIndex.clamp(0, widget.steps.length - 1);
	}

	@override
	Widget build(BuildContext context) {
		final stepText = widget.steps[_index];
		final total = widget.steps.length;
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				title: Text(context.tr('Hướng dẫn nấu')),
				backgroundColor: AppColors.background,
				foregroundColor: AppColors.textPrimary,
				elevation: 0,
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Text(
										context.trKey(
											L10nKeys.commonStepProgress,
											params: {
												'current': _index + 1,
												'total': total,
											},
										),
										style: AppTextStyles.caption,
									),
									const Spacer(),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
										decoration: BoxDecoration(
											color: AppColors.surface,
											borderRadius: BorderRadius.circular(999),
											border: Border.all(color: AppColors.border),
										),
										child: Text(
											widget.recipeName,
											style: AppTextStyles.caption,
										),
									),
								],
							),
							const SizedBox(height: 16),
							_buildDecorBanner(context),
							const SizedBox(height: 16),
							Text(
								stepText,
								style: AppTextStyles.body,
							),
						],
					),
				),
			),
			bottomNavigationBar: Padding(
				padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
				child: Row(
					children: [
						Expanded(
							child: OutlinedButton(
								onPressed: _index > 0 ? _prevStep : null,
								style: OutlinedButton.styleFrom(
									foregroundColor: AppColors.textPrimary,
									side: BorderSide(color: AppColors.border),
									padding: const EdgeInsets.symmetric(vertical: 14),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(14),
									),
								),
								child: Text(context.tr('Bước trước')),
							),
						),
						const SizedBox(width: 12),
						Expanded(
							child: ElevatedButton(
								onPressed: _index < total - 1
									? _nextStep
									: (_finishing ? null : _finish),
								style: ElevatedButton.styleFrom(
									backgroundColor: AppColors.primary,
									foregroundColor: AppColors.black,
									padding: const EdgeInsets.symmetric(vertical: 14),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(14),
									),
								),
								child: _finishing
									? const SizedBox(
										height: 18,
										width: 18,
										child: CircularProgressIndicator(strokeWidth: 2),
									)
									: Text(
										_index < total - 1
												? context.tr('Bước tiếp theo')
												: context.tr('Hoàn tất'),
									),
							),
						),
					],
				),
			),
		);
	}

	Widget _buildDecorBanner(BuildContext context) {
		return Container(
			height: 160,
			decoration: BoxDecoration(
				color: AppColors.surfaceSoft,
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: AppColors.border),
			),
			child: Stack(
				children: [
					Positioned(
						left: -14,
						top: -10,
						child: Container(
							width: 80,
							height: 80,
							decoration: BoxDecoration(
								color: const Color(0xFFFDE68A),
								borderRadius: BorderRadius.circular(999),
							),
						),
					),
					Positioned(
						right: -20,
						bottom: -20,
						child: Container(
							width: 110,
							height: 110,
							decoration: BoxDecoration(
								color: const Color(0xFFFFEDD5),
								borderRadius: BorderRadius.circular(999),
							),
						),
					),
					Center(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: 52,
									height: 52,
									decoration: BoxDecoration(
										color: AppColors.surface,
										borderRadius: BorderRadius.circular(16),
										border: Border.all(color: AppColors.border),
									),
									child: Icon(
										Icons.menu_book,
										color: AppColors.textMuted,
										size: 22,
									),
								),
								const SizedBox(height: 8),
								Text(
									context.tr('Hướng dẫn nấu'),
									style: AppTextStyles.caption.copyWith(
										color: AppColors.textMuted,
									),
								),
							],
						),
					),
				],
			),
		);
	}

	void _nextStep() {
		if (_index >= widget.steps.length - 1) return;
		setState(() => _index += 1);
	}

	void _prevStep() {
		if (_index <= 0) return;
		setState(() => _index -= 1);
	}

	Future<void> _finish() async {
		setState(() => _finishing = true);
		try {
			final now = DateTime.now();
			final mealType = _mealTypeByTime(now);
			final entry = MealPlanEntry(
				id: PlannerService.instance.createId(),
				date: now,
				mealType: mealType,
				recipeName: widget.recipeName,
				servings: widget.servings <= 0 ? 1 : widget.servings,
				note: 'Hoàn tất lúc ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
			);
			await PlannerService.instance.createPlan(entry);

			if (!mounted) return;
			Navigator.of(context).pushAndRemoveUntil(
				MaterialPageRoute(builder: (_) => const RecipeScreen()),
				(route) => false,
			);
		} catch (e) {
			if (!mounted) return;
			showTopSnackBar(context, e.toString().replaceAll('Exception: ', ''), isError: true);
			setState(() => _finishing = false);
		}
	}

	MealType _mealTypeByTime(DateTime time) {
		final hour = time.hour;
		if (hour >= 5 && hour < 11) return MealType.breakfast;
		if (hour >= 11 && hour < 16) return MealType.lunch;
		if (hour >= 16 && hour < 22) return MealType.dinner;
		return MealType.snack;
	}
}
