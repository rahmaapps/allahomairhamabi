import 'package:flutter/foundation.dart';

import 'ads_availability.dart';
import 'ads_sdk_initializer.dart';
import 'consent_service.dart';
import 'google_ump_consent_service.dart';

/// Point d'entrée unique du socle Monétisation, appelé au lancement (voir
/// `main.dart`). N'est jamais `await`é avant `runApp` — s'exécute en tâche
/// de fond pendant que la première frame se construit (§7 audit LOT 5.A :
/// ne pas retarder le démarrage).
///
/// LOT 5.A : ce bootstrap ne fait qu'établir l'état UMP et, si autorisé,
/// initialiser le SDK — il ne charge ni n'affiche jamais de publicité.
class MonetizationBootstrap {
  MonetizationBootstrap._();

  static final ConsentService consentService = GoogleUmpConsentService();

  /// Source unique de vérité à consulter par tout futur code d'affichage
  /// publicitaire (LOT 5.B+).
  static final AdsAvailability adsAvailability = AdsAvailability(
    consentService,
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
      if (await consentService.canRequestAds()) {
        await AdsSdkInitializer.initializeIfNeeded();
        adsAvailability.markSdkInitialized();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Monetization] Bootstrap non bloquant — erreur ignorée: $e',
        );
      }
    }
  }
}
