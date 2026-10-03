import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';

/// Initialise le SDK Google Mobile Ads, **une seule fois par session**.
///
/// Idempotent et sûr en concurrence (LOT 5.F) : plusieurs appels simultanés
/// partagent la même initialisation en vol, et un appel après succès est un
/// no-op immédiat. Ne déclenche elle-même aucune requête publicitaire —
/// c'est [AdsAvailability] (couplée au consentement UMP) qui reste la source
/// unique de vérité consultée avant toute demande d'annonce.
///
/// Applique au passage la configuration globale des requêtes
/// (`maxAdContentRating`, appareils de test) : point central unique, jamais
/// dupliqué dans les loaders.
class AdsSdkInitializer {
  AdsSdkInitializer._();

  static bool _initialized = false;
  static Future<void>? _inFlight;

  static bool get isInitialized => _initialized;

  /// Initialisation réelle. Remplaçable en test uniquement : le SDK passe
  /// par un canal de plateforme natif non mockable en `flutter_test`.
  @visibleForTesting
  static Future<void> Function() initializer = defaultInitializer;

  @visibleForTesting
  static Future<void> defaultInitializer() async {
    // Avant `initialize()` : la configuration doit être connue du SDK dès
    // la première requête possible.
    await MobileAds.instance
        .updateRequestConfiguration(AdsConfig.buildRequestConfiguration());
    await MobileAds.instance.initialize();
  }

  /// Ne fait rien si le SDK est déjà initialisé. En cas d'échec, l'exception
  /// est propagée à l'appelant (qui l'absorbe — voir `AdsActivation`) et une
  /// tentative ultérieure reste possible : aucun état « échoué » définitif
  /// n'est mémorisé, et aucune boucle de retry n'est déclenchée ici.
  static Future<void> initializeIfNeeded() {
    if (_initialized) return Future<void>.value();
    return _inFlight ??= _initializeOnce();
  }

  static Future<void> _initializeOnce() async {
    try {
      await initializer();
      _initialized = true;
    } finally {
      _inFlight = null;
    }
  }

  /// Réservé aux tests : revient à l'état non initialisé.
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _inFlight = null;
    initializer = defaultInitializer;
  }
}
