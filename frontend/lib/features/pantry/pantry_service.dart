import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'pantry_item_model.dart';

class PantryService extends ChangeNotifier {
	static final PantryService instance = PantryService._();

	PantryService._();

	final List<PantryItemModel> _items = [];
	bool _loading = false;

	List<PantryItemModel> get items => List.unmodifiable(_items);
	bool get isLoading => _loading;

	int get expiredCount {
		final today = _normalizeDate(DateTime.now());
		return _items.where((item) {
			final expiredAt = item.expiredAt;
			if (expiredAt == null) return false;
			return _normalizeDate(expiredAt).isBefore(today);
		}).length;
	}

	int get expiringSoonCount {
		final today = _normalizeDate(DateTime.now());
		return _items.where((item) {
			final expiredAt = item.expiredAt;
			if (expiredAt == null) return false;
			final normalized = _normalizeDate(expiredAt);
			if (normalized.isBefore(today)) return false;
			return normalized.difference(today).inDays < 4;
		}).length;
	}

	Future<void> loadItems() async {
		if (_loading) return;
		_loading = true;
		notifyListeners();
		try {
			final res = await ApiClient.get('/ingredients', auth: true);
			if (res.statusCode != 200) {
				throw Exception('Failed to load ingredients');
			}
			final data = jsonDecode(res.body);
			final items = <PantryItemModel>[];
			if (data is List) {
				for (final item in data) {
					if (item is Map<String, dynamic>) {
						items.add(_fromApi(item));
					}
				}
			}
			_items
				..clear()
				..addAll(items);
			notifyListeners();
		} finally {
			_loading = false;
			notifyListeners();
		}
	}

	PantryItemModel _fromApi(Map<String, dynamic> item) {
		return PantryItemModel(
			id: (item['id'] ?? '').toString(),
			name: (item['name'] ?? '').toString(),
			quantity: item['quantity'] is num
					? (item['quantity'] as num).toDouble()
					: double.tryParse(item['quantity'].toString()) ?? 0,
			unit: (item['unit'] ?? '').toString(),
			expiredAt: item['expiredAt'] == null
					? null
					: DateTime.tryParse(item['expiredAt'].toString()),
		);
	}

	DateTime _normalizeDate(DateTime date) {
		return DateTime(date.year, date.month, date.day);
	}
}