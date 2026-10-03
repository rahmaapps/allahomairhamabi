import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/monetization/reward_service.dart';

void main() {
  group('RewardKind', () {
    test('expose exactement les deux usages verrouillés produit', () {
      expect(RewardKind.values, [
        RewardKind.adFreeHour,
        RewardKind.shareAsImageUnlock,
      ]);
    });
  });

  group('RewardOutcome', () {
    test('distingue les quatre issues verrouillées', () {
      expect(RewardOutcome.values, [
        RewardOutcome.unavailable,
        RewardOutcome.failed,
        RewardOutcome.dismissedWithoutReward,
        RewardOutcome.earned,
      ]);
    });
  });

  group('NoopRewardService (aucun Rewarded réel)', () {
    test('ne grant jamais de récompense, quel que soit le RewardKind',
        () async {
      const service = NoopRewardService();
      expect(await service.canOfferReward(), isFalse);

      for (final kind in RewardKind.values) {
        expect(await service.requestReward(kind), isFalse);
        expect(
          await service.requestRewardOutcome(kind),
          RewardOutcome.unavailable,
        );
      }
    });

    test('implémente bien l\'interface RewardService (contrat respecté)',
        () {
      const RewardService service = NoopRewardService();
      expect(service, isA<RewardService>());
    });
  });
}
