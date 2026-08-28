import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'models/dua.dart';

class DuaRepository {
  final Random _rand = Random();

  Map<String, dynamic>? _cache;
  List<Dua>? _allCache;
  Map<int, Dua>? _indexCache;

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
  // ✅ FLATTEN JSON → LIST<Dua> + INDEX PAR ID (V1.2)
  // ===============================
  // Construit la liste aplatie ET l'index id→Dua en une seule passe.
  // Chaque Dua connaît sa personne d'origine (personKey), dérivée de sa
  // position dans l'arbre personne→catégorie→liste (jamais stockée dans le
  // JSON lui-même). Depuis la migration V1.2, les ids sont garantis
  // globalement uniques (voir docs/duas_id_migration_manifest.json) : toute
  // collision détectée ici est une régression de données et doit échouer
  // explicitement plutôt que de silencieusement masquer un dou'a.
  Future<void> _ensureLoaded() async {
    if (_allCache != null && _indexCache != null) return;

    final data = await _loadJson();
    final all = <Dua>[];
    final index = <int, Dua>{};

    data.forEach((personKey, categories) {
      if (categories is! Map<String, dynamic>) return;
      categories.forEach((category, list) {
        if (list is! List) return;
        for (final raw in list) {
          final dua = Dua.fromJson(
            Map<String, dynamic>.from(raw),
            personKey: personKey,
          );
          final existing = index[dua.id];
          if (existing != null) {
            throw StateError(
              "Collision d'id de dou'a : id=${dua.id} existe à la fois pour "
              "${existing.personKey}/${existing.category} et "
              "${dua.personKey}/${dua.category}. Les ids doivent être "
              "globalement uniques (voir docs/duas_id_migration_manifest.json).",
            );
          }
          index[dua.id] = dua;
          all.add(dua);
        }
      });
    });

    _allCache = all;
    _indexCache = index;
  }

  Future<List<Dua>> _getAllDuas() async {
    await _ensureLoaded();
    return _allCache!;
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
  // ✅ FILTER FOR SELECTED PERSONS (personsData + catégorie active réelle)
  // ===============================
  // Contrairement à loadFiltered() (qui aplatit TOUTES les personnes du
  // JSON), cette méthode interroge directement data[personne][catégorie],
  // exactement comme le fait déjà _loadRandomDua() dans home_screen.dart.
  // Le repli sur 'normal' n'intervient que si la catégorie demandée est
  // vide pour CES personnes précises — jamais un repli global sur 'all'
  // qui mélangerait les catégories entre elles.
  Future<List<Dua>> loadFilteredForPersons({
    required List<String> personKeys,
    required String lengthFilter,
    required String categoryFilter,
  }) async {
    final data = await _loadJson();
    final keys = personKeys.isEmpty ? ['general'] : personKeys;

    List<Dua> collectByCategory(String category) {
      final result = <Dua>[];
      for (final key in keys) {
        final person = data[key];
        if (person is! Map<String, dynamic>) continue;

        if (category == 'all') {
          for (final categoryList in person.values) {
            if (categoryList is List) {
              result.addAll(categoryList.map((e) => Dua.fromJson(
                    Map<String, dynamic>.from(e),
                    personKey: key,
                  )));
            }
          }
        } else {
          final categoryList = person[category];
          if (categoryList is List) {
            result.addAll(categoryList.map((e) => Dua.fromJson(
                  Map<String, dynamic>.from(e),
                  personKey: key,
                )));
          }
        }
      }
      return result;
    }

    List<Dua> pool = collectByCategory(categoryFilter);

    // ✅ repli : uniquement si la catégorie demandée est vide pour ces personnes
    if (pool.isEmpty && categoryFilter != 'normal' && categoryFilter != 'all') {
      pool = collectByCategory('normal');
    }

    final filtered = pool.where((d) => _matchLength(d, lengthFilter)).toList();

    return filtered.isNotEmpty ? filtered : pool;
  }

  Future<Dua?> getRandomDuaFilteredForPersons({
    required List<String> personKeys,
    required String lengthFilter,
    required String categoryFilter,
  }) async {
    final list = await loadFilteredForPersons(
      personKeys: personKeys,
      lengthFilter: lengthFilter,
      categoryFilter: categoryFilter,
    );

    if (list.isEmpty) return null;

    return list[_rand.nextInt(list.length)];
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
  // ✅ GET BY ID (V1.2 — résolution O(1) via l'index, jamais "premier trouvé")
  // ===============================
  Future<Dua?> getById(int id) async {
    await _ensureLoaded();
    return _indexCache![id];
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