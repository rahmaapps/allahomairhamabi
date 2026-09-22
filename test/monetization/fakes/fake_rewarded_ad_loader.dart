import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:test_1/monetization/rewarded_ad_loader.dart';

/// Fake de [LoadedRewardedAd] — aucune plateforme native. Permet de simuler
/// précisément chaque callback Google (présentation, récompense, fermeture,
/// échec), dans n'importe quel ordre, y compris des callbacks tardifs ou
/// dupliqués.
class FakeLoadedRewardedAd implements LoadedRewardedAd {
  int disposeCallCount = 0;
  int showCallCount = 0;

  VoidCallback? _onShowed;
  VoidCallback? _onEarned;
  VoidCallback? _onFinished;

  @override
  void show({
    required VoidCallback onShowed,
    required VoidCallback onEarned,
    required VoidCallback onFinished,
  }) {
    showCallCount++;
    _onShowed = onShowed;
    _onEarned = onEarned;
    _onFinished = onFinished;
  }

  /// `onAdShowedFullScreenContent`.
  void simulateShowed() => _onShowed?.call();

  /// `onUserEarnedReward` — seul callback autorisant une récompense.
  void simulateEarned() => _onEarned?.call();

  /// `onAdDismissedFullScreenContent`.
  void simulateDismissed() {
    dispose();
    _onFinished?.call();
  }

  /// `onAdFailedToShowFullScreenContent` : `onShowed` n'est jamais appelé.
  void simulateFailedToShow() {
    dispose();
    _onFinished?.call();
  }

  @override
  void dispose() {
    disposeCallCount++;
  }
}

/// Fake injectable de [RewardedAdLoader], sans compte AdMob ni canal natif.
class FakeRewardedAdLoader implements RewardedAdLoader {
  int loadCallCount = 0;
  final List<FakeLoadedRewardedAd> issuedAds = [];

  /// Si `false`, tout `load()` échoue (retourne `null`).
  bool succeedNextLoad = true;

  /// Si `true`, `load()` lève une exception.
  bool throwOnLoad = false;

  /// Quand `true`, `load()` ne se résout pas seul : le test pilote la
  /// résolution via [completePendingLoad] / [failPendingLoad].
  bool manualCompletion = false;

  final List<Completer<LoadedRewardedAd?>> _pending = [];

  int get pendingLoadCount => _pending.length;

  FakeLoadedRewardedAd completePendingLoad() {
    final ad = FakeLoadedRewardedAd();
    issuedAds.add(ad);
    _pending.removeAt(0).complete(ad);
    return ad;
  }

  void failPendingLoad() => _pending.removeAt(0).complete(null);

  @override
  Future<LoadedRewardedAd?> load() {
    loadCallCount++;

    if (throwOnLoad) return Future<LoadedRewardedAd?>.error(Exception('load'));

    if (manualCompletion) {
      final completer = Completer<LoadedRewardedAd?>();
      _pending.add(completer);
      return completer.future;
    }

    if (!succeedNextLoad) return Future<LoadedRewardedAd?>.value(null);

    final ad = FakeLoadedRewardedAd();
    issuedAds.add(ad);
    return Future<LoadedRewardedAd?>.value(ad);
  }
}
