import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class HomeAiRecipe {
	final String name;
	final int timeMinutes;
	final List<String> ingredients;
	final List<String> tags;

	const HomeAiRecipe({
		required this.name,
		required this.timeMinutes,
		required this.ingredients,
		required this.tags,
	});

	int get ingredientCount => ingredients.length;
}

class HomeAiTip {
	final String category;
	final String title;
	final String message;

	const HomeAiTip({
		required this.category,
		required this.title,
		required this.message,
	});
}

class HomeAiService extends ChangeNotifier {
	static final HomeAiService instance = HomeAiService._();

	HomeAiService._();

	bool _loading = false;
	String? _error;
	bool _loaded = false;
	List<HomeAiRecipe> _recipes = [];
	List<HomeAiTip> _tips = [];

	bool get isLoading => _loading;
	String? get error => _error;
	List<HomeAiRecipe> get recipes => List.unmodifiable(_recipes);
	List<HomeAiTip> get tips => List.unmodifiable(_tips);

	Future<void> load({bool refresh = false}) async {
		if (_loading) return;
		if (!refresh && _loaded) return;
		_loading = true;
		_error = null;
		notifyListeners();

		try {
			final res = await ApiClient.get(
				'/home/ai',
				auth: true,
				queryParameters: {
					if (refresh) 'refresh': 'true',
				},
			);
			if (res.statusCode != 200) {
				throw Exception(_extractError(res));
			}

			final data = jsonDecode(res.body);
			if (data is Map<String, dynamic>) {
				_recipes = _parseRecipes(data['recommendedRecipes']);
				_tips = _parseTips(data['storageTips']);
			}
			_loaded = true;
		} catch (err) {
			_error = err.toString();
		} finally {
			_loading = false;
			notifyListeners();
		}
	}

	List<HomeAiRecipe> _parseRecipes(dynamic raw) {
		if (raw is! List) return [];
		final items = <HomeAiRecipe>[];
		for (final item in raw) {
			if (item is! Map<String, dynamic>) continue;
			final name = (item['name'] ?? '').toString();
			if (name.isEmpty) continue;
			final time = item['timeMinutes'] is int
					? item['timeMinutes'] as int
					: int.tryParse(item['timeMinutes'].toString()) ?? 30;
			final ingredientNames = <String>[];
			final ingredientsRaw = item['ingredients'];
			if (ingredientsRaw is List) {
				for (final ing in ingredientsRaw) {
					if (ing is Map<String, dynamic>) {
						final ingName = (ing['name'] ?? '').toString();
						if (ingName.isNotEmpty) ingredientNames.add(ingName);
					}
				}
			}
			final tags = _buildTags(ingredientNames);
			items.add(HomeAiRecipe(
				name: name,
				timeMinutes: time,
				ingredients: ingredientNames,
				tags: tags,
			));
		}
		return items;
	}

	List<HomeAiTip> _parseTips(dynamic raw) {
		if (raw is! List) return [];
		final items = <HomeAiTip>[];
		for (final item in raw) {
			if (item is! Map<String, dynamic>) continue;
			final category = (item['category'] ?? '').toString();
			final title = (item['title'] ?? '').toString();
			final message = (item['message'] ?? '').toString();
			if (category.isEmpty || title.isEmpty || message.isEmpty) continue;
			items.add(HomeAiTip(
				category: category,
				title: title,
				message: message,
			));
		}
		return items;
	}

	List<String> _buildTags(List<String> ingredients) {
		if (ingredients.isEmpty) return const [];
		if (ingredients.length <= 3) return ingredients;
		return [ingredients[0], ingredients[1], '+${ingredients.length - 2}'];
	}

	String _extractError(dynamic res) {
		try {
			final data = jsonDecode(res.body);
			if (data is Map && data['message'] is String) {
				final message = (data['message'] as String).trim();
				if (message.isNotEmpty) return message;
			}
		} catch (_) {}
		switch (res.statusCode) {
			case 401:
				return 'Vui lòng đăng nhập lại.';
			case 400:
				return 'Dữ liệu không hợp lệ.';
			default:
				return 'Không thể tải gợi ý.';
		}
	}
}
