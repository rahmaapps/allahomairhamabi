import '../user_prefs.dart';
import 'reward_kind.dart';

/// Effets d'une récompense CONFIRMÉE — appelés uniquement depuis le callback
/// `onUserEarnedReward` (voir `RewardedAdController`), jamais
/// spéculativement.
class RewardEffects {
  const RewardEffects._();

  /// Durée verrouillée produit de [RewardKind.adFreeHour].
  static const Duration adRemovalDuration = Duration(hours: 1);

  /// Point d'entrée unique : applique l'effet de [kind] pour une récompense
  /// gagnée à l'instant [earnedAt] — instant capturé DANS le callback
  /// `onUserEarnedReward`, jamais au chargement, au début de la
  /// présentation ni à la fermeture.
  static Future<void> apply(RewardKind kind, {required DateTime earnedAt}) {
    switch (kind) {
      case RewardKind.adFreeHour:
        return applyTemporaryAdRemoval(now: earnedAt);
      case RewardKind.shareAsImageUnlock:
        return grantShareAsImageUnlock();
    }
  }

  // ==========================================================
  // adFreeHour
  // ==========================================================

  /// Fixe `adsSuppressedUntil` à `now + 1h` (verrouillé produit). Persisté :
  /// survit à un redémarrage. Ne cumule jamais avec une suppression déjà
  /// active — remplace toujours la valeur par une nouvelle fenêtre d'1h à
  /// partir de [now].
  static Future<void> applyTemporaryAdRemoval({DateTime? now}) async {
    final until = (now ?? DateTime.now()).add(adRemovalDuration);
    await UserPrefs.instance.setAdsSuppressedUntil(until);
  }

  // ==========================================================
  // shareAsImageUnlock — autorisation one-shot (B4)
  // ==========================================================

  /// Enregistre UNE autorisation de Partage comme image. Persistée, pour
  /// qu'une récompense gagnée survive à un arrêt de l'application pendant
  /// ou juste après l'annonce.
  ///
  /// One-shot : l'autorisation est un état (présente / absente), jamais un
  /// compteur — deux octrois successifs sans consommation n'en donnent
  /// toujours qu'une seule.
  static Future<void> grantShareAsImageUnlock() =>
      UserPrefs.instance.setShareAsImageUnlockPending(true);

  /// `true` si une autorisation gagnée n'a pas encore été consommée.
  static Future<bool> hasShareAsImageUnlock() =>
      UserPrefs.instance.getShareAsImageUnlockPending();

  /// Consomme l'autorisation et retourne `true` si elle existait.
  ///
  /// À appeler par le futur flux Share as Image (LOT UX) **au moment où
  /// l'image est remise au système de partage** — jamais avant le rendu
  /// PNG : un rendu échoué ne doit pas consommer la récompense (B4). Aucun
  /// appel n'existe encore dans l'application.
  static Future<bool> consumeShareAsImageUnlock() async {
    if (!await hasShareAsImageUnlock()) return false;
    await UserPrefs.instance.setShareAsImageUnlockPending(false);
    return true;
  }
}
