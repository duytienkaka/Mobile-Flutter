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
  HomeAiRecipe? _generatedRecipe;
  bool _generatingRecipe = false;

  bool get isLoading => _loading;
  String? get error => _error;
  List<HomeAiRecipe> get recipes => List.unmodifiable(_recipes);
  List<HomeAiTip> get tips => List.unmodifiable(_tips);
  HomeAiRecipe? get generatedRecipe => _generatedRecipe;
  bool get isGeneratingRecipe => _generatingRecipe;

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
        queryParameters: {if (refresh) 'refresh': 'true'},
      );
      if (res.statusCode != 200) {
        throw Exception(_extractError(res));
      }

      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        _recipes = _parseRecipes(data['recommendedRecipes']);
        _tips = _parseTips(data['storageTips']);
      }

      // Nếu không có món ăn, không gán dữ liệu mẫu nữa
      // Nếu không có tips, vẫn dùng tips mẫu
      if (_tips.isEmpty) {
        _tips = _getDefaultTips();
      }

      _loaded = true;
    } catch (err) {
      _error = err.toString();
      // Nếu không có tips, dùng tips mẫu
      if (_tips.isEmpty) {
        _tips = _getDefaultTips();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> generateRecipeByName(String recipeName) async {
    if (_generatingRecipe) return;
    if (recipeName.trim().isEmpty) return;

    _generatingRecipe = true;
    _generatedRecipe = null;
    notifyListeners();

    try {
      final res = await ApiClient.get(
        '/home/recipe/generate',
        auth: true,
        queryParameters: {'name': recipeName.trim()},
      );

      if (res.statusCode != 200) {
        throw Exception(_extractError(res));
      }

      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        final recipe = _parseRecipe(data);
        if (recipe != null) {
          _generatedRecipe = recipe;
        } else {
          throw Exception('Không thể tạo công thức');
        }
      }
    } catch (err) {
      // fallback locally when API fails
      _generatedRecipe = _localGenerateRecipe(recipeName);
      _error = null; // clear error so UI will show the recipe
    } finally {
      _generatingRecipe = false;
      notifyListeners();
    }
  }

  HomeAiRecipe? _parseRecipe(Map<String, dynamic> item) {
    final name = (item['name'] ?? '').toString();
    if (name.isEmpty) return null;
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
        } else if (ing is String) {
          if (ing.isNotEmpty) ingredientNames.add(ing);
        }
      }
    }
    final tags = _buildTags(ingredientNames);
    return HomeAiRecipe(
      name: name,
      timeMinutes: time,
      ingredients: ingredientNames,
      tags: tags,
    );
  }

  // generate very basic recipe locally when API isn't available
  HomeAiRecipe _localGenerateRecipe(String query) {
    final parts = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final ingredients = <String>[];
    for (var i = 0; i < parts.length && i < 4; i++) {
      ingredients.add(parts[i]);
    }
    if (ingredients.isEmpty) ingredients.add('Nguyên liệu');
    return HomeAiRecipe(
      name: query.trim(),
      timeMinutes: 30,
      ingredients: ingredients,
      tags: _buildTags(ingredients),
    );
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
      items.add(
        HomeAiRecipe(
          name: name,
          timeMinutes: time,
          ingredients: ingredientNames,
          tags: tags,
        ),
      );
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
      items.add(HomeAiTip(category: category, title: title, message: message));
    }
    return items;
  }

  List<String> _buildTags(List<String> ingredients) {
    if (ingredients.isEmpty) return const [];
    if (ingredients.length <= 3) return ingredients;
    return [ingredients[0], ingredients[1], '+${ingredients.length - 2}'];
  }

  // Xóa dữ liệu seed món ăn, chỉ giữ tips mẫu
  // Nếu không có món ăn, UI sẽ hiển thị thông báo

  List<HomeAiTip> _getDefaultTips() {
    return [
      const HomeAiTip(
        category: 'vegetable',
        title: 'Bảo quản rau xanh',
        message:
            'Đặt rau vào túi nhựa và bảo quản ở ngăn dưới tủ lạnh. Thay túi thường xuyên để hạn chế độ ẩm.',
      ),
      const HomeAiTip(
        category: 'fruit',
        title: 'Giải phóng ethylene',
        message:
            'Các loại quả như chuối, lê phát hành ethylene. Đặt chúng riêng biệt để tránh làm nhanh hỏng các loại khác.',
      ),
      const HomeAiTip(
        category: 'meat',
        title: 'Thawing an toàn',
        message:
            'Luôn rã đông thịt trong tủ lạnh trước khi nấu. Tránh để ở nhiệt độ phòng để chống vi khuẩn.',
      ),
      const HomeAiTip(
        category: 'vegetable',
        title: 'Bảo quản khoai tây',
        message:
            'Lưu trữ khoai tây ở nơi tối, mát mẻ. Không để trong tủ lạnh vì sẽ ảnh hưởng đến hương vị.',
      ),
      const HomeAiTip(
        category: 'fruit',
        title: 'Giữ tươi cam',
        message:
            'Cam có thể giữ được 2-4 tuần ở tủ lạnh. Bảo quản trong túi giấy thấm để giảm độ ẩm.',
      ),
    ];
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
