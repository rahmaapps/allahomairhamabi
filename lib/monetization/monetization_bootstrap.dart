import 'package:flutter/foundation.dart';

import 'ads_activation.dart';
import 'ads_availability.dart';
import 'consent_service.dart';
import 'google_ump_consent_service.dart';

/// Point d'entrée unique du socle Monétisation, appelé au lancement (voir
/// `main.dart`). N'est jamais `await`é avant `runApp` — s'exécute en tâche
/// de fond pendant que la première frame se construit (§7 audit LOT 5.A :
/// ne pas retarder le démarrage).
///
/// Ce bootstrap n'établit que l'état UMP et, si autorisé, initialise le
/// SDK — il ne charge ni n'affiche jamais de publicité.
class MonetizationBootstrap {
  MonetizationBootstrap._();

  static final ConsentService consentService = GoogleUmpConsentService();

  /// Source unique de vérité à consulter par tout code d'affichage
  /// publicitaire (LOT 5.B+).
  static final AdsAvailability adsAvailability = AdsAvailability(
    consentService,
  );

  /// Activation du SDK conditionnée au consentement. Appelée au lancement,
  /// puis à nouveau après toute interaction susceptible d'avoir modifié le
  /// consentement (correction A2, LOT 5.F).
  static final AdsActivation adsActivation = AdsActivation(
    consentService: consentService,
    adsAvailability: adsAvailability,
  );

  /// À appeler à chaque lancement (§3 audit). Ne lève jamais d'exception :
  /// un échec réseau/plateforme laisse simplement `canRequestAds()` à
  /// `false` pour cette session, jamais l'app dans un état incohérent.
  static Future<void> runAtLaunch() async {
    try {
      // §3 : mise à jour UMP à chaque lancement (affiche le formulaire
      // uniquement s'il est requis, cf. GoogleUmpConsentService).
      await consentService.requestConsentUpdate();

      // §8 : le SDK Ads n'est initialisé — et donc rendu disponible via
      // `adsAvailability` — que si l'état UMP autorise déjà les requêtes.
      await ensureAdsInitializedIfAllowed();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Monetization] Bootstrap non bloquant — erreur ignorée: $e',
        );
      }
    }
  }

  /// Rejoue le contrôle de consentement et initialise le SDK si — et
  /// seulement si — `canRequestAds()` l'autorise. Idempotent, non bloquant,
  /// ne lève jamais, n'affiche aucune publicité.
  static Future<bool> ensureAdsInitializedIfAllowed() =>
      adsActivation.ensureInitializedIfAllowed();
}
