enum ShoppingSource { planner, suggested }

class ShoppingItemModel {
	final String id;
	final String name;
	final double quantity;
	final String unit;
	final ShoppingSource source;
	final bool isChecked;
	final String groupTitle;
	final String sourceDetail;

	const ShoppingItemModel({
		required this.id,
		required this.name,
		required this.quantity,
		required this.unit,
		required this.source,
		required this.groupTitle,
		required this.sourceDetail,
		this.isChecked = false,
	});

	ShoppingItemModel copyWith({
		String? id,
		String? name,
		double? quantity,
		String? unit,
		ShoppingSource? source,
		String? groupTitle,
		String? sourceDetail,
		bool? isChecked,
	}) {
		return ShoppingItemModel(
			id: id ?? this.id,
			name: name ?? this.name,
			quantity: quantity ?? this.quantity,
			unit: unit ?? this.unit,
			source: source ?? this.source,
			groupTitle: groupTitle ?? this.groupTitle,
			sourceDetail: sourceDetail ?? this.sourceDetail,
			isChecked: isChecked ?? this.isChecked,
		);
	}

	String get key => '${name.toLowerCase()}_${unit.toLowerCase()}';
}