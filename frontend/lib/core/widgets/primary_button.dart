import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
	final String label;
	final VoidCallback? onPressed;
	final bool loading;
	final bool fullWidth;
	final Color? background;

	const PrimaryButton({
		super.key,
		required this.label,
		required this.onPressed,
		this.loading = false,
		this.fullWidth = true,
		this.background,
	});

	@override
	Widget build(BuildContext context) {
		final child = loading
				? const SizedBox(
						width: 18,
						height: 18,
						child: CircularProgressIndicator(strokeWidth: 2),
					)
				: Text(label, style: const TextStyle(fontWeight: FontWeight.w600));

		final button = ElevatedButton(
			style: ElevatedButton.styleFrom(
				backgroundColor: background ?? AppColors.primary,
				foregroundColor: Colors.black,
				padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
				elevation: 0,
			),
			onPressed: loading ? null : onPressed,
			child: child,
		);

		if (!fullWidth) return button;
		return SizedBox(width: double.infinity, child: button);
	}
}