// LOT 3.L — persistance du template Partage Premium (§4 Partage Premium :
// « Persistée (share_template) »). Fichier séparé de
// premium_share_as_image_test.dart (comme user_prefs_migration_test.dart
// l'est déjà) : `UserPrefs.getShareTemplate`/`setShareTemplate` sont des
// méthodes d'instance qui passent par `_prefs()` (cache `_sp` du singleton
// `UserPrefs.instance`, jamais réinitialisé entre deux `test()`) — un
// `testWidgets` exerçant déjà `UserPrefs.instance` dans le même fichier
// rendrait un `SharedPreferences.setMockInitialValues` ultérieur invisible
// à `UserPrefs.instance` (cache déjà peuplé avec l'ancien contenu mock).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  test(
      'aucune préférence enregistrée : getShareTemplate() retourne null '
      '(Dark Luxe par défaut — décidé par l\'appelant, voir HomeScreen._templateFromName)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final saved = await UserPrefs.instance.getShareTemplate();
    expect(saved, isNull);
  });

  test('setShareTemplate puis getShareTemplate : round-trip exact', () async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setShareTemplate('emerald');
    final saved = await UserPrefs.instance.getShareTemplate();
    expect(saved, 'emerald');
  });

  test('une nouvelle sélection écrase la précédente (une seule à la fois, §4)',
      () async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setShareTemplate('emerald');
    await UserPrefs.instance.setShareTemplate('whiteElegant');
    final saved = await UserPrefs.instance.getShareTemplate();
    expect(saved, 'whiteElegant');
  });
}
