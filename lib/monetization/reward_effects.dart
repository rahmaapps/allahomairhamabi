import '../user_prefs.dart';
// ignore: unused_import
import 'reward_kind.dart'; // référencé uniquement dans la doc ci-dessous

/// Applique l'effet d'une récompense CONFIRMÉE accordée — à appeler
/// uniquement après un `RewardService.requestReward(...)` ayant retourné
/// `true` (jamais spéculativement). LOT 5.A n'implémente l'effet que pour
/// [RewardKind.temporaryAdRemoval], seul usage dont la règle produit est
/// entièrement spécifiée et verrouillée (1 heure). L'effet de
/// `RewardKind.shareAsImageUnlock` sera implémenté à son site d'appel par
/// le lot qui l'active (5.C/5.D, non touchés ici).
class RewardEffects {
  const RewardEffects._();

  static const Duration adRemovalDuration = Duration(hours: 1);

  /// Étend `adsSuppressedUntil` à `now + 1h` (verrouillé produit :
  /// "Rewarded suppression Ads : 1 heure", basé sur `onUserEarnedReward`).
  /// Ne cumule jamais avec une suppression déjà active — remplace toujours
  /// la valeur par une nouvelle fenêtre d'1h à partir de maintenant.
  static Future<void> applyTemporaryAdRemoval({DateTime? now}) async {
    final until = (now ?? DateTime.now()).add(adRemovalDuration);
    await UserPrefs.instance.setAdsSuppressedUntil(until);
  }
}
