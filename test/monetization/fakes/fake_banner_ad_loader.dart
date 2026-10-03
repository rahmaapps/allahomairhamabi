import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:test_1/monetization/ad_surface.dart';
import 'package:test_1/monetization/banner_ad_loader.dart';

/// Fake de [LoadedBannerAd] — pas de canal natif, juste un compteur de
/// dispose pour détecter toute fuite/double-libération dans les tests.
class FakeLoadedBannerAd implements LoadedBannerAd {
  FakeLoadedBannerAd({this.height = 50});

  @override
  final double height;

  int disposeCallCount = 0;

  @override
  Widget buildAdWidget() => const SizedBox(key: Key('fake-banner-ad'));

  @override
  void dispose() {
    disposeCallCount++;
  }
}

/// Fake injectable de [BannerAdLoader] — contrôle manuel de la résolution
/// (succès/échec/jamais) pour tester `BannerAdSlotController` sans canal de
/// plateforme natif (même limitation que ConsentService/RewardService,
/// LOT 5.A). Chaque appel `load()` ouvre un nouveau `Completer` : permet de
/// vérifier qu'une navigation répétée déclenche bien un nouveau chargement
/// par instance, jamais un cumul sur un état partagé.
class FakeBannerAdLoader implements BannerAdLoader {
  int loadCallCount = 0;
  final List<FakeLoadedBannerAd> issuedAds = [];
  final List<Completer<LoadedBannerAd?>> _pendingCompleters = [];

  /// Résout le dernier appel `load()` en attente avec un succès.
  FakeLoadedBannerAd completeWithSuccess({double height = 50}) {
    final ad = FakeLoadedBannerAd(height: height);
    issuedAds.add(ad);
    _pendingCompleters.removeLast().complete(ad);
    return ad;
  }

  /// Résout le dernier appel `load()` en attente par un échec.
  void completeWithFailure() {
    _pendingCompleters.removeLast().complete(null);
  }

  @override
  Future<LoadedBannerAd?> load({
    required AdSurface surface,
    required int width,
  }) {
    loadCallCount++;
    final completer = Completer<LoadedBannerAd?>();
    _pendingCompleters.add(completer);
    return completer.future;
  }
}
