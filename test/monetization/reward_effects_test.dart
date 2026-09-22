import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/reward_effects.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setShareAsImageUnlockPending(false);
  });

  group('RewardEffects.apply — aiguillage par RewardKind', () {
    test('adFreeHour : fenêtre d\'1h à partir de earnedAt', () async {
      final earnedAt = DateTime(2026, 9, 22, 10, 30);

      await RewardEffects.apply(RewardKind.adFreeHour, earnedAt: earnedAt);

      expect(
        await UserPrefs.instance.getAdsSuppressedUntil(),
        earnedAt.add(const Duration(hours: 1)),
      );
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
    });

    test('shareAsImageUnlock : autorisation seule, aucune suppression',
        () async {
      await UserPrefs.instance.setAdsSuppressedUntil(null);

      await RewardEffects.apply(
        RewardKind.shareAsImageUnlock,
        earnedAt: DateTime(2026, 9, 22),
      );

      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
    });
  });

  group('shareAsImageUnlock — one-shot (B4)', () {
    test('aucune autorisation par défaut ; consommer sans autorisation → false',
        () async {
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
      expect(await RewardEffects.consumeShareAsImageUnlock(), isFalse);
    });

    test('1 octroi = 1 consommation', () async {
      await RewardEffects.grantShareAsImageUnlock();

      expect(await RewardEffects.consumeShareAsImageUnlock(), isTrue);
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
      expect(await RewardEffects.consumeShareAsImageUnlock(), isFalse);
    });

    test('deux octrois sans consommation n\'en donnent qu\'un seul', () async {
      await RewardEffects.grantShareAsImageUnlock();
      await RewardEffects.grantShareAsImageUnlock();

      expect(await RewardEffects.consumeShareAsImageUnlock(), isTrue);
      expect(await RewardEffects.consumeShareAsImageUnlock(), isFalse);
    });

    test('persistée dans le stockage', () async {
      await RewardEffects.grantShareAsImageUnlock();

      final raw = (await SharedPreferences.getInstance())
          .getBool('share_as_image_unlock_pending');
      expect(raw, isTrue);
    });
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
