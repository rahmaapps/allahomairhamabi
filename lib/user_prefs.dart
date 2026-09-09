import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Gestion centralisée des préférences utilisateur.
/// - Singleton : UserPrefs.instance  (et compat UserPrefs())
/// - Cache l'instance SharedPreferences pour de meilleures perfs.
/// - Fournit des alias pour compatibilité avec du code existant.
class UserPrefs {
  // -----------------------------
  // Singleton + compatibilité
  // -----------------------------
  static final UserPrefs instance = UserPrefs._internal();
  factory UserPrefs() => instance;
  UserPrefs._internal();

  // -----------------------------
  // Cache SharedPreferences
  // -----------------------------
  SharedPreferences? _sp;
  Future<SharedPreferences> _prefs() async {
    return _sp ??= await SharedPreferences.getInstance();
  }

  // -----------------------------
  // Clés : cohérence & compat
  // -----------------------------
  // Switchs (nous conservons les clés existantes de ton fichier)
  static const _kEnableMorning = 'enableMorning';
  static const _kEnableEvening = 'enableEvening';
  // LOT 3.G — تذكير الجمعة : switch seul, heure fixe non persistée (09:00).
  static const _kEnableFriday = 'enableFriday';

  static Future<void> saveFavoriteText(int id, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fav_text_$id', text);
  }

  static Future<String?> getFavoriteText(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fav_text_$id');
  }

  // Heures/Horaires — LOT 3.G : seule تذكير الصباح garde une heure
  // configurable et persistée (المساء et الجمعة sont fixes en dur, non
  // persistées : 20:00 et 09:00, voir settings_screen.dart).
  static const _kMorningHour = 'morningHour';
  static const _kMorningMinute = 'morningMinute';

  // Filtre longueur
  static const _kLengthFilter = 'length_filter'; // (déjà utilisée)

  // Favoris
  static const _kFavoriteIds = 'favorite_dua_ids';

  // Thème
  static const _kThemeMode = 'theme_mode'; // "light" | "dark" | "system"

  // ============================================================
  // 🔔 NOTIFICATIONS — SWITCHS
  // ============================================================
  Future<bool> getMorningEnabled() async {
    final sp = await _prefs();
    return sp.getBool(_kEnableMorning) ?? true;
  }

  Future<void> setMorningEnabled(bool v) async {
    final sp = await _prefs();
    await sp.setBool(_kEnableMorning, v);
  }

  Future<bool> getEveningEnabled() async {
    final sp = await _prefs();
    return sp.getBool(_kEnableEvening) ?? true;
  }

  Future<void> setEveningEnabled(bool v) async {
    final sp = await _prefs();
    await sp.setBool(_kEnableEvening, v);
  }

  /// LOT 3.G — nouveau rappel, absent avant ce lot : défaut `false` pour ne
  /// jamais activer silencieusement une notification supplémentaire chez un
  /// utilisateur existant qui ne l'a jamais demandée.
  Future<bool> getFridayEnabled() async {
    final sp = await _prefs();
    return sp.getBool(_kEnableFriday) ?? false;
  }

  Future<void> setFridayEnabled(bool v) async {
    final sp = await _prefs();
    await sp.setBool(_kEnableFriday, v);
  }

  // ---- Alias backward-compat (ton ancien naming) ----
  Future<void> setEnableMorning(bool v) => setMorningEnabled(v);
  Future<bool> getEnableMorning() => getMorningEnabled();

  Future<void> setEnableEvening(bool v) => setEveningEnabled(v);
  Future<bool> getEnableEvening() => getEveningEnabled();

  // ============================================================
  // ⏰ NOTIFICATIONS — HORAIRES
  // ============================================================
  Future<void> setMorningTime(TimeOfDay t) async {
    final sp = await _prefs();
    await sp.setInt(_kMorningHour, t.hour);
    await sp.setInt(_kMorningMinute, t.minute);
  }

