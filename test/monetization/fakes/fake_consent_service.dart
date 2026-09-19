import 'package:test_1/monetization/consent_service.dart';

/// Fake injectable de [ConsentService] — le vrai `GoogleUmpConsentService`
/// appelle un canal de plateforme natif non mockable en `flutter_test` (même
/// limitation déjà documentée dans ce projet pour `share_plus`/
/// `flutter_local_notifications`). Utilisé pour tester tout code métier
/// dépendant de l'interface [ConsentService] (ex. `AdsAvailability`).
class FakeConsentService implements ConsentService {
  bool canRequestAdsValue = false;
  bool privacyOptionsRequiredValue = false;
  int requestConsentUpdateCallCount = 0;
  int showPrivacyOptionsFormCallCount = 0;

  @override
  Future<void> requestConsentUpdate() async {
    requestConsentUpdateCallCount++;
  }

  @override
  Future<bool> canRequestAds() async => canRequestAdsValue;

  @override
  Future<bool> isPrivacyOptionsRequired() async => privacyOptionsRequiredValue;

  @override
  Future<void> showPrivacyOptionsForm() async {
    showPrivacyOptionsFormCallCount++;
  }
}
