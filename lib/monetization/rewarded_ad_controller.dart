import 'dart:async';

import 'package:flutter/foundation.dart';

import '../user_prefs.dart';
import 'ads_availability.dart';
import 'ads_config.dart';
import 'ads_free_status.dart';
import 'google_rewarded_ad_loader.dart';
import 'monetization_bootstrap.dart';
import 'reward_effects.dart';
import 'reward_kind.dart';
import 'reward_service.dart';
import 'rewarded_ad_loader.dart';

/// Cycle de vie observable d'un Rewarded.
enum RewardedAdState { idle, loading, ready, showing }

/// Implémentation réelle de [RewardService] (LOT 5.G.A).
///
/// Même patron que `InterstitialAdController` : **instance applicative
/// unique** ([instance]), dépendance à l'abstraction [RewardedAdLoader]
/// uniquement, réutilisation stricte des briques existantes
/// (`AdsAvailability.canRequestAds()`, `adsSuppressedUntil`,
/// `RewardEffects`). Aucune logique de consentement redéfinie ici.
///
/// Contrats verrouillés :
/// - totalement volontaire : ce service ne se déclenche jamais seul, il
///   n'agit qu'à l'appel explicite de [requestRewardOutcome] ;
/// - récompense accordée **uniquement** sur `onUserEarnedReward`, une seule
///   fois, avec un effet horodaté à l'instant exact de ce callback ;
/// - fermeture avant récompense, échec de chargement, échec de
///   présentation, délai dépassé : aucune récompense ;
/// - ne lève jamais, ne bloque jamais la navigation.
///
/// Aucun point d'appel UI n'existe encore : le branchement relève d'un lot
/// UX ultérieur.
class RewardedAdController implements RewardService {
  RewardedAdController({
    required AdsAvailability adsAvailability,
    required RewardedAdLoader loader,
    bool Function()? isAdUnitConfigured,
    DateTime Function()? clock,
    Future<void> Function(RewardKind kind, DateTime earnedAt)? applyEffect,
    Duration loadTimeout = defaultLoadTimeout,
    Duration readyAdTtl = defaultReadyAdTtl,
  })  : _adsAvailability = adsAvailability,
        _loader = loader,
        _isAdUnitConfigured =
            isAdUnitConfigured ?? (() => AdsConfig.isRewardedAdUnitConfigured),
        _clock = clock ?? DateTime.now,
        _applyEffect = applyEffect ?? _defaultApplyEffect,
        _loadTimeout = loadTimeout,
        _readyAdTtl = readyAdTtl;

  /// Instance applicative unique, branchée sur le socle LOT 5.A.
  static final RewardedAdController instance = RewardedAdController(
    adsAvailability: MonetizationBootstrap.adsAvailability,
    loader: GoogleRewardedAdLoader(),
  );

  /// Au-delà, un chargement est traité comme un échec — jamais d'attente
  /// infinie pour l'utilisateur.
  static const Duration defaultLoadTimeout = Duration(seconds: 15);

  /// Une annonce préchargée n'est plus présentée au-delà de cette durée :
  /// Google fait expirer les Rewarded chargés depuis trop longtemps. Marge
  /// volontaire sous l'heure.
  static const Duration defaultReadyAdTtl = Duration(minutes: 55);

  static Future<void> _defaultApplyEffect(RewardKind kind, DateTime earnedAt) =>
      RewardEffects.apply(kind, earnedAt: earnedAt);

  final AdsAvailability _adsAvailability;
  final RewardedAdLoader _loader;
  final bool Function() _isAdUnitConfigured;
  final DateTime Function() _clock;
  final Future<void> Function(RewardKind, DateTime) _applyEffect;
  final Duration _loadTimeout;
  final Duration _readyAdTtl;

  /// Une demande est en cours (chargement pour présentation ou
  /// présentation) : toute autre demande est refusée — garantie
  /// structurelle contre le double show.
  bool _busy = false;
  bool _showing = false;
  bool _loadingForUse = false;

  LoadedRewardedAd? _readyAd;
  DateTime? _readyLoadedAt;
  Future<void>? _preloading;

  RewardedAdState get state {
    if (_showing) return RewardedAdState.showing;
    if (_loadingForUse || _preloading != null) return RewardedAdState.loading;
    if (_readyAd != null) return RewardedAdState.ready;
    return RewardedAdState.idle;
  }

  /// Lecture seule, destinée à une future sonde « publicité plein écran en
  /// cours » (décision D6 de l'évaluation).
  bool get isShowing => _showing;

  // ==========================================================
  // Décision pure
  // ==========================================================

  /// Conditions préalables à toute tentative — aucune requête réseau n'est
  /// émise si l'une manque :
  /// - unité Rewarded configurée (jamais de requête avec un placeholder de
  ///   production) ;
  /// - `canRequestAds()` vrai (porte unique de consentement, LOT 5.A) ;
  /// - aucune fenêtre sans publicité active : pendant l'heure accordée par
  ///   un Rewarded, aucune publicité — Rewarded compris — n'est présentée.
  static bool isAttemptAllowed({
    required bool adUnitConfigured,
    required bool canRequestAds,
    required AdsFreeStatus adsFreeStatus,
    DateTime? now,
  }) {
    if (!adUnitConfigured) return false;
    if (!canRequestAds) return false;
    if (adsFreeStatus.isActive(now: now)) return false;
    return true;
  }

