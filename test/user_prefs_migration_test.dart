// Test de la migration des favoris V1.2 (Option A — abandon propre).
// Corrige BUG-006 : anciens favoris ambigus (ids locaux réutilisés par
// plusieurs personnes) jamais résolus automatiquement.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migration efface les anciens favoris ambigus (Option A)', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.favorite_dua_ids': <String>['121', '5'],
      'flutter.fav_text_121': 'texte personnalisé ancien',
      'flutter.fav_text_5': 'autre texte',
    });

    final didMigrate = await UserPrefs.migrateFavoritesToGlobalIdsIfNeeded();
    expect(didMigrate, isTrue);

    final ids = await UserPrefs.instance.getFavoriteIds();
    expect(ids, isEmpty);

    final text = await UserPrefs.getFavoriteText(121);
    expect(text, isNull);
  });

  test('migration est idempotente (2e appel = no-op)', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.favorite_dua_ids': <String>['61'],
    });

    final first = await UserPrefs.migrateFavoritesToGlobalIdsIfNeeded();
    expect(first, isTrue);

    // Ajoute un NOUVEAU favori (post-migration, id global légitime) pour
    // vérifier que le 2e appel ne l'efface pas.
    await UserPrefs.instance.addFavoriteId(61);
    final second = await UserPrefs.migrateFavoritesToGlobalIdsIfNeeded();
    expect(second, isFalse, reason: 'la migration ne doit s\'exécuter qu\'une fois');

    final ids = await UserPrefs.instance.getFavoriteIds();
    expect(ids, contains(61));
  });

  test('aucune donnée ancienne : migration marquée faite mais sans effet signalé', () async {
    SharedPreferences.setMockInitialValues({});
    final didMigrate = await UserPrefs.migrateFavoritesToGlobalIdsIfNeeded();
    expect(didMigrate, isFalse);
  });
}
