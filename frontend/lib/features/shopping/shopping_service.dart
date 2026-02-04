import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'shopping_item_model.dart';
import 'shopping_list_model.dart';

class ShoppingService extends ChangeNotifier {
	static final ShoppingService instance = ShoppingService._();

	final List<ShoppingItemModel> _items = [];
	final List<ShoppingListModel> _lists = [];
	final Set<String> _dismissedKeys = {};
	bool _loading = false;
	bool _loadingLists = false;
	String? _activeListId;

	ShoppingService._();

	List<ShoppingItemModel> get items => List.unmodifiable(_items);
	List<ShoppingListModel> get lists => List.unmodifiable(_lists);
	bool get isLoading => _loading;
	bool get isLoadingLists => _loadingLists;
	String? get activeListId => _activeListId;

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
		_updateListCountsFromItems();
		notifyListeners();
		try {
			await _updateItem(current);
		} catch (_) {
			await loadItemsForList(_activeListId ?? '');
		}
	}

	Future<void> removeItem(String id) async {
		final index = _items.indexWhere((item) => item.id == id);
		if (index == -1) return;
		_dismissedKeys.add(_items[index].key);
		_items.removeAt(index);
		_updateListCountsFromItems();
		notifyListeners();
		try {
			await ApiClient.delete('/shopping/items/$id', auth: true);
		} catch (_) {
			await loadItemsForList(_activeListId ?? '');
		}
	}

	Future<void> addManualItem({
		required String listId,
		required String name,
		required double quantity,
		required String unit,
	}) {
		return _createItem(
			listId: listId,
			name: name,
			quantity: quantity,
			unit: unit,
		);
	}

	Future<void> loadLists() async {
		if (_loadingLists) return;
		_loadingLists = true;
		notifyListeners();
		try {
			final res = await ApiClient.get('/shopping/lists', auth: true);
			if (res.statusCode != 200) {
				throw Exception(_extractError(res));
			}
			final data = jsonDecode(res.body);
			final lists = <ShoppingListModel>[];
			if (data is List) {
				for (final item in data) {
					if (item is Map<String, dynamic>) {
						lists.add(_listFromApi(item));
					}
				}
			}
			_lists
				..clear()
				..addAll(lists);
			notifyListeners();
		} finally {
			_loadingLists = false;
			notifyListeners();
		}
	}

	Future<void> loadItemsForList(String listId) async {
		if (listId.isEmpty) return;
		if (_loading) return;
		_loading = true;
		notifyListeners();
		try {
			_activeListId = listId;
			final res = await ApiClient.get('/shopping/lists/$listId', auth: true);
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

	Future<ShoppingListModel?> createList({
		required String name,
		required DateTime planDate,
	}) async {
		final res = await ApiClient.post(
			'/shopping/lists',
			{
				'name': name,
				'planDate': planDate.toUtc().toIso8601String(),
			},
			auth: true,
		);
		if (res.statusCode != 201) {
			throw Exception(_extractError(res));
		}
		final data = jsonDecode(res.body);
		if (data is Map<String, dynamic>) {
			final list = _listFromApi(data);
			_lists.insert(0, list);
			notifyListeners();
			return list;
		}
		return null;
	}

	Future<void> _createItem({
		required String listId,
		required String name,
		required double quantity,
		required String unit,
	}) async {
		final res = await ApiClient.post(
			'/shopping/lists/$listId/items',
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
			final listIndex = _lists.indexWhere((e) => e.id == listId);
			if (listIndex != -1) {
				final current = _lists[listIndex];
				_lists[listIndex] = current.copyWith(
					itemCount: current.itemCount + 1,
				);
			}
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
				_updateListCountsFromItems();
				notifyListeners();
			}
		}
	}

	void _updateListCountsFromItems() {
		if (_activeListId == null) return;
		final listIndex = _lists.indexWhere((e) => e.id == _activeListId);
		if (listIndex == -1) return;
		final completed = _items.where((e) => e.isChecked).length;
		final total = _items.length;
		final current = _lists[listIndex];
		_lists[listIndex] = current.copyWith(
			itemCount: total,
			completedCount: completed,
		);
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
			groupTitle: 'Cần mua',
			sourceDetail: 'Thủ công',
			isChecked: item['isChecked'] == true,
		);
	}

	ShoppingListModel _listFromApi(Map<String, dynamic> data) {
		final planDateValue = (data['planDate'] ?? '').toString();
		final parsedDate = planDateValue.isNotEmpty
			? DateTime.tryParse(planDateValue)
			: null;
		return ShoppingListModel(
			id: (data['id'] ?? '').toString(),
			name: (data['name'] ?? '').toString(),
			planDate: (parsedDate ?? DateTime.now()).toLocal(),
			isCompleted: data['isCompleted'] == true,
			itemCount: data['itemCount'] is num ? data['itemCount'] as int : 0,
			completedCount: data['completedCount'] is num
					? data['completedCount'] as int
					: 0,
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