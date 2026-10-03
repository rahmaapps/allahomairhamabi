import '../monetization/ads_policy.dart';
import '../monetization/interstitial_ad_controller.dart';
import '../user_prefs.dart';
import 'ad_activity_probe.dart';

/// Implémentation réelle de [AdActivityProbe], branchée sur l'état
/// interstitiel existant **en lecture seule** — aucun fichier de
/// `lib/monetization/` n'est modifié, aucune publicité n'est déclenchée ni
/// annulée ici.
///
/// Deux garanties, toutes deux nécessaires à D6 :
/// - un interstitiel est à l'écran en ce moment (`showing`) ;
/// - un interstitiel a été **effectivement présenté** trop récemment. La
///   fenêtre réutilise `AdsPolicy.interstitialCooldown`, valeur produit
///   déjà verrouillée au LOT 5.C, plutôt que d'en inventer une nouvelle.
///
/// Les états `loading` et `ready` ne bloquent pas : par construction, un
/// interstitiel chargé sur une transition n'est jamais présenté sur cette
/// même transition, et `ready` est l'état nominal entre deux publicités —
/// le traiter comme bloquant interdirait toute sollicitation en pratique.
Future<bool> interstitialAdActivityProbe() async {
  if (InterstitialAdController.instance.state ==
      InterstitialAdState.showing) {
    return true;
  }

  final lastShownAt = await UserPrefs.instance.getLastInterstitialShownAt();
  if (lastShownAt == null) return false;

  // Un écart négatif (horloge reculée) est traité comme « trop récent » :
  // en cas de doute, on ne sollicite pas.
  final elapsed = DateTime.now().difference(lastShownAt);
  return elapsed < AdsPolicy.interstitialCooldown;
}
