import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'interstitial_ad_loader.dart';

class _GoogleLoadedInterstitialAd implements LoadedInterstitialAd {
  _GoogleLoadedInterstitialAd(this._ad);

  final InterstitialAd _ad;
  bool _disposed = false;

  @override
  void show({
    required VoidCallback onShowed,
    required VoidCallback onFinished,
  }) {
    var finished = false;
    void finishOnce() {
      if (finished) return;
      finished = true;
      // L'annonce est à usage unique : libérée dès la fin de son cycle,
      // que la présentation ait réussi ou échoué (règle explicite du SDK :
      // `dispose` depuis onAdDismissed/onAdFailedToShow).
      dispose();
      onFinished();
    }

    _ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) => onShowed(),
      onAdDismissedFullScreenContent: (_) => finishOnce(),
      onAdFailedToShowFullScreenContent: (_, error) {
        if (kDebugMode) {
          debugPrint(
            '[Monetization] Échec présentation interstitiel '
            '(${error.code}): ${error.message}',
          );
        }
        finishOnce();
      },
    );

    // Une exception côté plateforme laisserait sinon l'appelant bloqué en
    // état « showing » sans jamais recevoir de callback : traitée comme un
    // échec de présentation (aucun cooldown consommé).
    unawaited(
      _ad.show().catchError((Object e) {
        if (kDebugMode) {
          debugPrint('[Monetization] Exception présentation interstitiel: $e');
        }
        finishOnce();
      }),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ad.dispose();
  }
}

/// Implémentation réelle de [InterstitialAdLoader], adossée au SDK Google
/// Mobile Ads. Non testée directement en `flutter_test` (canal de plateforme
/// natif) — voir les tests de `InterstitialAdController`, qui dépendent de
/// l'interface [InterstitialAdLoader] via un fake.
class GoogleInterstitialAdLoader implements InterstitialAdLoader {
  @override
  Future<LoadedInterstitialAd?> load() async {
    final completer = Completer<LoadedInterstitialAd?>();

    try {
      await InterstitialAd.load(
        adUnitId: AdsConfig.testInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) {
              completer.complete(_GoogleLoadedInterstitialAd(ad));
            }
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              debugPrint(
                '[Monetization] Échec chargement interstitiel '
                '(${error.code}): ${error.message}',
              );
            }
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Monetization] Exception chargement interstitiel: $e');
      }
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }
}
