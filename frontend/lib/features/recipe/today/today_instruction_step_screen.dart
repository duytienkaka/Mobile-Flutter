import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TodayInstructionStepScreen extends StatefulWidget {
	final String recipeName;
	final List<String> steps;
	final int initialIndex;

	const TodayInstructionStepScreen({
		super.key,
		required this.recipeName,
		required this.steps,
		required this.initialIndex,
	});

	@override
	State<TodayInstructionStepScreen> createState() => _TodayInstructionStepScreenState();
}

class _TodayInstructionStepScreenState extends State<TodayInstructionStepScreen> {
	late int _index;

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
										'${context.tr('Bước')} ${_index + 1}/$total',
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
								onPressed: _index < total - 1 ? _nextStep : _finish,
								style: ElevatedButton.styleFrom(
									backgroundColor: AppColors.primary,
									foregroundColor: AppColors.black,
									padding: const EdgeInsets.symmetric(vertical: 14),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(14),
									),
								),
								child: Text(
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

	void _finish() {
		Navigator.of(context).pop();
	}
}
