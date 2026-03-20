import 'dart:async';
import 'dart:convert';
import 'package:frontend/features/shopping/shopping_service.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodayIngredient {
	final String name;
	final double quantity;
	final String unit;

	const TodayIngredient({
		required this.name,
		required this.quantity,
		required this.unit,
	});

	String get key => '${name.toLowerCase()}_${unit.toLowerCase()}';

	Map<String, dynamic> toJson() => {
		'name': name,
		'quantity': quantity,
		'unit': unit,
	};

	static TodayIngredient fromJson(Map<String, dynamic> json) {
		return TodayIngredient(
			name: (json['name'] ?? '').toString(),
			quantity: json['quantity'] is num
					? (json['quantity'] as num).toDouble()
					: double.tryParse(json['quantity'].toString()) ?? 1,
			unit: (json['unit'] ?? '').toString(),
		);
	}
}

class TodayRecipe {
	final String name;
	final int timeMinutes;
	final String imageUrl;
	final List<TodayIngredient> ingredients;
	final List<TodayIngredient> missingIngredients;

	const TodayRecipe({
		required this.name,
		required this.timeMinutes,
		required this.imageUrl,
		required this.ingredients,
		required this.missingIngredients,
	});

	Map<String, dynamic> toJson() => {
		'name': name,
		'timeMinutes': timeMinutes,
		'imageUrl': imageUrl,
		'ingredients': ingredients.map((e) => e.toJson()).toList(),
		'missingIngredients': missingIngredients.map((e) => e.toJson()).toList(),
	};

	static TodayRecipe fromJson(Map<String, dynamic> json) {
		final ingredientsRaw = json['ingredients'] is List
				? json['ingredients'] as List
				: const [];
		final missingRaw = json['missingIngredients'] is List
				? json['missingIngredients'] as List
				: const [];
		return TodayRecipe(
			name: (json['name'] ?? '').toString(),
			timeMinutes: json['timeMinutes'] is int
					? json['timeMinutes'] as int
					: int.tryParse(json['timeMinutes'].toString()) ?? 30,
			imageUrl: (json['imageUrl'] ?? '').toString(),
			ingredients: ingredientsRaw
					.whereType<Map<String, dynamic>>()
					.map(TodayIngredient.fromJson)
					.toList(),
			missingIngredients: missingRaw
					.whereType<Map<String, dynamic>>()
					.map(TodayIngredient.fromJson)
					.toList(),
		);
	}
}

enum TodayTabType { full, near }

class TodayService extends ChangeNotifier {
		Future<void> loadHealthyRecipes() async {
			_loading = true;
			_loadingTab = TodayTabType.near;
			notifyListeners();
			await Future.delayed(const Duration(milliseconds: 300));
			_near = [
				TodayRecipe(
					name: 'Salad cá hồi',
					timeMinutes: 20,
					imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
					ingredients: [
						TodayIngredient(name: 'Cá hồi', quantity: 150, unit: 'g'),
						TodayIngredient(name: 'Rau xà lách', quantity: 1, unit: 'bó'),
						TodayIngredient(name: 'Dầu olive', quantity: 1, unit: 'muỗng'),
					],
					missingIngredients: [],
				),
				TodayRecipe(
					name: 'Súp bí đỏ',
					timeMinutes: 30,
					imageUrl: 'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=1200&q=80',
					ingredients: [
						TodayIngredient(name: 'Bí đỏ', quantity: 200, unit: 'g'),
						TodayIngredient(name: 'Sữa tươi', quantity: 100, unit: 'ml'),
						TodayIngredient(name: 'Hành tây', quantity: 1, unit: 'củ'),
					],
					missingIngredients: [],
				),
				TodayRecipe(
					name: 'Ức gà áp chảo',
					timeMinutes: 25,
					imageUrl: 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=1200&q=80',
					ingredients: [
						TodayIngredient(name: 'Ức gà', quantity: 200, unit: 'g'),
						TodayIngredient(name: 'Bông cải xanh', quantity: 100, unit: 'g'),
						TodayIngredient(name: 'Dầu olive', quantity: 1, unit: 'muỗng'),
					],
					missingIngredients: [],
				),
			];
			_selectedNearIndex = _near.isEmpty ? -1 : 0;
			_loading = false;
			_loadingTab = null;
			notifyListeners();
		}
	static final TodayService instance = TodayService._();
	static const bool _enableFallback = false;
	static const int _fullMax = 3;
	static const int _nearMax = 3;