  Future<bool> _canAttempt() async {
    final canRequestAds = await _adsAvailability.canRequestAds();
    final adsFreeStatus =
        AdsFreeStatus(await UserPrefs.instance.getAdsSuppressedUntil());
    return isAttemptAllowed(
      adUnitConfigured: _isAdUnitConfigured(),
      canRequestAds: canRequestAds,
      adsFreeStatus: adsFreeStatus,
      now: _clock(),
    );
  }

  // ==========================================================
  // RewardService
  // ==========================================================

  @override
  Future<bool> requestReward(RewardKind kind) async =>
      await requestRewardOutcome(kind) == RewardOutcome.earned;

  @override
  Future<RewardOutcome> requestRewardOutcome(RewardKind kind) async {
    if (_busy) return RewardOutcome.unavailable;
    _busy = true;

    try {
      if (!await _canAttempt()) return RewardOutcome.unavailable;

      final ad = await _obtainAd();
      if (ad == null) return RewardOutcome.failed;

      // Revalidé à l'instant de la présentation, jamais réutilisé depuis le
      // chargement (même règle que les interstitiels).
      if (!await _canAttempt()) {
        _keepOrDispose(ad);
        return RewardOutcome.unavailable;
      }

      return await _present(ad, kind);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Monetization] Rewarded non bloquant — erreur ignorée: $e');
      }
      return RewardOutcome.failed;
    } finally {
      _busy = false;
    }
  }

  // ==========================================================
  // Chargement
  // ==========================================================

  Future<LoadedRewardedAd?> _obtainAd() async {
    // Un préchargement en vol : on l'attend plutôt que d'en lancer un
    // second — jamais deux chargements concurrents.
    final preloading = _preloading;
    if (preloading != null) await preloading;

    final ready = _takeFreshReadyAd();
    if (ready != null) return ready;

    _loadingForUse = true;
    try {
      return await _loadWithTimeout();
    } finally {
      _loadingForUse = false;
    }
  }

  LoadedRewardedAd? _takeFreshReadyAd() {
    final ad = _readyAd;
    final loadedAt = _readyLoadedAt;
    _readyAd = null;
    _readyLoadedAt = null;
    if (ad == null || loadedAt == null) return null;

    if (_clock().difference(loadedAt) >= _readyAdTtl) {
      ad.dispose();
      return null;
    }
    return ad;
  }

  void _keepOrDispose(LoadedRewardedAd ad) {
    if (_readyAd == null) {
      _readyAd = ad;
      _readyLoadedAt = _clock();
    } else {
      ad.dispose();
    }
  }

  /// Un chargement arrivé APRÈS le délai n'est jamais conservé : l'annonce
  /// est libérée immédiatement, sans fuite native.
  Future<LoadedRewardedAd?> _loadWithTimeout() {
    final completer = Completer<LoadedRewardedAd?>();
    final timer = Timer(_loadTimeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });

    _loader.load().then(
      (ad) {
        if (completer.isCompleted) {
          ad?.dispose();
          return;
        }
        timer.cancel();
        completer.complete(ad);
      },
      onError: (Object e) {
        if (completer.isCompleted) return;
        timer.cancel();
        completer.complete(null);
      },
    );

    return completer.future;
  }

  /// Préchargement suivant, déclenché uniquement après la fin d'un Rewarded
  /// demandé par l'utilisateur — jamais au démarrage, jamais sans demande
  /// préalable. Une seule tentative, aucune boucle de retry.
  Future<void> _preloadNext() async {
    if (_readyAd != null || _preloading != null) return;

    final completer = Completer<void>();
    _preloading = completer.future;
    try {
      if (!await _canAttempt()) return;
      final ad = await _loadWithTimeout();
      if (ad == null) return;
      _keepOrDispose(ad);
    } catch (_) {
      // Non bloquant : le prochain Rewarded chargera à la demande.
    } finally {
      _preloading = null;
      completer.complete();
    }
  }

  // ==========================================================
  // Présentation
  // ==========================================================

  Future<RewardOutcome> _present(LoadedRewardedAd ad, RewardKind kind) {
    final completer = Completer<RewardOutcome>();
    var showed = false;
    var earned = false;
    var finished = false;
    Future<void>? effect;

    _showing = true;

    ad.show(
      onShowed: () {
        if (!finished) showed = true;
      },
      onEarned: () {
        // Double callback ou callback tardif après la fin du cycle :
        // jamais une seconde récompense.
        if (finished || earned) return;
        earned = true;
        // Instant capturé DANS le callback onUserEarnedReward (D6) — ni au
        // chargement, ni au début de la présentation, ni à la fermeture.
        final earnedAt = _clock();
        effect = _applyEffectSafely(kind, earnedAt);
      },
      onFinished: () {
        if (finished) return;
        finished = true;
        _showing = false;

        () async {
          // L'effet est persisté AVANT de rendre la main à l'appelant.
          await effect;
          final RewardOutcome outcome;
          if (earned) {
            outcome = RewardOutcome.earned;
          } else if (showed) {
            outcome = RewardOutcome.dismissedWithoutReward;
          } else {
            outcome = RewardOutcome.failed;
          }
          completer.complete(outcome);
          unawaited(_preloadNext());
        }();
      },
    );

    return completer.future;
  }

  Future<void> _applyEffectSafely(RewardKind kind, DateTime earnedAt) async {
    try {
      await _applyEffect(kind, earnedAt);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Monetization] Effet de récompense non appliqué: $e');
      }
    }
  }
}
