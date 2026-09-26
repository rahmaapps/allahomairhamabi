// Tests LOT 3.G — Paramètres / Rappels.
//
// Portée : persistance `enableFriday` (`UserPrefs`). La logique pure
// `WorkManagerService.initialDelayForNextFriday` (code mort, aucune
// référence dans `lib/`) a été retirée avec ses tests ; la planification
// réelle passe par `NotificationService.scheduleWeeklyReminder`.
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

import 'package:test_1/user_prefs.dart';

void main() {
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
