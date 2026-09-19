import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/reward_effects.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RewardEffects.applyTemporaryAdRemoval (verrouillé produit : 1h)',
      () {
    test('étend adsSuppressedUntil à exactement now + 1h', () async {
      final now = DateTime(2026, 1, 1, 12, 0);

      await RewardEffects.applyTemporaryAdRemoval(now: now);

      final until = await UserPrefs.instance.getAdsSuppressedUntil();
      expect(until, now.add(const Duration(hours: 1)));
    });

    test('remplace toujours la valeur précédente (pas de cumul)', () async {
      final now = DateTime(2026, 1, 1, 12, 0);
      await UserPrefs.instance.setAdsSuppressedUntil(
        now.add(const Duration(hours: 5)),
      );

      await RewardEffects.applyTemporaryAdRemoval(now: now);

      final until = await UserPrefs.instance.getAdsSuppressedUntil();
      expect(until, now.add(const Duration(hours: 1)));
    });
  });
}
