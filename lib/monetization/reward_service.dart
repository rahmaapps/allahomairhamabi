import 'reward_kind.dart';

/// Issue d'une demande de Rewarded. Les quatre cas sont volontairement
/// distincts : le futur flux UX (LOT 5.G.B) doit pouvoir réagir
/// différemment à une indisponibilité (repli) et à une fermeture volontaire.
enum RewardOutcome {
  /// Aucune tentative n'a eu lieu : consentement non exploitable, SDK non
  /// initialisé, fenêtre sans publicité active, unité non configurée, ou
  /// une autre demande est déjà en cours. Aucune requête réseau émise.
  unavailable,

  /// Tentative échouée : échec de chargement, délai dépassé ou échec de
  /// présentation.
  failed,

  /// Annonce présentée puis fermée **sans** `onUserEarnedReward`.
  dismissedWithoutReward,

  /// `onUserEarnedReward` reçu : l'effet du [RewardKind] a été appliqué.
  earned,
}

/// Abstraction d'un Rewarded. Les écrans ne dépendent que de cette
/// interface, jamais de Google Mobile Ads (implémentation réelle :
/// `RewardedAdController`, LOT 5.G.A).
abstract class RewardService {
  /// Présente un Rewarded pour [kind] et en retourne l'issue détaillée.
  ///
  /// L'effet de la récompense est appliqué par le service lui-même, à
  /// l'instant exact du callback `onUserEarnedReward` — jamais au
  /// chargement, au début de la présentation ni à la fermeture. Aucun
  /// autre callback n'accorde de récompense.
  Future<RewardOutcome> requestRewardOutcome(RewardKind kind);

  /// `true` UNIQUEMENT si la récompense a été effectivement accordée
  /// (callback `onUserEarnedReward` réellement déclenché) — jamais sur une
  /// simple fermeture de l'annonce sans récompense gagnée (règle produit
  /// verrouillée : « aucun reward si la récompense n'est pas effectivement
  /// accordée »).
  Future<bool> requestReward(RewardKind kind);
}

/// Implémentation neutre : ne déclenche jamais de publicité et n'accorde
/// jamais de récompense. Reste la valeur d'injection sûre pour tout code
/// qui ne doit pas exposer de Rewarded réel.
class NoopRewardService implements RewardService {
  const NoopRewardService();

  @override
  Future<RewardOutcome> requestRewardOutcome(RewardKind kind) async =>
      RewardOutcome.unavailable;

  @override
  Future<bool> requestReward(RewardKind kind) async => false;
}
