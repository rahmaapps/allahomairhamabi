import 'ad_surface.dart';
import 'ads_free_status.dart';
import 'interstitial_trigger.dart';

/// Policy pure (aucune dépendance widget/écran, entièrement testable) qui
/// détermine où une bannière future pourrait apparaître. Décisions produit
/// verrouillées (audit LOT 5.A) : bannières limitées à HOME/Recherche/
/// Favoris ; Grave Visit, DuaRead, Onboarding et Splash restent strictement
/// hors publicité. LOT 5.A n'appelle cette policy nulle part dans l'UI —
/// elle est préparée pour un futur lot qui affichera réellement des
/// bannières.
class AdsPolicy {
  const AdsPolicy._();

  static const Set<AdSurface> _bannerEligibleSurfaces = {
    AdSurface.home,
    AdSurface.search,
    AdSurface.favorites,
  };

  /// `true` si [surface] fait partie des emplacements verrouillés pour une
  /// bannière (HOME, Recherche, Favoris).
  static bool isBannerEligible(AdSurface surface) =>
      _bannerEligibleSurfaces.contains(surface);

  /// Décision finale d'affichage d'une bannière : la surface doit être
  /// éligible, `canRequestAds` (source unique de vérité UMP, voir
  /// `AdsAvailability`) doit être vrai, et aucune suppression temporaire
  /// (Rewarded) ne doit être active.
  static bool canShowBanner({
    required AdSurface surface,
    required bool canRequestAds,
    required AdsFreeStatus adsFreeStatus,
    DateTime? now,
  }) {
    if (!isBannerEligible(surface)) return false;
    if (!canRequestAds) return false;
    if (adsFreeStatus.isActive(now: now)) return false;
    return true;
  }

  // ==========================================================
  // Interstitiels (LOT 5.C) — mêmes briques de consentement et
  // d'état sans publicité que ci-dessus, jamais redéfinies.
  // ==========================================================

  /// Espacement minimal entre deux interstitiels (verrouillé produit :
  /// « maximum 1 interstitiel toutes les 10 minutes »).
  static const Duration interstitialCooldown = Duration(minutes: 10);

  /// Liste d'autorisation explicite : tout ce qui n'y figure pas est
  /// refusé par défaut, y compris une valeur d'enum ajoutée plus tard.
  static const Set<InterstitialTrigger> _eligibleInterstitialTriggers = {
    InterstitialTrigger.leavingSearch,
    InterstitialTrigger.leavingFavorites,
  };

  static bool isInterstitialTriggerEligible(InterstitialTrigger trigger) =>
      _eligibleInterstitialTriggers.contains(trigger);

  /// `true` si aucun interstitiel n'a encore été présenté ([lastShownAt]
  /// `null`) ou si [interstitialCooldown] est entièrement écoulé.
  static bool isInterstitialCooldownElapsed({
    required DateTime? lastShownAt,
    DateTime? now,
  }) {
    if (lastShownAt == null) return true;
    final elapsed = (now ?? DateTime.now()).difference(lastShownAt);
    return elapsed >= interstitialCooldown;
  }

  /// Décision finale de présentation d'un interstitiel. Évaluée au moment
  /// du show, jamais réutilisée depuis l'instant du chargement (§ LOT 5.C).
  static bool canShowInterstitial({
    required InterstitialTrigger trigger,
    required bool canRequestAds,
    required AdsFreeStatus adsFreeStatus,
    required DateTime? lastShownAt,
    DateTime? now,
  }) {
    if (!isInterstitialTriggerEligible(trigger)) return false;
    if (!canRequestAds) return false;
    if (adsFreeStatus.isActive(now: now)) return false;
    if (!isInterstitialCooldownElapsed(lastShownAt: lastShownAt, now: now)) {
      return false;
    }
    return true;
  }
}
