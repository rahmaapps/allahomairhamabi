/// Abstraction du mécanisme natif de demande d'évaluation (D7). La policy
/// et le controller ne dépendent que de cette interface, jamais du package
/// `in_app_review` : l'implémentation réelle passe par un canal de
/// plateforme non mockable en `flutter_test` (même limitation déjà
/// documentée pour `ConsentService`/`InterstitialAdLoader`).
///
/// Contrat strict, exigé par D7 : **aucune méthode ne lève jamais**. Une
/// indisponibilité (hors Play Store, Play Services absents, quota Google
/// atteint) ou une exception plateforme se traduit par un `false`, jamais
/// par une erreur remontée à l'appelant ni par un blocage de navigation.
abstract class ReviewAvailability {
  /// `true` si le mécanisme natif est exploitable ici et maintenant.
  Future<bool> isAvailable();

  /// Émet la demande d'évaluation. Retourne `true` si elle a effectivement
  /// été émise, `false` en cas d'échec.
  ///
  /// Ne dit **jamais** si l'utilisateur a noté l'application : Google ne
  /// renvoie aucune information sur l'issue du dialogue, ni même sur le
  /// fait qu'il ait été affiché. C'est une limitation de l'API, pas de
  /// cette abstraction.
  Future<bool> requestReview();
}
