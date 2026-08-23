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
  static const _kEnableAfternoon = 'enableAfternoon';
  static const _kEnableEvening = 'enableEvening';

  static Future<void> saveFavoriteText(int id, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fav_text_$id', text);
  }

  static Future<String?> getFavoriteText(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fav_text_$id');
  }

  // Heures/Horaires
  static const _kMorningHour = 'morningHour';
  static const _kMorningMinute = 'morningMinute';
  static const _kAfternoonHour = 'afternoonHour';
  static const _kAfternoonMinute = 'afternoonMinute';
  static const _kEveningHour = 'eveningHour';
  static const _kEveningMinute = 'eveningMinute';

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

  Future<bool> getAfternoonEnabled() async {
    final sp = await _prefs();
    return sp.getBool(_kEnableAfternoon) ?? true;
  }

  Future<void> setAfternoonEnabled(bool v) async {
    final sp = await _prefs();
    await sp.setBool(_kEnableAfternoon, v);
  }

  Future<bool> getEveningEnabled() async {
    final sp = await _prefs();
    return sp.getBool(_kEnableEvening) ?? true;
  }

  Future<void> setEveningEnabled(bool v) async {
    final sp = await _prefs();
    await sp.setBool(_kEnableEvening, v);
  }

  // ---- Alias backward-compat (ton ancien naming) ----
  Future<void> setEnableMorning(bool v) => setMorningEnabled(v);
  Future<bool> getEnableMorning() => getMorningEnabled();

  Future<void> setEnableAfternoon(bool v) => setAfternoonEnabled(v);
  Future<bool> getEnableAfternoon() => getAfternoonEnabled();

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

  Future<void> setAfternoonTime(TimeOfDay t) async {
    final sp = await _prefs();
    await sp.setInt(_kAfternoonHour, t.hour);
    await sp.setInt(_kAfternoonMinute, t.minute);
  }

  Future<TimeOfDay> getAfternoonTime() async {
    final sp = await _prefs();
    final h = sp.getInt(_kAfternoonHour) ?? 15;
    final m = sp.getInt(_kAfternoonMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> setEveningTime(TimeOfDay t) async {
    final sp = await _prefs();
    await sp.setInt(_kEveningHour, t.hour);
    await sp.setInt(_kEveningMinute, t.minute);
  }

  Future<TimeOfDay> getEveningTime() async {
    final sp = await _prefs();
    final h = sp.getInt(_kEveningHour) ?? 20;
    final m = sp.getInt(_kEveningMinute) ?? 0;
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

  // ============================================================
  // 🎨 PERSON NAME
  // ============================================================

  static Future<void> savePersonName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('person_name', name);
  }

  static Future<String?> getPersonName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('person_name');
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
    prefs.setString('persons_data', jsonEncode(data));
  }

  static Future<Map<String, String>> getPersonsData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('persons_data');

    if (jsonStr == null) return {};

    return Map<String, String>.from(jsonDecode(jsonStr));
  }

}