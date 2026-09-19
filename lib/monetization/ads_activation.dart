import 'package:flutter/foundation.dart';

import 'ads_availability.dart';
import 'ads_sdk_initializer.dart';
import 'consent_service.dart';

/// Active le SDK publicitaire **dès que — et seulement si — le consentement
/// l'autorise** (correction A2, LOT 5.F).
///
/// Avant ce lot, le SDK n'était initialisé qu'au lancement, et uniquement si
/// `canRequestAds()` était déjà vrai à cet instant : un utilisateur accordant
/// son consentement plus tard dans la session (notamment via
/// « خيارات الخصوصية », ajouté au LOT 5.E) ne voyait aucune publicité
/// jusqu'au redémarrage de l'application.
///
/// Cette classe ne change **aucune** décision produit : elle ne fait que
/// permettre de refaire, au bon moment, exactement le contrôle déjà écrit au
/// LOT 5.A. Le refus ou l'absence de consentement exploitable continue
/// d'interdire toute requête publicitaire, et rien n'est affiché ici :
/// initialiser le SDK ne charge ni ne présente la moindre annonce.
class AdsActivation {
  AdsActivation({
    required ConsentService consentService,
    required AdsAvailability adsAvailability,
    Future<void> Function()? initializeSdk,
  })  : _consentService = consentService,
        _adsAvailability = adsAvailability,
        _initializeSdk = initializeSdk ?? AdsSdkInitializer.initializeIfNeeded;

  final ConsentService _consentService;
  final AdsAvailability _adsAvailability;
  final Future<void> Function() _initializeSdk;

  /// Garde de concurrence : deux appels simultanés (lancement + ouverture
  /// des options de confidentialité, par exemple) partagent la même
  /// tentative — jamais deux initialisations.
  Future<bool>? _inFlight;

  /// `true` si le SDK est initialisé et exploitable à l'issue de l'appel.
  ///
  /// Ne lève jamais : une erreur de plateforme, un consentement refusé ou
  /// indisponible retournent simplement `false`, sans bloquer l'appelant ni
  /// l'interface.
  Future<bool> ensureInitializedIfAllowed() {
    if (_adsAvailability.isSdkInitialized) return Future<bool>.value(true);

    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _run();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<bool> _run() async {
    try {
      // Exactement le même contrôle qu'au LOT 5.A, rejoué au bon moment.
      if (!await _consentService.canRequestAds()) return false;

      await _initializeSdk();
      _adsAvailability.markSdkInitialized();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Monetization] Activation Ads non bloquante — erreur ignorée: $e');
      }
      return false;
    }
  }
}