  Future<TimeOfDay> getMorningTime() async {
    final sp = await _prefs();
    final h = sp.getInt(_kMorningHour) ?? 9;
    final m = sp.getInt(_kMorningMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  // ============================================================
  // 📏 FILTRE LONGUEUR ('all'|'short'|'long')
  // ============================================================
  Future<void> setLengthFilter(String value) async {
    final sp = await _prefs();
    await sp.setString(_kLengthFilter, value);
  }

  Future<String> getLengthFilter() async {
    final sp = await _prefs();
    return sp.getString(_kLengthFilter) ?? 'all';
  }

  // ============================================================
  // 🖼️ PARTAGE PREMIUM — template sélectionné (§4 Partage Premium :
  // « Persistée (share_template) »). Stocke le nom de l'enum
  // (`PremiumTemplate.name`, ex. "darkLuxe") ; `null` si jamais choisi —
  // à l'appelant de retomber sur Dark Luxe par défaut dans ce cas.
  // ============================================================
  static const _kShareTemplate = 'share_template';

  Future<String?> getShareTemplate() async {
    final sp = await _prefs();
    return sp.getString(_kShareTemplate);
  }

  Future<void> setShareTemplate(String templateName) async {
    final sp = await _prefs();
    await sp.setString(_kShareTemplate, templateName);
  }

  // ============================================================
  // ⭐️ FAVORIS
  // ============================================================
  Future<List<int>> getFavoriteIds() async {
    final sp = await _prefs();
    final list = sp.getStringList(_kFavoriteIds) ?? <String>[];
    return list.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  Future<void> addFavoriteId(int id) async {
    final sp = await _prefs();
    final list = sp.getStringList(_kFavoriteIds) ?? <String>[];
    if (!list.contains(id.toString())) {
      list.add(id.toString());
      await sp.setStringList(_kFavoriteIds, list);
    }
  }

  Future<void> removeFavoriteId(int id) async {
    final sp = await _prefs();
    final list = sp.getStringList(_kFavoriteIds) ?? <String>[];
    list.remove(id.toString());
    await sp.setStringList(_kFavoriteIds, list);
  }

  Future<bool> isFavoriteId(int id) async {
    final ids = await getFavoriteIds();
    return ids.contains(id);
  }

  // Helpers conviviaux
  Future<bool> isFavorite(int id) => isFavoriteId(id);

  Future<void> toggleFavorite(int id) async {
    if (await isFavorite(id)) {
      await removeFavoriteId(id);
    } else {
      await addFavoriteId(id);
    }
  }

  // ============================================================
  // 🎨 THÈME ('light'|'dark'|'system')
  // ============================================================
  Future<void> setThemeMode(String mode) async {
    final sp = await _prefs();
    await sp.setString(_kThemeMode, mode);
  }

  Future<String> getThemeMode() async {
    final sp = await _prefs();
    return sp.getString(_kThemeMode) ?? 'system';
  }

  static Future<void> saveSelectedPersons(List<String> persons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_persons', persons);
  }

  static Future<List<String>> getSelectedPersons() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('selected_persons') ?? ['father'];
  }

  static Future<void> savePersonsData(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persons_data', jsonEncode(data));
  }

  static Future<Map<String, String>> getPersonsData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('persons_data');

    if (jsonStr == null) return {};

    return Map<String, String>.from(jsonDecode(jsonStr));
  }

  // ============================================================
  // 🧹 MIGRATION V1.2 — IDs GLOBAUX (Option A : abandon propre)
  // ============================================================
  // Avant la V1.2, favorite_dua_ids ne contenait que l'ancien id local
  // (1-200), partagé par jusqu'à 11 personnes différentes : un ancien
  // favori est donc intrinsèquement ambigu (impossible de savoir avec
  // certitude à quelle personne il appartenait). Décision produit validée :
  // aucune résolution automatique (pas de matching approximatif, pas
  // d'attribution par défaut au père) — les anciens favoris sont effacés
  // proprement une seule fois, via un numéro de schéma idempotent.
  static const _kSchemaVersion = 'dua_id_schema_version';
  static const int currentDuaIdSchemaVersion = 2;

  /// Retourne true si une migration a effectivement eu lieu (favoris
  /// existants effacés), pour permettre d'en informer l'utilisateur une
  /// seule fois. Idempotent : no-op si déjà exécutée.
  static Future<bool> migrateFavoritesToGlobalIdsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kSchemaVersion) ?? 1;

    if (current >= currentDuaIdSchemaVersion) return false;

    final oldFavoriteIds = prefs.getStringList(_kFavoriteIds) ?? const <String>[];
    final favTextKeys =
        prefs.getKeys().where((k) => k.startsWith('fav_text_')).toList();
    final hadData = oldFavoriteIds.isNotEmpty || favTextKeys.isNotEmpty;

    for (final k in favTextKeys) {
      await prefs.remove(k);
    }
    await prefs.remove(_kFavoriteIds);

    await prefs.setInt(_kSchemaVersion, currentDuaIdSchemaVersion);

    return hadData;
  }

}