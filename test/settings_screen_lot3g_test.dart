// Tests LOT 3.G — Paramètres / Rappels.
//
// Portée : logique pure de replanification du vendredi
// (`WorkManagerService.initialDelayForNextFriday`, exposée via
// `@visibleForTesting` pour cet unique besoin, aucune nouvelle
// infrastructure) et persistance `enableFriday` (`UserPrefs`).
//
// Hors portée de ce fichier — limitation déjà documentée dans le projet
// pour cet écran précis (voir `test/phase7_onboarding_and_person_
// selection_test.dart` et `test/onboarding_screen_test.dart`) :
// `SettingsScreen._bootstrap()` attend `NotificationService.
// ensureInitialized()` avant `_loadPrefs()` ; en `flutter_test` simple,
// sans mock des canaux de plateforme (`flutter_local_notifications` et
// `workmanager`), cet appel ne se résout jamais et l'écran reste bloqué
// sur son indicateur de chargement — vérifié empiriquement pendant l'audit
// de ce lot. Un test widget de `SettingsScreen` (structure des 6 lignes,
// absence de بعد الظهر/تدعو لـ/حفظ, affichage conditionnel de الوقت)
// nécessiterait soit de mocker ces canaux (première du genre dans ce
// projet), soit de changer `_bootstrap()` pour un chargement non bloquant
// (comme `OnboardingScreen`) — deux changements hors du périmètre de ce
// lot, non effectués ici sans validation explicite.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/settings_screen.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  group('LOT 3.G — WorkManagerService.initialDelayForNextFriday', () {
    test('vendredi avant 09:00 → même jour à 09:00', () {
      // Vendredi 2026-01-02 à 07:00.
      final now = DateTime(2026, 1, 2, 7, 0);
      expect(now.weekday, DateTime.friday);

      final delay = WorkManagerService.initialDelayForNextFriday(9, 0, now: now);

      expect(delay, const Duration(hours: 2));
      final scheduled = now.add(delay);
      expect(scheduled.weekday, DateTime.friday);
      expect(scheduled.year, 2026);
      expect(scheduled.month, 1);
      expect(scheduled.day, 2);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 0);
    });

    test('vendredi après 09:00 → vendredi suivant', () {
      // Vendredi 2026-01-02 à 10:00 — l'heure du jour est déjà passée.
      final now = DateTime(2026, 1, 2, 10, 0);
      expect(now.weekday, DateTime.friday);

      final delay = WorkManagerService.initialDelayForNextFriday(9, 0, now: now);
      final scheduled = now.add(delay);

      expect(scheduled.isAfter(now), isTrue);
      expect(scheduled.weekday, DateTime.friday);
      // Vendredi suivant = 2026-01-09 (7 jours plus tard).
      expect(scheduled.year, 2026);
      expect(scheduled.month, 1);
      expect(scheduled.day, 9);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 0);
    });

    test('autre jour avant vendredi (lundi) → vendredi de la même semaine', () {
      // Lundi 2025-12-29 à 08:00.
      final now = DateTime(2025, 12, 29, 8, 0);
      expect(now.weekday, DateTime.monday);

      final delay = WorkManagerService.initialDelayForNextFriday(9, 0, now: now);
      final scheduled = now.add(delay);

      expect(scheduled.isAfter(now), isTrue);
      expect(scheduled.weekday, DateTime.friday);
      // Vendredi de la même semaine = 2026-01-02.
      expect(scheduled.year, 2026);
      expect(scheduled.month, 1);
      expect(scheduled.day, 2);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 0);
    });

    test('samedi → prochain vendredi (semaine suivante)', () {
      // Samedi 2026-01-03 à 08:00 — le vendredi de la semaine (hier) est passé.
      final now = DateTime(2026, 1, 3, 8, 0);
      expect(now.weekday, DateTime.saturday);

      final delay = WorkManagerService.initialDelayForNextFriday(9, 0, now: now);
      final scheduled = now.add(delay);

      expect(scheduled.isAfter(now), isTrue);
      expect(scheduled.weekday, DateTime.friday);
      expect(scheduled.year, 2026);
      expect(scheduled.month, 1);
      expect(scheduled.day, 9);
    });

    test('dimanche → prochain vendredi (semaine suivante)', () {
      // Dimanche 2026-01-04 à 08:00.
      final now = DateTime(2026, 1, 4, 8, 0);
      expect(now.weekday, DateTime.sunday);

      final delay = WorkManagerService.initialDelayForNextFriday(9, 0, now: now);
      final scheduled = now.add(delay);

      expect(scheduled.isAfter(now), isTrue);
      expect(scheduled.weekday, DateTime.friday);
      expect(scheduled.year, 2026);
      expect(scheduled.month, 1);
      expect(scheduled.day, 9);
    });

    test('aucun délai négatif ou nul sur un balayage des 7 jours de la semaine', () {
      final start = DateTime(2026, 1, 1); // un jeudi
      for (var i = 0; i < 14; i++) {
        final now = start.add(Duration(days: i, hours: 7, minutes: 30));
        final delay =
            WorkManagerService.initialDelayForNextFriday(9, 0, now: now);
        expect(delay.isNegative, isFalse,
            reason: 'délai négatif pour now=$now');
        expect(delay, greaterThan(Duration.zero),
            reason: 'délai nul pour now=$now');
        expect(now.add(delay).weekday, DateTime.friday,
            reason: 'occurrence calculée non-vendredi pour now=$now');
      }
    });

    test('replanification après déclenchement reste ancrée au vendredi '
        '(pas un simple +7 jours depuis l\'exécution)', () {
      // Le rappel devait se déclencher vendredi 09:00 mais WorkManager ne
      // l'exécute réellement que 3 jours plus tard (retard Android
      // plausible, ex. Doze) : un « +7 jours depuis l'exécution » dériverait
      // hors du vendredi. `initialDelayForNextFriday` doit rester correct
      // car il recalcule depuis la vraie date du jour, pas depuis un delta.
      final executedLate = DateTime(2026, 1, 5, 14, 0); // lundi, en retard
      final delay =
          WorkManagerService.initialDelayForNextFriday(9, 0, now: executedLate);
      final rescheduled = executedLate.add(delay);

      expect(rescheduled.weekday, DateTime.friday);
      expect(rescheduled.hour, 9);
      expect(rescheduled.minute, 0);
    });
  });

  group('LOT 3.G — persistance تذكير الجمعة (UserPrefs.enableFriday)', () {
    // Un seul test, `setMockInitialValues` appelé une seule fois avant tout
    // accès à `UserPrefs.instance` : `UserPrefs` mémorise en interne
    // l'instance `SharedPreferences` résolue (`_sp`) pour toute la durée de
    // l'isolat de test — réinitialiser le mock puis réutiliser le singleton
    // dans un test séparé du même fichier serait un piège de test connu
    // (cache non invalidé). Ce séquencement reproduit le même principe déjà
    // implicite dans `test/user_prefs_migration_test.dart`.
    test('valeur par défaut false, puis set/get reflète la valeur persistée',
        () async {
      SharedPreferences.setMockInitialValues({});

      expect(await UserPrefs.instance.getFridayEnabled(), isFalse);

      await UserPrefs.instance.setFridayEnabled(true);
      expect(await UserPrefs.instance.getFridayEnabled(), isTrue);

      await UserPrefs.instance.setFridayEnabled(false);
      expect(await UserPrefs.instance.getFridayEnabled(), isFalse);
    });
  });
}
