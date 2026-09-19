import 'reward_kind.dart';

/// Abstraction d'un Rewarded. LOT 5.A ne fournit AUCUNE implémentation
/// réelle : aucun `RewardedAd` Google Mobile Ads n'est chargé ni affiché ici
/// (§12 audit LOT 5.A). Un futur lot (5.C/5.D) fournira une implémentation
/// concrète appelant le SDK et déclenchant réellement `onUserEarnedReward`.
abstract class RewardService {
  /// Doit retourner `true` UNIQUEMENT si la récompense a été effectivement
  /// accordée par le SDK (callback `onUserEarnedReward` réellement
  /// déclenché) — jamais sur une simple fermeture/complétion de l'annonce
  /// sans récompense gagnée (règle produit verrouillée : "aucun reward si
  /// la récompense n'est pas effectivement accordée").
  Future<bool> requestReward(RewardKind kind);
}

/// Implémentation par défaut tant qu'aucun Rewarded réel n'existe : ne
/// déclenche jamais de publicité et n'accorde jamais de récompense. Sert de
/// valeur d'injection par défaut pour ne jamais risquer un appel accidentel
/// à une pub réelle avant le lot qui l'implémente.
class NoopRewardService implements RewardService {
  const NoopRewardService();

  @override
  Future<bool> requestReward(RewardKind kind) async => false;
}
