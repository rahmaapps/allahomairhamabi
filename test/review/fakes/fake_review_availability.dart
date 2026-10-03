import 'package:test_1/review/review_availability.dart';

/// Fake injectable de [ReviewAvailability] — aucun canal de plateforme,
/// aucun dialogue Google Play réellement affiché. Permet d'exercer les
/// quatre issues réelles du mécanisme natif : disponible et demande émise,
/// indisponible (hors Play Store), demande échouée, et exception
/// plateforme.
class FakeReviewAvailability implements ReviewAvailability {
  int isAvailableCallCount = 0;
  int requestReviewCallCount = 0;

  /// Mécanisme natif exploitable ou non (hors Play Store, Play Services
  /// absents, quota Google atteint...).
  bool available = true;

  /// La demande aboutit ou échoue silencieusement.
  bool requestSucceeds = true;

  /// Simule un canal de plateforme qui lève — l'implémentation réelle
  /// intercepte, mais le controller doit survivre même si ce n'était pas
  /// le cas (contrat D7 : aucune exception, aucun blocage).
  bool throwOnIsAvailable = false;
  bool throwOnRequestReview = false;

  @override
  Future<bool> isAvailable() async {
    isAvailableCallCount++;
    if (throwOnIsAvailable) {
      throw StateError('canal de plateforme indisponible (simulé)');
    }
    return available;
  }

  @override
  Future<bool> requestReview() async {
    requestReviewCallCount++;
    if (throwOnRequestReview) {
      throw StateError('échec plateforme pendant la demande (simulé)');
    }
    return requestSucceeds;
  }
}
