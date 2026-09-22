import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'rewarded_ad_loader.dart';

class _GoogleLoadedRewardedAd implements LoadedRewardedAd {
  _GoogleLoadedRewardedAd(this._ad);

  final RewardedAd _ad;
  bool _disposed = false;
  bool _shown = false;

  /// Court délai entre `onAdDismissedFullScreenContent` et la fin du cycle
  /// de vie. Sur Android, `onUserEarnedReward` précède normalement la
  /// fermeture ; ce délai protège le cas — non garanti par le SDK — où les
  /// deux événements natifs arriveraient dans l'ordre inverse, afin qu'une
  /// récompense réellement gagnée ne soit jamais perdue.
  static const Duration _lateRewardGrace = Duration(milliseconds: 300);

  @override
  void show({
    required VoidCallback onShowed,
    required VoidCallback onEarned,
    required VoidCallback onFinished,
  }) {
    // Protection contre le double show : une annonce n'est présentée
    // qu'une fois, quel que soit le nombre d'appels.
    if (_shown || _disposed) return;
    _shown = true;

    var finished = false;
    void finishOnce() {
      if (finished) return;
      finished = true;
      dispose();
      onFinished();
    }

    _ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) {
        if (!finished) onShowed();
      },
      onAdDismissedFullScreenContent: (_) {
        Timer(_lateRewardGrace, finishOnce);
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        if (kDebugMode) {
          debugPrint(
            '[Monetization] Échec présentation Rewarded '
            '(${error.code}): ${error.message}',
          );
        }
        finishOnce();
      },
    );

    unawaited(
      _ad.show(
        onUserEarnedReward: (_, __) {
          // Callback tardif après la fin du cycle : ignoré.
          if (!finished) onEarned();
        },
      ).catchError((Object e) {
        if (kDebugMode) {
          debugPrint('[Monetization] Exception présentation Rewarded: $e');
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

/// Implémentation réelle de [RewardedAdLoader], adossée au SDK Google Mobile
/// Ads. Non testée directement en `flutter_test` (canal natif) — voir les
/// tests de `RewardedAdController`, qui passent par un fake.
class GoogleRewardedAdLoader implements RewardedAdLoader {
  @override
  Future<LoadedRewardedAd?> load() async {
    final completer = Completer<LoadedRewardedAd?>();

    try {
      await RewardedAd.load(
        adUnitId: AdsConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (completer.isCompleted) {
              // Chargement arrivé trop tard : libéré, jamais conservé.
              ad.dispose();
              return;
            }
            completer.complete(_GoogleLoadedRewardedAd(ad));
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              debugPrint(
                '[Monetization] Échec chargement Rewarded '
                '(${error.code}): ${error.message}',
              );
            }
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Monetization] Exception chargement Rewarded: $e');
      }
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }
}
