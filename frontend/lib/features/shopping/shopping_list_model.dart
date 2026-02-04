class ShoppingListModel {
	final String id;
	final String name;
	final DateTime planDate;
	final bool isCompleted;
	final int itemCount;
	final int completedCount;

	const ShoppingListModel({
		required this.id,
		required this.name,
		required this.planDate,
		required this.isCompleted,
		required this.itemCount,
		required this.completedCount,
	});

	ShoppingListModel copyWith({
		String? id,
		String? name,
		DateTime? planDate,
		bool? isCompleted,
		int? itemCount,
		int? completedCount,
	}) {
		return ShoppingListModel(
			id: id ?? this.id,
			name: name ?? this.name,
			planDate: planDate ?? this.planDate,
			isCompleted: isCompleted ?? this.isCompleted,
			itemCount: itemCount ?? this.itemCount,
			completedCount: completedCount ?? this.completedCount,
		);
	}
}
