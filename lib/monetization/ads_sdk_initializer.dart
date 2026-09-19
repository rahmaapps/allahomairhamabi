import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Initialise le SDK Google Mobile Ads. Idempotent : un second appel est un
/// no-op. Ne déclenche elle-même aucune requête publicitaire — c'est
/// [AdsAvailability] (couplée au consentement UMP) qui reste la source
/// unique de vérité consultée avant toute future demande d'annonce.
class AdsSdkInitializer {
  AdsSdkInitializer._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initializeIfNeeded() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Réservé aux tests : revient à l'état non initialisé.
  @visibleForTesting
  static void resetForTesting() => _initialized = false;
}