	TodayService._();

	List<TodayRecipe> _full = [];
	List<TodayRecipe> _near = [];
	bool _loading = false;
	String? _error;
	TodayTabType? _loadingTab;
	final Set<TodayTabType> _loadedTabs = {};
	final Map<TodayTabType, String?> _tabErrors = {};
	SharedPreferences? _prefs;
	int _selectedFullIndex = -1;
	int _selectedNearIndex = -1;
	String _activeDateKey = _todayKey();

	List<TodayRecipe> get fullRecipes => List.unmodifiable(_full);
	List<TodayRecipe> get nearRecipes => List.unmodifiable(_near);
	bool get isLoading => _loading;
	String? get error => _error;

	bool isLoadingFor(TodayTabType tab) => _loading && _loadingTab == tab;
	String? errorFor(TodayTabType tab) => _tabErrors[tab];

	int selectedIndex(TodayTabType tab) {
		switch (tab) {
			case TodayTabType.full:
				return _selectedFullIndex;
			case TodayTabType.near:
				return _selectedNearIndex;
		}
	}

	TodayRecipe? selectedRecipe(TodayTabType tab) {
		final list = tab == TodayTabType.full
				? _full
				: _near;
		final index = selectedIndex(tab);
		if (index < 0 || index >= list.length) return null;
		return list[index];
	}

	Future<void> loadTab(TodayTabType tab, {bool refresh = false}) async {
		_syncDailyStateIfNeeded();
		if (_loading) return;
		if (!refresh && _loadedTabs.contains(tab)) return;
		_loading = true;
		_loadingTab = tab;
		_tabErrors[tab] = null;
		notifyListeners();
		try {
			if (refresh) {
				await _refreshUntilChanged(tab);
			} else {
				await _loadSuggestionsNonStream(tab: tab, refresh: false);
			}
			_loadedTabs.add(tab);
		} catch (err) {
			_tabErrors[tab] = err.toString();
			_error = err.toString();
			final restored = await _restoreTabFromCache(tab);
			if (restored) {
				_tabErrors[tab] = null;
				_error = null;
			}
			if (_enableFallback && tab == TodayTabType.full) {
				_useFallback();
			}
		} finally {
			_loading = false;
			_loadingTab = null;
			notifyListeners();
		}
	}

	Future<void> _refreshUntilChanged(TodayTabType tab) async {
		final before = _signature(_tabList(tab));
		for (var attempt = 0; attempt < 2; attempt++) {
			await _loadSuggestionsNonStream(tab: tab, refresh: true);
			final after = _signature(_tabList(tab));
			if (after != before || _tabList(tab).isEmpty) {
				return;
			}
			await Future.delayed(const Duration(milliseconds: 250));
		}
	}

	String _signature(List<TodayRecipe> recipes) {
		return recipes
			.map((r) => r.name.trim().toLowerCase())
			.where((name) => name.isNotEmpty)
			.join('|');
	}

	Future<void> _loadSuggestionsNonStream({
		required TodayTabType tab,
		required bool refresh,
	}) async {
		final res = await ApiClient.get(
			'/recipes/today',
			auth: true,
			queryParameters: {
				'tab': _tabParam(tab),
				if (refresh) 'refresh': 'true'
			},
		);
		if (res.statusCode != 200) {
			throw Exception(_extractError(res));
		}
		final data = jsonDecode(res.body);
		_applyResponse(data, tab);
		await _saveTabCache(tab);
	}



