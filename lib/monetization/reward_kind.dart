/// Les deux usages distincts d'un Rewarded, séparés dès le LOT 5.A pour ne
/// jamais confondre leurs effets respectifs à l'appel. Infrastructure réelle
/// livrée au LOT 5.G.A ; aucun point d'appel UI n'existe encore.
enum RewardKind {
  /// Suppression temporaire des publicités : 1 heure, fenêtre démarrant à
  /// l'instant exact du callback `onUserEarnedReward` (verrouillé produit).
  adFreeHour,

  /// Une autorisation ponctuelle de Partage comme image : 1 Rewarded =
  /// 1 partage (verrouillé produit, B4). Le partage texte reste toujours
  /// gratuit et n'est jamais concerné.
  shareAsImageUnlock,
}
