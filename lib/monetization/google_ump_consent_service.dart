import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'consent_service.dart';

/// Implémentation réelle de [ConsentService], adossée au SDK Google User
/// Messaging Platform (`google_mobile_ads`). Non testée directement en
/// `flutter_test` (canal de plateforme natif) — voir les tests de
/// `AdsAvailability`/`AdsPolicy`, qui dépendent de l'interface [ConsentService]
/// via un fake, jamais de cette classe.
class GoogleUmpConsentService implements ConsentService {
  @override
  Future<void> requestConsentUpdate() async {
    final infoUpdated = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(consentDebugSettings: AdsConfig.debugSettings),
      () {
        if (!infoUpdated.isCompleted) infoUpdated.complete();
      },
      (formError) {
        if (kDebugMode) {
          debugPrint(
            '[Monetization] Échec mise à jour consentement UMP '
            '(${formError.errorCode}): ${formError.message}',
          );
        }
        if (!infoUpdated.isCompleted) infoUpdated.complete();
      },
    );

    await infoUpdated.future;

    // Charge et affiche le formulaire UMP UNIQUEMENT s'il est requis —
    // comportement garanti par l'API du plugin elle-même (§4 audit LOT 5.A).
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
        if (formError != null && kDebugMode) {
          debugPrint(
            '[Monetization] Erreur formulaire UMP '
            '(${formError.errorCode}): ${formError.message}',
          );
        }
      });
    } catch (e) {
      // Ne doit jamais faire échouer le lancement de l'app (§7 audit
      // LOT 5.A) : un échec ici laisse simplement canRequestAds() à false.
      if (kDebugMode) {
        debugPrint('[Monetization] Exception formulaire UMP: $e');
      }
    }
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<void> showPrivacyOptionsForm() {
    return ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null && kDebugMode) {
        debugPrint(
          '[Monetization] Erreur formulaire options de confidentialité '
          '(${formError.errorCode}): ${formError.message}',
        );
      }
    });
  }
}
