class PantryItemModel {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expiredAt;

  const PantryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expiredAt,
  });
}
