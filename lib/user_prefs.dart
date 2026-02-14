import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return sp.getBool(_kEnableAfternoon) ?? false;
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
    final h = sp.getInt(_kMorningHour) ?? 7;
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
    final h = sp.getInt(_kAfternoonHour) ?? 14;
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


// Si tu veux persister le dernier template choisi :
  Future<void> _saveTemplateChoice() async {
    // UserPrefs.instance.setString('lastTemplate', _selectedTemplate.name);
    // Ajoute des helpers similaires à tes favoris si besoin.
  }

  Future<void> _restoreTemplateChoice() async {
    // final name = await UserPrefs.instance.getString('lastTemplate');
    // if (name != null) _selectedTemplate = PremiumTemplate.values.firstWhere(
    //   (e) => e.name == name, orElse: () => PremiumTemplate.darkLuxe,
    // );
  }

}