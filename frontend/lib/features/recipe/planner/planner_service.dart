import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
	String get label {
		switch (this) {
			case MealType.breakfast:
				return 'Bữa sáng';
			case MealType.lunch:
				return 'Bữa trưa';
			case MealType.dinner:
				return 'Bữa tối';
			case MealType.snack:
				return 'Bữa phụ';
		}
	}

	IconData get icon {
		switch (this) {
			case MealType.breakfast:
				return Icons.free_breakfast;
			case MealType.lunch:
				return Icons.lunch_dining;
			case MealType.dinner:
				return Icons.dinner_dining;
			case MealType.snack:
				return Icons.cookie;
		}
	}

	String get apiValue => name;

	static MealType fromApi(String value) {
		switch (value.toLowerCase()) {
			case 'breakfast':
				return MealType.breakfast;
			case 'lunch':
				return MealType.lunch;
			case 'dinner':
				return MealType.dinner;
			case 'snack':
				return MealType.snack;
			default:
				return MealType.lunch;
		}
	}
}

class MealPlanEntry {
	final String id;
	final DateTime date;
	final MealType mealType;
	final String recipeName;
	final int servings;
	final String? note;

	const MealPlanEntry({
		required this.id,
		required this.date,
		required this.mealType,
		required this.recipeName,
		required this.servings,
		this.note,
	});

	MealPlanEntry copyWith({
		DateTime? date,
		MealType? mealType,
		String? recipeName,
		int? servings,
		String? note,
	}) {
		return MealPlanEntry(
			id: id,
			date: date ?? this.date,
			mealType: mealType ?? this.mealType,
			recipeName: recipeName ?? this.recipeName,
			servings: servings ?? this.servings,
			note: note ?? this.note,
		);
	}
}

class PlannerService extends ChangeNotifier {
	static final PlannerService instance = PlannerService._();

	PlannerService._();

	final List<MealPlanEntry> _entries = [];

	List<MealPlanEntry> get entries => List.unmodifiable(_entries);

	bool _loading = false;
	bool get isLoading => _loading;

	DateTime normalizeDate(DateTime date) {
		return DateTime(date.year, date.month, date.day);
	}

	DateTime weekStartFor(DateTime date) {
		final normalized = normalizeDate(date);
		return normalized.subtract(Duration(days: normalized.weekday - 1));
	}

	List<DateTime> daysOfWeek(DateTime weekStart) {
		return List.generate(7, (index) => weekStart.add(Duration(days: index)));
	}

	List<MealPlanEntry> entriesForDate(DateTime date) {
		final target = normalizeDate(date);
		final filtered = _entries.where((entry) {
			return normalizeDate(entry.date) == target;
		}).toList();
		filtered.sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
		return filtered;
	}

	List<MealPlanEntry> entriesForWeek(DateTime weekStart) {
		final start = normalizeDate(weekStart);
		final end = start.add(const Duration(days: 6));
		final filtered = _entries.where((entry) {
			final date = normalizeDate(entry.date);
			return !date.isBefore(start) && !date.isAfter(end);
		}).toList();
		filtered.sort((a, b) => a.date.compareTo(b.date));
		return filtered;
	}

	void addEntry(MealPlanEntry entry) {
		_entries.add(entry);
		notifyListeners();
	}

	void updateEntry(MealPlanEntry entry) {
		final index = _entries.indexWhere((e) => e.id == entry.id);
		if (index == -1) return;
		_entries[index] = entry;
		notifyListeners();
	}

	void deleteEntry(String id) {
		_entries.removeWhere((entry) => entry.id == id);
		notifyListeners();
	}

	String createId() => DateTime.now().microsecondsSinceEpoch.toString();

	Future<void> loadWeek(DateTime weekStart) async {
		if (_loading) return;
		_loading = true;
		notifyListeners();
		try {
			final start = normalizeDate(weekStart);
			final end = start.add(const Duration(days: 6));
			final res = await ApiClient.get(
				'/planner',
				auth: true,
				queryParameters: {
					'from': start.toIso8601String(),
					'to': end.toIso8601String(),
				},
			);
			if (res.statusCode != 200) {
				throw Exception(_extractError(res));
			}
			final data = jsonDecode(res.body);
			final items = <MealPlanEntry>[];
			if (data is List) {
				for (final item in data) {
					if (item is Map<String, dynamic>) {
						items.add(_fromApi(item));
					}
				}
			}
			_entries
				..clear()
				..addAll(items);
			notifyListeners();
		} finally {
			_loading = false;
			notifyListeners();
		}
	}

	Future<void> createPlan(MealPlanEntry entry) async {
		final res = await ApiClient.post(
			'/planner',
			{
				'date': normalizeDate(entry.date).toIso8601String(),
				'mealType': entry.mealType.apiValue,
				'recipeName': entry.recipeName,
				'servings': entry.servings,
				'note': entry.note,
			},
			auth: true,
		);
		if (res.statusCode != 201) {
			throw Exception(_extractError(res));
		}
		final data = jsonDecode(res.body);
		if (data is Map<String, dynamic>) {
			addEntry(_fromApi(data));
		}
	}

	Future<void> updatePlan(MealPlanEntry entry) async {
		final res = await ApiClient.put(
			'/planner/${entry.id}',
			{
				'date': normalizeDate(entry.date).toIso8601String(),
				'mealType': entry.mealType.apiValue,
				'recipeName': entry.recipeName,
				'servings': entry.servings,
				'note': entry.note,
			},
			auth: true,
		);
		if (res.statusCode != 200) {
			throw Exception(_extractError(res));
		}
		final data = jsonDecode(res.body);
		if (data is Map<String, dynamic>) {
			updateEntry(_fromApi(data));
		}
	}

	Future<void> removePlan(String id) async {
		final res = await ApiClient.delete(
			'/planner/$id',
			auth: true,
		);
		if (res.statusCode != 204) {
			throw Exception(_extractError(res));
		}
		deleteEntry(id);
	}

	MealPlanEntry _fromApi(Map<String, dynamic> item) {
		return MealPlanEntry(
			id: (item['id'] ?? '').toString(),
			date: DateTime.parse(item['date'] as String),
			mealType: MealTypeX.fromApi(item['mealType'] as String),
			recipeName: (item['recipeName'] ?? '').toString(),
			servings: item['servings'] is int
					? item['servings'] as int
					: int.tryParse(item['servings'].toString()) ?? 1,
			note: item['note']?.toString(),
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