import 'dart:async';

import '../user_prefs.dart';
import 'ads_availability.dart';
import 'ads_free_status.dart';
import 'ads_policy.dart';
import 'google_interstitial_ad_loader.dart';
import 'interstitial_ad_loader.dart';
import 'interstitial_trigger.dart';
import 'monetization_bootstrap.dart';

/// Cycle de vie d'un interstitiel : `idle → loading → ready → showing → idle`.
enum InterstitialAdState { idle, loading, ready, showing }

/// Service applicatif unique pilotant les interstitiels (LOT 5.C).
///
/// Contrairement à `BannerAdSlotController` (un par widget), un interstitiel
/// n'est lié à aucun écran : il est préchargé en arrière-plan puis présenté
/// sur une transition de navigation éligible. D'où une **instance
/// applicative unique** ([instance]) — garantie structurelle contre les
/// doubles chargements et les doubles présentations.
///
/// Réutilise strictement les briques LOT 5.A : `AdsAvailability`
/// (`canRequestAds()`), `AdsFreeStatus`/`adsSuppressedUntil` et `AdsPolicy`.
/// Aucune logique de consentement ni de suppression publicitaire n'est
/// redéfinie ici.
class InterstitialAdController {
  InterstitialAdController({
    required AdsAvailability adsAvailability,
    required InterstitialAdLoader loader,
  })  : _adsAvailability = adsAvailability,
        _loader = loader;

  /// Instance applicative unique, branchée sur le socle LOT 5.A.
  static final InterstitialAdController instance = InterstitialAdController(
    adsAvailability: MonetizationBootstrap.adsAvailability,
    loader: GoogleInterstitialAdLoader(),
  );

  final AdsAvailability _adsAvailability;
  final InterstitialAdLoader _loader;

  InterstitialAdState _state = InterstitialAdState.idle;
  InterstitialAdState get state => _state;

  LoadedInterstitialAd? _loadedAd;

  /// Garde contre les appels concurrents : deux transitions rapprochées ne
  /// doivent jamais déclencher deux évaluations (donc deux présentations)
  /// en parallèle pendant les `await` de la policy.
  bool _evaluating = false;

  /// Point d'entrée unique, appelé APRÈS qu'une transition de navigation a
  /// déjà eu lieu — la navigation n'attend donc jamais la publicité.
  ///
  /// Ne lève jamais d'exception. Si aucune annonce n'est prête, précharge
  /// silencieusement pour la prochaine transition éligible et n'affiche
  /// rien.
  Future<void> maybeShowOnTransition(InterstitialTrigger trigger) async {
    if (_evaluating) return;
    // Une présentation en cours ou un chargement déjà en vol : ne rien
    // relancer (ni show, ni load concurrent).
    if (_state == InterstitialAdState.showing ||
        _state == InterstitialAdState.loading) {
      return;
    }

    _evaluating = true;
    try {
      // Policy évaluée MAINTENANT, à l'instant de la présentation —
      // jamais réutilisée depuis l'instant du chargement (§ LOT 5.C).
      final allowed = await _isShowAllowed(trigger);
      if (!allowed) return;

      if (_state == InterstitialAdState.ready) {
        final ad = _loadedAd;
        if (ad == null) {
          // Incohérence défensive : repart proprement de zéro.
          _state = InterstitialAdState.idle;
          return;
        }
        _present(ad);
        return;
      }

      // `idle` sans annonce prête : la transition courante ne montre rien
      // (jamais de blocage), on prépare la prochaine.
      await _startLoad();
    } finally {
      _evaluating = false;
    }
  }

  Future<bool> _isShowAllowed(InterstitialTrigger trigger) async {
    final canRequestAds = await _adsAvailability.canRequestAds();
    final adsFreeStatus =
        AdsFreeStatus(await UserPrefs.instance.getAdsSuppressedUntil());
    final lastShownAt = await UserPrefs.instance.getLastInterstitialShownAt();

    return AdsPolicy.canShowInterstitial(
      trigger: trigger,
      canRequestAds: canRequestAds,
      adsFreeStatus: adsFreeStatus,
      lastShownAt: lastShownAt,
    );
  }

  /// Chargement en arrière-plan. Aucune requête n'est émise sans
  /// consentement exploitable ni pendant une fenêtre sans publicité
  /// (briques LOT 5.A). Un échec ramène simplement à `idle` : la prochaine
  /// tentative aura lieu sur une future transition utilisateur, jamais via
  /// une boucle de retry automatique.
  Future<void> _startLoad() async {
    if (_state != InterstitialAdState.idle) return;

    if (!await _adsAvailability.canRequestAds()) return;
    final adsFreeStatus =
        AdsFreeStatus(await UserPrefs.instance.getAdsSuppressedUntil());
    if (adsFreeStatus.isActive()) return;

    // L'état a pu changer pendant les `await` ci-dessus.
    if (_state != InterstitialAdState.idle) return;

    _state = InterstitialAdState.loading;
    final ad = await _loader.load();

    if (ad == null) {
      _state = InterstitialAdState.idle;
      return;
    }

    _loadedAd = ad;
    _state = InterstitialAdState.ready;
  }

  void _present(LoadedInterstitialAd ad) {
    _state = InterstitialAdState.showing;
    // L'annonce est à usage unique : elle quitte l'état `ready` dès sa
    // présentation, elle ne peut donc jamais être présentée deux fois.
    _loadedAd = null;

    ad.show(
      onShowed: () {
        // Présentation EFFECTIVE : seul cas qui consomme le cooldown.
        // Un échec de chargement ou de présentation ne l'entame jamais.
        unawaited(
          UserPrefs.instance.setLastInterstitialShownAt(DateTime.now()),
        );
      },
      onFinished: () {
        // `dismissed` comme `failed-to-show` : l'annonce est déjà libérée
        // par l'implémentation. On repart de `idle` et on précharge la
        // suivante (une seule tentative, pas de boucle).
        _state = InterstitialAdState.idle;
        unawaited(_startLoad());
      },
    );
  }
}
