// lib/dua_repository.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

import 'models/dua.dart';

class DuaRepository {
  final _rand = Random();

  /// Charge et convertit entièrement le JSON → List<Dua>
  Future<List<Dua>> _loadAllDuas() async {
    final jsonStr = await rootBundle.loadString('assets/data/duas.json');
    final raw = jsonDecode(jsonStr);

    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => Dua.fromJson(e))
          .toList();
    }

    return [];
  }

  /// Renvoie toutes les dou‘a
  Future<List<Dua>> getAllDuas() => _loadAllDuas();

  // ————————————————————————————————————
  // 🔎 Gestion du filtre LENGTH (TON JSON en arabe)
  // ————————————————————————————————————
  bool _matchLength(Dua d, String filter) {
    final raw = d.length.trim(); // "قصيرة" ou "طويلة"

    final isShort = raw == 'قصيرة';
    final isLong = raw == 'طويلة';

    switch (filter) {
      case 'short':
        return isShort;
      case 'long':
        return isLong;
      default:
        return true; // all
    }
  }

  // ————————————————————————————————————
  // 🔎 Gestion du filtre CATEGORY (normal / friday / ramadan)
  // ————————————————————————————————————
  bool _matchCategory(Dua d, String filter) {
    final c = d.category.trim().toLowerCase();
    final f = filter.trim().toLowerCase();

    // Exemple JSON :
    // "category": "normal"
    // "category": "friday"
    // "category": "ramadan"

    return c == f;
  }

  // ————————————————————————————————————
  // 📌 Liste filtrée selon longueur + catégorie
  // ————————————————————————————————————
  Future<List<Dua>> loadFiltered({
    required String lengthFilter,   // "all" | "short" | "long"
    required String categoryFilter, // "normal" | "friday" | "ramadan"
  }) async {
    final all = await _loadAllDuas();


    return all.where((d) {
      final okLength = _matchLength(d, lengthFilter);
      final okCat = _matchCategory(d, categoryFilter);
      return okLength && okCat;
    }).toList();
  }

  // ————————————————————————————————————
  // ✨ Dou‘a aléatoire selon longueur + catégorie
  // ————————————————————————————————————
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

  // ————————————————————————————————————
  // 🔎 Trouver une dou‘a par ID
  // ————————————————————————————————————
  Future<Dua?> getById(int id) async {
    final all = await _loadAllDuas();
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  // ————————————————————————————————————
  // ⭐ Convertir une liste d'IDs favoris en vrais objets Dua
  // ————————————————————————————————————
  Future<List<Dua>> resolveFavorites(List<int> ids) async {
    final all = await _loadAllDuas();
    return all.where((d) => ids.contains(d.id)).toList();
  }
}