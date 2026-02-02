import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'planner_tab.dart';

class PlannerScreen extends StatelessWidget {
	const PlannerScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				backgroundColor: AppColors.background,
				elevation: 0,
				leading: IconButton(
					onPressed: () => Navigator.pop(context),
					icon: const Icon(Icons.arrow_back),
				),
				title: Text('Planner', style: AppTextStyles.title),
			),
			body: const PlannerTab(),
		);
	}
}
