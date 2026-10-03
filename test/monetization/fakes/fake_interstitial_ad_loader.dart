import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:test_1/monetization/interstitial_ad_loader.dart';

/// Fake de [LoadedInterstitialAd] — aucune plateforme native. Permet de
/// simuler précisément les trois issues réelles : présentation effective
/// puis fermeture, échec de présentation, et annonce jamais présentée.
class FakeLoadedInterstitialAd implements LoadedInterstitialAd {
  int disposeCallCount = 0;
  int showCallCount = 0;

  VoidCallback? _onShowed;
  VoidCallback? _onFinished;

  @override
  void show({
    required VoidCallback onShowed,
    required VoidCallback onFinished,
  }) {
    showCallCount++;
    _onShowed = onShowed;
    _onFinished = onFinished;
  }

  /// Simule une présentation effective (`onAdShowedFullScreenContent`).
  void simulateShowed() => _onShowed?.call();

  /// Simule la fermeture par l'utilisateur après présentation effective.
  void simulateDismissed() {
    dispose();
    _onFinished?.call();
  }

  /// Simule un échec de présentation : `onShowed` n'est JAMAIS appelé.
  void simulateFailedToShow() {
    dispose();
    _onFinished?.call();
  }

  @override
  void dispose() {
    disposeCallCount++;
  }
}

/// Fake injectable de [InterstitialAdLoader] — contrôle manuel de la
/// résolution (succès/échec), sans aucun compte AdMob ni canal natif.
class FakeInterstitialAdLoader implements InterstitialAdLoader {
  int loadCallCount = 0;
  final List<FakeLoadedInterstitialAd> issuedAds = [];

  /// Si `false`, tout `load()` échoue (retourne `null`).
  bool succeedNextLoad = true;

  /// Quand `true`, `load()` ne se résout pas tout seul : le test pilote la
  /// résolution via [completePendingLoad].
  bool manualCompletion = false;

  final List<Completer<LoadedInterstitialAd?>> _pending = [];

  FakeLoadedInterstitialAd completePendingLoad() {
    final ad = FakeLoadedInterstitialAd();
    issuedAds.add(ad);
    _pending.removeLast().complete(ad);
    return ad;
  }

  void failPendingLoad() => _pending.removeLast().complete(null);

  @override
  Future<LoadedInterstitialAd?> load() {
    loadCallCount++;

    if (manualCompletion) {
      final completer = Completer<LoadedInterstitialAd?>();
      _pending.add(completer);
      return completer.future;
    }

    if (!succeedNextLoad) return Future<LoadedInterstitialAd?>.value(null);

    final ad = FakeLoadedInterstitialAd();
    issuedAds.add(ad);
    return Future<LoadedInterstitialAd?>.value(ad);
  }
}
