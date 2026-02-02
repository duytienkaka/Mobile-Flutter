import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'shopping_item_model.dart';

class ShoppingService extends ChangeNotifier {
	static final ShoppingService instance = ShoppingService._();

	final List<ShoppingItemModel> _items = [];
	final Set<String> _dismissedKeys = {};
	bool _loading = false;

	ShoppingService._();

	List<ShoppingItemModel> get items => List.unmodifiable(_items);
	bool get isLoading => _loading;

	List<ShoppingItemModel> itemsBySource(ShoppingSource source) {
		return _items.where((item) => item.source == source).toList();
	}

	Map<String, List<ShoppingItemModel>> groupedItems({
		required bool completed,
	}) {
		final map = <String, List<ShoppingItemModel>>{};
		for (final item in _items.where((e) => e.isChecked == completed)) {
			map.putIfAbsent(item.groupTitle, () => []).add(item);
		}
		return map;
	}

	Future<void> toggleChecked(String id, bool value) async {
		final index = _items.indexWhere((item) => item.id == id);
		if (index == -1) return;
		final current = _items[index].copyWith(isChecked: value);
		_items[index] = current;
		notifyListeners();
		try {
			await _updateItem(current);
		} catch (_) {
			await loadItems();
		}
	}

	Future<void> removeItem(String id) async {
		final index = _items.indexWhere((item) => item.id == id);
		if (index == -1) return;
		_dismissedKeys.add(_items[index].key);
		_items.removeAt(index);
		notifyListeners();
		try {
			await ApiClient.delete('/shopping/items/$id', auth: true);
		} catch (_) {
			await loadItems();
		}
	}

	Future<void> addManualItem({
		required String name,
		required double quantity,
		required String unit,
	}) {
		return _createItem(name: name, quantity: quantity, unit: unit);
	}

	Future<void> loadItems() async {
		if (_loading) return;
		_loading = true;
		notifyListeners();
		try {
			final res = await ApiClient.get('/shopping', auth: true);
			if (res.statusCode != 200) {
				throw Exception(_extractError(res));
			}
			final data = jsonDecode(res.body);
			final items = <ShoppingItemModel>[];
			if (data is Map && data['items'] is List) {
				for (final item in data['items'] as List) {
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

	Future<void> _createItem({
		required String name,
		required double quantity,
		required String unit,
	}) async {
		final res = await ApiClient.post(
			'/shopping/items',
			{
				'name': name,
				'quantity': quantity,
				'unit': unit,
			},
			auth: true,
		);
		if (res.statusCode != 201) {
			throw Exception(_extractError(res));
		}
		final data = jsonDecode(res.body);
		if (data is Map<String, dynamic>) {
			final item = _fromApi(data);
			if (_dismissedKeys.contains(item.key)) return;
			_items.add(item);
			notifyListeners();
		}
	}

	Future<void> _updateItem(ShoppingItemModel item) async {
		final res = await ApiClient.put(
			'/shopping/items/${item.id}',
			{
				'name': item.name,
				'quantity': item.quantity,
				'unit': item.unit,
				'isChecked': item.isChecked,
			},
			auth: true,
		);
		if (res.statusCode != 200) {
			throw Exception(_extractError(res));
		}
		final data = jsonDecode(res.body);
		if (data is Map<String, dynamic>) {
			final updated = _fromApi(data);
			final index = _items.indexWhere((e) => e.id == updated.id);
			if (index != -1) {
				_items[index] = updated;
				notifyListeners();
			}
		}
	}

	ShoppingItemModel _fromApi(Map<String, dynamic> item) {
		return ShoppingItemModel(
			id: (item['id'] ?? '').toString(),
			name: (item['name'] ?? '').toString(),
			quantity: item['quantity'] is num
					? (item['quantity'] as num).toDouble()
					: double.tryParse(item['quantity'].toString()) ?? 1,
			unit: (item['unit'] ?? '').toString(),
			source: ShoppingSource.suggested,
			groupTitle: 'To Buy',
			sourceDetail: 'Manual',
			isChecked: item['isChecked'] == true,
		);
	}

	String _extractError(dynamic res) {
		try {
			if (res.statusCode == 401) {
				return 'Vui lòng đăng nhập lại.';
			}
			final data = jsonDecode(res.body);
			if (data is Map && data['message'] is String) {
				final message = (data['message'] as String).trim();
				if (message.isNotEmpty) return message;
			}
		} catch (_) {}
		switch (res.statusCode) {
			case 400:
				return 'Dữ liệu không hợp lệ.';
			case 404:
				return 'Không tìm thấy dữ liệu.';
			default:
				return 'Không thể xử lý yêu cầu.';
		}
	}
}