	void _applyResponse(dynamic data, TodayTabType tab) {
		switch (tab) {
			case TodayTabType.full:
				_full = _capList(_parseList(data, 'fullRecipes'), _fullMax);
				// fallback nếu không có dữ liệu
				if (_full.isEmpty) {
					_full = _capList(_parseList(data, 'recipes'), _fullMax);
				}
				_selectedFullIndex = _full.isEmpty ? -1 : 0;
				break;
			case TodayTabType.near:
				_near = _capList(_parseList(data, 'nearRecipes'), _nearMax);
				// fallback nếu không có dữ liệu
				if (_near.isEmpty) {
					_near = _capList(_parseList(data, 'recipes'), _nearMax);
				}
				if (_near.isEmpty) {
					_near = _capList(_parseList(data, 'data'), _nearMax);
				}
				_selectedNearIndex = _near.isEmpty ? -1 : 0;
				break;
		}

		if (_enableFallback && _tabList(tab).isEmpty) {
			_applyFallbackForTab(tab);
		}
	}

	void _applyFallbackForTab(TodayTabType tab) {
		_useFallback();
		switch (tab) {
			case TodayTabType.full:
				_near = [];
				_selectedNearIndex = -1;
				break;
			case TodayTabType.near:
				_full = [];
				_selectedFullIndex = -1;
				break;
		}
	}

	Future<void> _saveTabCache(TodayTabType tab) async {
		_prefs ??= await SharedPreferences.getInstance();
		final key = _cacheKey(tab);
		final list = _tabList(tab).map((e) => e.toJson()).toList();
		await _prefs!.setString(key, jsonEncode(list));
	}

	Future<bool> _restoreTabFromCache(TodayTabType tab) async {
		_prefs ??= await SharedPreferences.getInstance();
		final key = _cacheKey(tab);
		final raw = _prefs!.getString(key);
		if (raw == null || raw.isEmpty) return false;
		try {
			final data = jsonDecode(raw);
			if (data is! List) return false;
			final items = data
					.whereType<Map<String, dynamic>>()
					.map(TodayRecipe.fromJson)
					.toList();
			if (items.isEmpty) return false;
			switch (tab) {
				case TodayTabType.full:
					_full = _capList(items, _fullMax);
					_selectedFullIndex = _full.isEmpty ? -1 : 0;
					break;
				case TodayTabType.near:
					_near = _capList(items, _nearMax);
					_selectedNearIndex = _near.isEmpty ? -1 : 0;
					break;
			}
			notifyListeners();
			return true;
		} catch (_) {
			return false;
		}
	}

	String _cacheKey(TodayTabType tab) => 'today_tab_${_tabParam(tab)}_$_activeDateKey';

	void _syncDailyStateIfNeeded() {
		final current = _todayKey();
		if (current == _activeDateKey) return;
		_activeDateKey = current;
		_loadedTabs.clear();
		_tabErrors.clear();
	}

	static String _todayKey() {
		final now = DateTime.now();
		return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
	}

	List<TodayRecipe> _tabList(TodayTabType tab) {
		switch (tab) {
			case TodayTabType.full:
				return _full;
			case TodayTabType.near:
				return _near;
		}
	}



	String _tabParam(TodayTabType tab) {
		switch (tab) {
			case TodayTabType.full:
				return 'full';
			case TodayTabType.near:
				return 'near';
		}
	}

	List<TodayRecipe> _capList(List<TodayRecipe> items, int max) {
		if (items.length <= max) return items;
		return items.take(max).toList();
	}


