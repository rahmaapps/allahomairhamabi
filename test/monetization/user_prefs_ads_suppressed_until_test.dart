// Persistance de `adsSuppressedUntil` (LOT 5.A §9) via l'infrastructure
// UserPrefs/SharedPreferences existante — même style que
// test/user_prefs_migration_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getAdsSuppressedUntil() est null par défaut (jamais accordé)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final result = await UserPrefs.instance.getAdsSuppressedUntil();
    expect(result, isNull);
  });

  test('setAdsSuppressedUntil() puis getAdsSuppressedUntil() round-trip '
      'exact (à la milliseconde)', () async {
    SharedPreferences.setMockInitialValues({});
    final until = DateTime(2026, 3, 1, 18, 30, 0);

    await UserPrefs.instance.setAdsSuppressedUntil(until);
    final result = await UserPrefs.instance.getAdsSuppressedUntil();

    expect(result, until);
  });

  test('setAdsSuppressedUntil(null) efface la suppression persistée',
      () async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setAdsSuppressedUntil(DateTime(2026, 3, 1));

    await UserPrefs.instance.setAdsSuppressedUntil(null);
    final result = await UserPrefs.instance.getAdsSuppressedUntil();

    expect(result, isNull);
  });

  test(
      'getAdsSuppressedUntil() renvoie la valeur brute persistée même si '
      'elle est déjà expirée — la décision d\'activité revient à '
      'AdsFreeStatus, pas à UserPrefs', () async {
    SharedPreferences.setMockInitialValues({});
    final pastDate = DateTime(2020, 1, 1);

    await UserPrefs.instance.setAdsSuppressedUntil(pastDate);
    final result = await UserPrefs.instance.getAdsSuppressedUntil();

    expect(result, pastDate);
  });
}
