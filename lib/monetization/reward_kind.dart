/// Deux usages futurs distincts d'un Rewarded (LOT 5.C/5.D — non
/// implémentés dans LOT 5.A, cf. §12 audit). Séparés dès maintenant pour ne
/// jamais confondre leurs effets respectifs à l'appel.
enum RewardKind {
  /// Suppression temporaire des publicités (1 heure, verrouillé produit).
  temporaryAdRemoval,

  /// Déblocage ponctuel d'un Partage comme image (Share as Image).
  shareAsImageUnlock,
}