	void _useFallback() {
		_error = null;
		_full = [
			TodayRecipe(
				name: 'Gỏi cuốn tôm thịt',
				timeMinutes: 35,
				imageUrl:
					'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=1200&q=80',
				ingredients: const [
					TodayIngredient(name: 'Tôm', quantity: 200, unit: 'g'),
					TodayIngredient(name: 'Thịt heo', quantity: 200, unit: 'g'),
					TodayIngredient(name: 'Bánh tráng', quantity: 10, unit: 'cái'),
					TodayIngredient(name: 'Bún tươi', quantity: 200, unit: 'g'),
					TodayIngredient(name: 'Rau sống', quantity: 1, unit: 'bó'),
				],
				missingIngredients: const [],
			),
			TodayRecipe(
				name: 'Trứng chiên cà chua',
				timeMinutes: 20,
				imageUrl:
					'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
				ingredients: const [
					TodayIngredient(name: 'Trứng gà', quantity: 3, unit: 'quả'),
					TodayIngredient(name: 'Cà chua', quantity: 2, unit: 'quả'),
					TodayIngredient(name: 'Hành', quantity: 1, unit: 'củ'),
				],
				missingIngredients: const [],
			),
			TodayRecipe(
				name: 'Canh rau ngót thịt băm',
				timeMinutes: 25,
				imageUrl:
					'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=1200&q=80',
				ingredients: const [
					TodayIngredient(name: 'Rau ngót', quantity: 1, unit: 'bó'),
					TodayIngredient(name: 'Thịt băm', quantity: 200, unit: 'g'),
				],
				missingIngredients: const [],
			),
		];
		_near = [
			TodayRecipe(
				name: 'Canh chua cá',
				timeMinutes: 40,
				imageUrl:
					'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',
				ingredients: const [
					TodayIngredient(name: 'Cá', quantity: 300, unit: 'g'),
					TodayIngredient(name: 'Dứa', quantity: 200, unit: 'g'),
					TodayIngredient(name: 'Cà chua', quantity: 2, unit: 'quả'),
					TodayIngredient(name: 'Rau thơm', quantity: 1, unit: 'bó'),
				],
				missingIngredients: const [
					TodayIngredient(name: 'Dứa', quantity: 200, unit: 'g'),
				],
			),
			TodayRecipe(
				name: 'Bún bò',
				timeMinutes: 45,
				imageUrl:
					'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=1200&q=80',
				ingredients: const [
					TodayIngredient(name: 'Bún', quantity: 200, unit: 'g'),
					TodayIngredient(name: 'Thịt bò', quantity: 200, unit: 'g'),
					TodayIngredient(name: 'Gia vị', quantity: 1, unit: 'gói'),
				],
				missingIngredients: const [
					TodayIngredient(name: 'Gia vị', quantity: 1, unit: 'gói'),
				],
			),
			TodayRecipe(
				name: 'Cơm tấm sườn',
				timeMinutes: 35,
				imageUrl:
					'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
				ingredients: const [
					TodayIngredient(name: 'Sườn', quantity: 300, unit: 'g'),
					TodayIngredient(name: 'Cơm tấm', quantity: 2, unit: 'bát'),
				],
				missingIngredients: const [
					TodayIngredient(name: 'Cơm tấm', quantity: 2, unit: 'bát'),
				],
			),
		];
		_selectedFullIndex = _full.isEmpty ? -1 : 0;
		_selectedNearIndex = _near.isEmpty ? -1 : 0;
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
				return 'Không thể tải gợi ý.';
		}
	}

	void selectRecipe(TodayTabType tab, int index) {
		switch (tab) {
			case TodayTabType.full:
				_selectedFullIndex = index;
				break;
			case TodayTabType.near:
				_selectedNearIndex = index;
				break;
		}
		notifyListeners();
	}

	void selectNext(TodayTabType tab) {
		final list = tab == TodayTabType.full
				? _full
				: _near;
		if (list.isEmpty) return;
		final nextIndex = (selectedIndex(tab) + 1) % list.length;
		selectRecipe(tab, nextIndex);
	}

	Future<void> cookSelected(TodayTabType tab) async {
		final recipe = selectedRecipe(tab);
		if (recipe == null) return;
		await cookRecipe(recipe);
	}

	Future<void> cookRecipe(TodayRecipe recipe, {bool addMissing = true}) async {
		final missingKeys = recipe.missingIngredients.map((e) => e.key).toSet();
		final availableIngredients = recipe.ingredients
			.where((e) => !missingKeys.contains(e.key))
			.toList();

		final res = await ApiClient.post(
			'/recipes/cook',
			{
				'recipeName': recipe.name,
				'recipeSource': 'AI',
				'ingredients': availableIngredients
					.map((e) => {
						'name': e.name,
						'quantity': e.quantity <= 0 ? 1 : e.quantity,
						'unit': e.unit,
					})
					.toList(),
			},
			auth: true,
		);
		if (res.statusCode != 200) {
			throw Exception(_extractError(res));
		}

		if (addMissing && recipe.missingIngredients.isNotEmpty) {
			await _addMissingIngredients(recipe.missingIngredients);
		}
	}

	Future<void> addMissingIngredients(List<TodayIngredient> missing, {String? recipeName}) async {
		if (missing.isEmpty) return;
		// Nếu có tên món ăn, tạo shopping list mới
		if (recipeName != null && recipeName.isNotEmpty) {
			final shoppingService = await _getShoppingService();
			final newList = await shoppingService.createList(
				name: recipeName,
				planDate: DateTime.now(),
			);
			if (newList != null) {
				for (final ingredient in missing) {
					final normalizedUnit = ingredient.unit.trim().isEmpty
						? 'phan'
						: ingredient.unit;
					await shoppingService.addManualItem(
						listId: newList.id,
						name: ingredient.name,
						quantity: ingredient.quantity <= 0 ? 1 : ingredient.quantity,
						unit: normalizedUnit,
					);
				}
				return;
			}
		}
		await _addMissingIngredients(missing);
	}

	Future<dynamic> _getShoppingService() async {
		return await Future.value((await importShoppingService()));
	}

	Future<ShoppingService> importShoppingService() async {
		return Future.value(ShoppingService.instance);
	}

	Future<void> addMissingIngredient(TodayIngredient ingredient) async {
		await _addMissingIngredients([ingredient]);
	}

	Future<void> _addMissingIngredients(
		List<TodayIngredient> missing,
	) async {
		final listRes = await ApiClient.get('/shopping', auth: true);
		if (listRes.statusCode != 200) {
			return;
		}
		final data = jsonDecode(listRes.body);
		if (data is! Map<String, dynamic>) return;
		final listId = (data['id'] ?? '').toString();
		if (listId.isEmpty) return;

		final existingKeys = <String>{};
		if (data['items'] is List) {
			for (final item in data['items'] as List) {
				if (item is Map<String, dynamic>) {
					final name = (item['name'] ?? '').toString();
					final unit = (item['unit'] ?? '').toString();
					existingKeys.add('${name.toLowerCase()}_${unit.toLowerCase()}');
				}
			}
		}

		for (final ingredient in missing) {
			if (existingKeys.contains(ingredient.key)) continue;
			await ApiClient.post(
				'/shopping/lists/$listId/items',
				{
					'name': ingredient.name,
					'quantity': ingredient.quantity <= 0 ? 1 : ingredient.quantity,
					'unit': ingredient.unit,
				},
				auth: true,
			);
		}
	}

	List<TodayRecipe> _parseList(dynamic data, String key) {
		final items = <TodayRecipe>[];
		if (data is Map && data[key] is List) {
			for (final item in data[key] as List) {
				if (item is Map<String, dynamic>) {
					items.add(_fromApi(item));
				}
			}
		}
		return items;
	}

	TodayRecipe _fromApi(Map<String, dynamic> item) {
		final ingredients = _parseIngredients(item['ingredients']);
		final missing = _parseIngredients(item['missingIngredients']);
		return TodayRecipe(
			name: (item['name'] ?? '').toString(),
			timeMinutes: item['timeMinutes'] is int
					? item['timeMinutes'] as int
					: int.tryParse(item['timeMinutes'].toString()) ?? 30,
			imageUrl: (item['imageUrl'] ?? '').toString(),
			ingredients: ingredients,
			missingIngredients: missing,
		);
	}

	List<TodayIngredient> _parseIngredients(dynamic data) {
		final items = <TodayIngredient>[];
		if (data is List) {
			for (final item in data) {
				if (item is Map<String, dynamic>) {
					final name = (item['name'] ?? '').toString();
					if (name.isEmpty) continue;
					final quantity = item['quantity'] is num
							? (item['quantity'] as num).toDouble()
							: double.tryParse(item['quantity'].toString()) ?? 1;
					items.add(TodayIngredient(
						name: name,
						quantity: quantity,
						unit: (item['unit'] ?? '').toString(),
					));
				}
			}
		}
		return items;
	}
}