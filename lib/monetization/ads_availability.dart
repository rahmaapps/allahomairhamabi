import 'consent_service.dart';

/// Source UNIQUE de vérité à consulter avant toute future demande de
/// publicité (LOT 5.B+ — aucun appel n'existe encore dans ce lot). Combine
/// deux garanties, toutes deux nécessaires :
/// - le SDK Google Mobile Ads a été initialisé pour cette session ;
/// - `ConsentInformation.canRequestAds()` (via [ConsentService]) autorise
///   la requête — jamais assimilé à "l'utilisateur a accepté" (cf.
///   [ConsentService.canRequestAds]).
///
/// Tant que l'une des deux conditions n'est pas remplie, [canRequestAds]
/// retourne `false` : aucune requête ne peut être effectuée avant que
/// l'état UMP soit exploitable (garantie explicite audit LOT 5.A, §8).
class AdsAvailability {
  AdsAvailability(this._consentService);

  final ConsentService _consentService;
  bool _sdkInitialized = false;

  bool get isSdkInitialized => _sdkInitialized;

  void markSdkInitialized() => _sdkInitialized = true;

  Future<bool> canRequestAds() async {
    if (!_sdkInitialized) return false;
    return _consentService.canRequestAds();
  }
}
