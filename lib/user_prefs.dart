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
  static const _kEnableFriday = 'enableFriday';

  static Future<void> saveFavoriteText(int id, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fav_text_$id', text);
  }

  static Future<String?> getFavoriteText(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fav_text_$id');
  }

  // Heures/Horaires — les 3 rappels (صباح/مساء/جمعة) ont chacun une heure
  // configurable et persistée séparément. Défauts alignés sur les anciennes
  // heures fixes (9:00 / 20:00 / 9:00) pour préserver le comportement des
  // utilisateurs existants n'ayant jamais rien persisté pour مساء/جمعة.
  static const _kMorningHour = 'morningHour';
  static const _kMorningMinute = 'morningMinute';
  static const _kEveningHour = 'eveningHour';
  static const _kEveningMinute = 'eveningMinute';
  static const _kFridayHour = 'fridayHour';
  static const _kFridayMinute = 'fridayMinute';

  // Filtre longueur
  static const _kLengthFilter = 'length_filter'; // (déjà utilisée)

  // Favoris
  static const _kFavoriteIds = 'favorite_dua_ids';

  // Thème
  static const _kThemeMode = 'theme_mode'; // "light" | "dark" | "system"

  // Monétisation — suppression temporaire des publicités (LOT 5.A socle ;
  // affichage réel des publicités et déclenchement Rewarded hors périmètre).
  static const _kAdsSuppressedUntil = 'ads_suppressed_until';

  // Monétisation — dernier interstitiel effectivement présenté (LOT 5.C).
  // Concept DISTINCT de `_kAdsSuppressedUntil` : espacement entre deux
  // interstitiels, pas fenêtre « sans publicité » accordée par un Rewarded.
  static const _kLastInterstitialShownAt = 'last_interstitial_shown_at';

  // Monétisation — autorisation one-shot de Partage comme image gagnée par
  // un Rewarded (LOT 5.G.A). État présent/absent, jamais un compteur :
  // 1 Rewarded = 1 partage (B4).
  static const _kShareAsImageUnlockPending = 'share_as_image_unlock_pending';

  // Évaluation de l'application (LOT 5.D) — date du tout premier usage,
  // écrite UNE SEULE FOIS. Concept distinct de `settings_completed` (fin
  // d'onboarding, progression fonctionnelle) : mesure uniquement
  // l'ancienneté de l'installation. Aucun compteur d'ouvertures, de
  // sessions ni de douʿās n'en est dérivé (décision produit D2).
  static const _kFirstOpenAt = 'first_open_at';

  // Évaluation de l'application (LOT 5.D) — dernière sollicitation émise.
  static const _kLastReviewPromptedAt = 'last_review_prompted_at';

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

  Future<void> setFridayTime(TimeOfDay t) async {
    final sp = await _prefs();
    await sp.setInt(_kFridayHour, t.hour);
    await sp.setInt(_kFridayMinute, t.minute);
  }

  Future<TimeOfDay> getFridayTime() async {
    final sp = await _prefs();
    final h = sp.getInt(_kFridayHour) ?? 9;
    final m = sp.getInt(_kFridayMinute) ?? 0;
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

  // ============================================================
  // 🚫 MONÉTISATION — suppression temporaire des publicités
  // ============================================================
  /// `null` = aucune suppression temporaire active (jamais accordée, ou
  /// expirée). Stockée en `millisecondsSinceEpoch` — persistante entre les
  /// sessions, comme l'exige le socle LOT 5.A.
  Future<DateTime?> getAdsSuppressedUntil() async {
    final sp = await _prefs();
    final millis = sp.getInt(_kAdsSuppressedUntil);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// `null` efface la suppression (ex. après expiration constatée par
  /// l'appelant) ; une valeur non-nulle la (re)définit.
  Future<void> setAdsSuppressedUntil(DateTime? until) async {
    final sp = await _prefs();
    if (until == null) {
      await sp.remove(_kAdsSuppressedUntil);
    } else {
      await sp.setInt(_kAdsSuppressedUntil, until.millisecondsSinceEpoch);
    }
  }

  // ============================================================
  // 🎁 MONÉTISATION — autorisation de Partage comme image (LOT 5.G.A)
  // ============================================================
  /// `true` si une autorisation gagnée par Rewarded n'a pas encore été
  /// consommée. Persistée entre les sessions.
  Future<bool> getShareAsImageUnlockPending() async {
    final sp = await _prefs();
    return sp.getBool(_kShareAsImageUnlockPending) ?? false;
  }

  /// `false` retire la clé (aucune autorisation en attente).
  Future<void> setShareAsImageUnlockPending(bool pending) async {
    final sp = await _prefs();
    if (pending) {
      await sp.setBool(_kShareAsImageUnlockPending, true);
    } else {
      await sp.remove(_kShareAsImageUnlockPending);
    }
  }

  // ============================================================
  // ⏳ MONÉTISATION — cooldown interstitiel (LOT 5.C)
  // ============================================================
  /// Instant de la dernière présentation **effective** d'un interstitiel,
  /// ou `null` si aucun n'a jamais été présenté. Persistant entre les
  /// sessions : le cooldown de 10 minutes survit à un redémarrage de l'app.
  Future<DateTime?> getLastInterstitialShownAt() async {
    final sp = await _prefs();
    final millis = sp.getInt(_kLastInterstitialShownAt);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// `null` réinitialise le cooldown (aucun interstitiel présenté connu).
  Future<void> setLastInterstitialShownAt(DateTime? shownAt) async {
    final sp = await _prefs();
    if (shownAt == null) {
      await sp.remove(_kLastInterstitialShownAt);
    } else {
      await sp.setInt(_kLastInterstitialShownAt, shownAt.millisecondsSinceEpoch);
    }
  }

  // ============================================================
  // ⭐ ÉVALUATION DE L'APPLICATION (LOT 5.D)
  // ============================================================
  /// Date du tout premier usage, ou `null` si jamais enregistrée. Sert
  /// uniquement au critère d'ancienneté (≥ 7 jours) avant une éventuelle
  /// demande d'évaluation. Stockée en `millisecondsSinceEpoch`, comme les
  /// autres dates de ce fichier.
  Future<DateTime?> getFirstOpenAt() async {
    final sp = await _prefs();
    final millis = sp.getInt(_kFirstOpenAt);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setFirstOpenAt(DateTime? at) async {
    final sp = await _prefs();
    if (at == null) {
      await sp.remove(_kFirstOpenAt);
    } else {
      await sp.setInt(_kFirstOpenAt, at.millisecondsSinceEpoch);
    }
  }

  /// Écriture unique : la date déjà persistée n'est JAMAIS écrasée, sans
  /// quoi l'ancienneté repartirait de zéro à chaque lancement et le critère
  /// des 7 jours ne serait jamais atteint.
  Future<void> recordFirstOpenIfAbsent({DateTime? now}) async {
    final sp = await _prefs();
    if (sp.getInt(_kFirstOpenAt) != null) return;
    await sp.setInt(
      _kFirstOpenAt,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  /// Instant de la dernière sollicitation d'évaluation **émise**, ou `null`
  /// si aucune ne l'a jamais été. Google ne renvoyant jamais l'issue réelle
  /// du dialogue (noté / fermé / non affiché), c'est l'émission de la
  /// demande — et elle seule — qui consomme le cooldown de 90 jours.
  Future<DateTime?> getLastReviewPromptedAt() async {
    final sp = await _prefs();
    final millis = sp.getInt(_kLastReviewPromptedAt);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastReviewPromptedAt(DateTime? at) async {
    final sp = await _prefs();
    if (at == null) {
      await sp.remove(_kLastReviewPromptedAt);
    } else {
      await sp.setInt(_kLastReviewPromptedAt, at.millisecondsSinceEpoch);
    }
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