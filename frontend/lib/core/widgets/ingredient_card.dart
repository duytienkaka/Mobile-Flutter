import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class IngredientCard extends StatelessWidget {
	final String name;
	final String quantity;
	final String expiry;
	final bool isExpired;
	final bool isWarning;

	const IngredientCard({
		super.key,
		required this.name,
		required this.quantity,
		required this.expiry,
		this.isExpired = false,
		this.isWarning = false,
	});

	@override
	Widget build(BuildContext context) {
		Color badgeColor = AppColors.textMuted;
		if (isExpired) badgeColor = AppColors.danger;
		if (!isExpired && isWarning) badgeColor = AppColors.warning;

		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.black, width: 2),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
								decoration: BoxDecoration(
									color: AppColors.surfaceSoft,
									borderRadius: BorderRadius.circular(20),
								),
								child:
										Text(quantity, style: const TextStyle(fontSize: 10)),
							),
							const Spacer(),
							Container(
								width: 10,
								height: 10,
								decoration:
										BoxDecoration(color: badgeColor, shape: BoxShape.circle),
							),
						],
					),
					const SizedBox(height: 8),
					Expanded(
						child: Center(
							child: Icon(Icons.image_outlined,
									size: 48, color: AppColors.textMuted),
						),
					),
					const SizedBox(height: 6),
					Text(name,
							style:
									const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
					const SizedBox(height: 4),
					Text(expiry,
							style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
				],
			),
		);
	}
}