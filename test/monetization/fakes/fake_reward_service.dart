import 'dart:async';

import 'package:test_1/monetization/reward_effects.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/monetization/reward_service.dart';

/// Fake de [RewardService] pour les tests d'interface (LOT 5.G.B).
///
/// Sur `earned`, reproduit exactement ce que fait l'infrastructure LOT 5.G.A
/// au callback `onUserEarnedReward` : `RewardEffects.apply(kind, earnedAt)`.
/// Les écrans ne calculent donc jamais eux-mêmes la récompense.
class FakeRewardService implements RewardService {
  FakeRewardService({
    this.offerable = true,
    this.outcome = RewardOutcome.earned,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  bool offerable;
  RewardOutcome outcome;
  final DateTime Function() _clock;

  final List<RewardKind> requestedKinds = [];
  int canOfferCallCount = 0;

  /// Quand non nul, la demande attend ce completer avant de se résoudre
  /// (permet d'observer l'état « chargement »).
  Completer<void>? gate;

  @override
  Future<bool> canOfferReward() async {
    canOfferCallCount++;
    return offerable;
  }

  @override
  Future<RewardOutcome> requestRewardOutcome(RewardKind kind) async {
    requestedKinds.add(kind);
    final pending = gate;
    if (pending != null) await pending.future;
    if (outcome == RewardOutcome.earned) {
      await RewardEffects.apply(kind, earnedAt: _clock());
    }
    return outcome;
  }

  @override
  Future<bool> requestReward(RewardKind kind) async =>
      await requestRewardOutcome(kind) == RewardOutcome.earned;
}
