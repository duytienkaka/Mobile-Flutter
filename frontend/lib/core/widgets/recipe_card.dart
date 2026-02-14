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
	final bool showImage;

	const RecipeCard({
		super.key,
		required this.imageUrl,
		required this.title,
		this.category,
		required this.tags,
		required this.time,
		required this.count,
		this.onTap,
		this.showImage = true,
	});

	@override
	Widget build(BuildContext context) {
		final header = showImage
				? _buildImageHeader()
				: _buildNoImageHeader();
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
						boxShadow: [
							BoxShadow(
								color: AppColors.shadow,
								blurRadius: 8,
								offset: const Offset(0, 6),
							),
						],
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							header,
							const SizedBox(height: 6),
							if (category != null)
								Text(category!,
										style:
												TextStyle(fontSize: 11, color: AppColors.textMuted)),
							if (category != null) const SizedBox(height: 2),
							Text(
								title,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
							),
							const SizedBox(height: 8),
							Wrap(
								spacing: 6,
								runSpacing: 6,
								children: tags.map((tag) {
									return Container(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
										decoration: BoxDecoration(
											color: AppColors.surfaceSoft,
											borderRadius: BorderRadius.circular(20),
											border: Border.all(color: AppColors.border),
										),
										child: Text(tag, style: const TextStyle(fontSize: 9)),
									);
								}).toList(),
							),
							const Spacer(),
							Row(
								children: [
									Icon(Icons.access_time,
											size: 12, color: AppColors.textMuted),
									const SizedBox(width: 4),
									Text(time,
											style: TextStyle(
													fontSize: 10, color: AppColors.textMuted)),
									const SizedBox(width: 12),
									Icon(Icons.list_alt,
											size: 12, color: AppColors.textMuted),
									const SizedBox(width: 4),
									Text('$count',
											style: TextStyle(
													fontSize: 10, color: AppColors.textMuted)),
								],
							)
						],
					),
				),
			),
		);
	}

	Widget _buildImageHeader() {
		return ClipRRect(
			borderRadius: BorderRadius.circular(12),
			child: Image.network(
				imageUrl.isEmpty
						? 'https://source.unsplash.com/featured/?food'
						: imageUrl,
				height: 88,
				width: double.infinity,
				fit: BoxFit.cover,
				errorBuilder: (_, __, ___) => Container(
					height: 88,
					width: double.infinity,
					color: AppColors.surfaceSoft,
					child: Icon(
						Icons.restaurant,
						color: AppColors.textMuted,
						size: 22,
					),
				),
			),
		);
	}

	Widget _buildNoImageHeader() {
		return Container(
			height: 76,
			width: double.infinity,
			padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(12),
				gradient: const LinearGradient(
					colors: [Color(0xFFFDE68A), Color(0xFFF3F4F6)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								padding: const EdgeInsets.all(6),
								decoration: BoxDecoration(
									color: AppColors.surface,
									borderRadius: BorderRadius.circular(8),
									border: Border.all(color: AppColors.border),
								),
								child: Icon(
									Icons.restaurant_menu,
									color: AppColors.textMuted,
									size: 16,
								),
							),
							const Spacer(),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
								decoration: BoxDecoration(
									color: AppColors.surface,
									borderRadius: BorderRadius.circular(999),
									border: Border.all(color: AppColors.border),
								),
								child: Text(
									time,
									style: TextStyle(fontSize: 9, color: AppColors.textMuted),
								),
							),
						],
					),
					const Spacer(),
					Row(
						children: [
							Text(
								count.toString(),
								style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
							),
							const SizedBox(width: 6),
							Text(
								'nguyên liệu',
								style: TextStyle(fontSize: 9, color: AppColors.textMuted),
							),
						],
					),
				],
			),
		);
	}
}
