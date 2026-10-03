/// Source unique de vérité pour l'état de consentement UMP (Google User
/// Messaging Platform). Toute future demande de publicité (LOT 5.B+) doit
/// passer par [canRequestAds] — jamais par un booléen local du type
/// "l'utilisateur a accepté" déduit indépendamment.
///
/// Interface volontairement minimale et injectable : la vraie
/// implémentation (`GoogleUmpConsentService`) appelle un canal de
/// plateforme natif non mockable en `flutter_test` (même limitation déjà
/// documentée dans ce projet pour `share_plus`/`flutter_local_notifications`)
/// — le code métier (ex. `AdsAvailability`) dépend donc de cette interface,
/// jamais directement du plugin, pour rester testable via un fake.
abstract class ConsentService {
  /// À appeler à chaque lancement de l'app : met à jour l'info de
  /// consentement puis affiche le formulaire UMP uniquement s'il est requis.
  /// Ne doit jamais lever d'exception ni bloquer indéfiniment le
  /// démarrage — un échec réseau/plateforme laisse simplement
  /// [canRequestAds] à `false` pour la session.
  Future<void> requestConsentUpdate();

  /// Reflète directement `ConsentInformation.canRequestAds()` — jamais
  /// assimilé à un simple "consentement accepté" (un statut `notRequired`
  /// peut aussi autoriser les requêtes, par exemple hors zone régulée).
  Future<bool> canRequestAds();

  /// `true` si un point d'entrée "Options de confidentialité" doit être
  /// proposé à l'utilisateur. LOT 5.A ne l'affiche dans aucun écran — à
  /// consommer par un futur écran (ex. Paramètres, hors périmètre ici).
  Future<bool> isPrivacyOptionsRequired();

  /// Affiche le formulaire d'options de confidentialité. À n'appeler que
  /// si [isPrivacyOptionsRequired] vaut `true`.
  Future<void> showPrivacyOptionsForm();
}
