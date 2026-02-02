import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RecipeCard extends StatelessWidget {
	final String imageUrl;
	final String title;
	final String? category;
	final List<String> tags;
	final String time;
	final int count;
	final VoidCallback? onTap;

	const RecipeCard({
		super.key,
		required this.imageUrl,
		required this.title,
		this.category,
		required this.tags,
		required this.time,
		required this.count,
		this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(16),
			child: SizedBox(
				width: 200,
				child: Container(
					padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
					decoration: BoxDecoration(
						color: AppColors.surface,
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: AppColors.border),
						boxShadow: const [
							BoxShadow(
								color: AppColors.shadow,
								blurRadius: 8,
								offset: Offset(0, 6),
							),
						],
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							ClipRRect(
								borderRadius: BorderRadius.circular(12),
								child: Image.network(
									imageUrl,
									height: 88,
									width: double.infinity,
									fit: BoxFit.cover,
								),
							),
							const SizedBox(height: 6),
							if (category != null)
								Text(category!,
										style:
												const TextStyle(fontSize: 11, color: AppColors.textMuted)),
							if (category != null) const SizedBox(height: 2),
							Text(
								title,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
							),
							const SizedBox(height: 6),
							SizedBox(
								height: 20,
								child: ListView.separated(
									scrollDirection: Axis.horizontal,
									itemCount: tags.length,
									separatorBuilder: (_, __) => const SizedBox(width: 6),
									itemBuilder: (_, i) => Container(
										padding:
												const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
										decoration: BoxDecoration(
											color: AppColors.surfaceSoft,
											borderRadius: BorderRadius.circular(20),
										),
										child: Text(tags[i], style: const TextStyle(fontSize: 9)),
									),
								),
							),
							const Spacer(),
							Row(
								children: [
									const Icon(Icons.access_time,
											size: 12, color: AppColors.textMuted),
									const SizedBox(width: 4),
									Text(time,
											style: const TextStyle(
													fontSize: 10, color: AppColors.textMuted)),
									const SizedBox(width: 12),
									const Icon(Icons.list_alt,
											size: 12, color: AppColors.textMuted),
									const SizedBox(width: 4),
									Text('$count',
											style: const TextStyle(
													fontSize: 10, color: AppColors.textMuted)),
								],
							)
						],
					),
				),
			),
		);
	}
}