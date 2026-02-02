import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
	final String title;
	final String? actionLabel;
	final VoidCallback? onAction;

	const SectionHeader({
		super.key,
		required this.title,
		this.actionLabel,
		this.onAction,
	});

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Expanded(child: Text(title, style: AppTextStyles.subtitle)),
				if (actionLabel != null)
					TextButton(
						onPressed: onAction,
						child: Text(actionLabel!),
					),
			],
		);
	}
}