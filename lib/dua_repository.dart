import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'models/dua.dart';

class DuaRepository {
  final Random _rand = Random();

  Map<String, dynamic>? _cache;

  // ===============================
  // ✅ LOAD JSON + CACHE
  // ===============================
  Future<Map<String, dynamic>> _loadJson() async {
    if (_cache != null) return _cache!;

    final jsonStr = await rootBundle.loadString('assets/data/duas.json');
    _cache = jsonDecode(jsonStr);
    return _cache!;
  }

  // ===============================
  // ✅ FLATTEN JSON → LIST<Dua>
  // ===============================
  Future<List<Dua>> _getAllDuas() async {
    final data = await _loadJson();

    List<Dua> result = [];

    for (var person in data.values) {
      if (person is Map<String, dynamic>) {
        for (var categoryList in person.values) {
          if (categoryList is List) {
            result.addAll(categoryList.map((e) =>
                Dua.fromJson(Map<String, dynamic>.from(e))));
          }
        }
      }
    }

    return result;
  }

  // ===============================
  // ✅ FILTER LENGTH
  // ===============================
  bool _matchLength(Dua d, String filter) {
    if (filter == 'all') return true;

    final len = d.length.trim();

    if (filter == 'short') return len == 'قصيرة';
    if (filter == 'long') return len == 'طويلة';

    return true;
  }

  // ===============================
  // ✅ FILTER CATEGORY
  // ===============================
  bool _matchCategory(Dua d, String filter) {
    if (filter == 'all') return true;

    final c = d.category.trim().toLowerCase();

    if (filter == 'normal') return c == 'normal';
    if (filter == 'friday') return c == 'friday';
    if (filter == 'grave_visit') return c == 'grave_visit';

    return true;
  }

  // ===============================
  // ✅ LIST FILTERED
  // ===============================
  Future<List<Dua>> loadFiltered({
    required String lengthFilter,
    required String categoryFilter,
  }) async {
    final all = await _getAllDuas();

    // ✅ filtre principal
    List<Dua> filtered = all.where((d) {
      return _matchLength(d, lengthFilter) &&
          _matchCategory(d, categoryFilter);
    }).toList();

    // ✅ fallback 1 → ignorer catégorie
    if (filtered.isEmpty && categoryFilter != 'all') {
      filtered = all.where((d) {
        return _matchLength(d, lengthFilter);
      }).toList();
    }

    // ✅ fallback 2 → ignorer longueur
    if (filtered.isEmpty) {
      filtered = all.where((d) {
        return _matchCategory(d, categoryFilter);
      }).toList();
    }

    return filtered;
  }

  // ===============================
  // ✅ RANDOM FILTERED
  // ===============================
  Future<Dua?> getRandomDuaFiltered({
    required String lengthFilter,
    required String categoryFilter,
  }) async {
    final list = await loadFiltered(
      lengthFilter: lengthFilter,
      categoryFilter: categoryFilter,
    );

    if (list.isEmpty) return null;

    return list[_rand.nextInt(list.length)];
  }

  // ===============================
  // ✅ GET BY ID
  // ===============================
  Future<Dua?> getById(int id) async {
    final all = await _getAllDuas();

    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===============================
  // ✅ GET JSON COMPLET (si besoin ailleurs)
  // ===============================
  Future<Map<String, dynamic>> getFullJson() async {
    return await _loadJson();
  }

  // ===============================
// ✅ GET ALL DUAS (utilisé par search & favorites)
// ===============================
  Future<List<Dua>> getAllDuas() async {
    return await _getAllDuas();
  }
}