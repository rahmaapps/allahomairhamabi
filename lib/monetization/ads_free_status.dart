/// Abstraction propre du statut "sans publicité" temporaire (ex. accordé
/// par un futur Rewarded, LOT 5.C — non implémenté ici). Ne porte aucune
/// logique de récompense ni de policy d'écran, uniquement l'état "jusqu'à
/// quand" — persisté séparément via `UserPrefs.adsSuppressedUntil`.
class AdsFreeStatus {
  const AdsFreeStatus(this.suppressedUntil);

  /// `null` = aucune suppression temporaire n'a jamais été accordée (ou
  /// elle a expiré et a été effacée par l'appelant).
  final DateTime? suppressedUntil;

  /// `true` si la suppression est active à l'instant [now] (par défaut
  /// `DateTime.now()`, injectable pour les tests).
  bool isActive({DateTime? now}) {
    final until = suppressedUntil;
    if (until == null) return false;
    return until.isAfter(now ?? DateTime.now());
  }

  /// Temps restant avant expiration, ou `null` si inactif.
  Duration? remaining({DateTime? now}) {
    if (!isActive(now: now)) return null;
    return suppressedUntil!.difference(now ?? DateTime.now());
  }
}
