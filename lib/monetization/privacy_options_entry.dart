import 'package:flutter/foundation.dart';

import 'consent_service.dart';
import 'monetization_bootstrap.dart';

/// Entrée utilisateur « خيارات الخصوصية » (LOT 5.E) — unique consommateur
/// des deux méthodes UMP restées sans appelant depuis le LOT 5.A :
/// `isPrivacyOptionsRequired()` et `showPrivacyOptionsForm()`.
///
/// N'ajoute AUCUNE architecture UMP : aucune nouvelle méthode de
/// consentement, aucun appel direct au plugin `google_mobile_ads`. Ne
/// dépend que de l'interface [ConsentService] du LOT 5.A — dont la vraie
/// implémentation passe par un canal de plateforme natif non mockable en
/// `flutter_test` — exactement comme `AdsAvailability`, pour rester
/// testable via un fake.
///
/// N'a aucun rapport avec l'AFFICHAGE de publicités : l'écran Paramètres
/// reste strictement hors surface publicitaire (aucun `BannerAdSlot`,
/// aucun `AdSurface`, aucun interstitiel). Seul le consentement est
/// concerné ici.
///
/// Contrat strict, à la charge de cette classe et non de l'appelant :
/// **aucune méthode ne lève jamais**. `GoogleUmpConsentService`, lui,
/// n'enveloppe ces deux appels dans aucun `try/catch` (LOT 5.A, non
/// modifié par ce lot) : une exception de plateforme doit donc être
/// absorbée ici, jamais remontée à l'écran Paramètres.
class PrivacyOptionsEntry {
  PrivacyOptionsEntry({
    ConsentService? consentService,
    Future<void> Function()? onConsentSettled,
  })  : _consentService = consentService ?? MonetizationBootstrap.consentService,
        _onConsentSettled =
            onConsentSettled ?? _defaultOnConsentSettled;

  static Future<void> _defaultOnConsentSettled() async {
    await MonetizationBootstrap.ensureAdsInitializedIfAllowed();
  }

  final ConsentService _consentService;

  /// Appelé après la fermeture du formulaire (LOT 5.F, correction A2) : le
  /// consentement a pu changer, le SDK doit donc pouvoir être initialisé
  /// dans la même session, sans redémarrage. Ne déclenche aucune publicité
  /// et ne bloque jamais l'écran.
  final Future<void> Function() _onConsentSettled;

  /// Garde contre les appels concurrents : deux activations rapprochées de
  /// la ligne ne doivent jamais ouvrir deux formulaires UMP.
  bool _opening = false;

  /// `true` si Google exige qu'un point d'entrée « Options de
  /// confidentialité » soit proposé à l'utilisateur ici et maintenant.
  ///
  /// Interrogé à CHAQUE ouverture de l'écran Paramètres, jamais mis en
  /// cache : le statut dépend de `requestConsentInfoUpdate()`, lancé en
  /// tâche de fond au démarrage (`MonetizationBootstrap.runAtLaunch`), et
  /// peut donc ne pas être encore exploitable lors d'une première visite
  /// très précoce ou hors ligne.
  ///
  /// En cas d'erreur : `false` — la ligne est simplement absente, jamais
  /// une exception ni un écran cassé.
  Future<bool> isRequired() async {
    try {
      return await _consentService.isPrivacyOptionsRequired();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Monetization] Statut des options de confidentialité '
          'indisponible: $e',
        );
      }
      return false;
    }
  }

  /// Demande l'affichage du formulaire d'options de confidentialité.
  ///
  /// Retourne `true` si la demande a pu être émise (ou si une demande est
  /// déjà en cours), `false` en cas d'échec — l'appelant se contente alors
  /// d'informer l'utilisateur, sans jamais bloquer la navigation.
  Future<bool> open() async {
    if (_opening) return true;

    _opening = true;
    try {
      await _consentService.showPrivacyOptionsForm();

      // A2 : le consentement a pu être accordé à l'instant. Ne peut pas
      // faire échouer l'ouverture du formulaire, qui a bien eu lieu.
      try {
        await _onConsentSettled();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Monetization] Activation Ads post-consentement ignorée: $e');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Monetization] Échec ouverture des options de confidentialité: $e',
        );
      }
      return false;
    } finally {
      _opening = false;
    }
  }
}
