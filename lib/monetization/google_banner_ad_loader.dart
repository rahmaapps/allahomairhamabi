import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_surface.dart';
import 'ads_config.dart';
import 'banner_ad_loader.dart';

class _GoogleLoadedBannerAd implements LoadedBannerAd {
  _GoogleLoadedBannerAd(this._bannerAd, this.height);

  final BannerAd _bannerAd;
  bool _disposed = false;

  @override
  final double height;

  @override
  Widget buildAdWidget() => AdWidget(ad: _bannerAd);

  @override
  void dispose() {
    // Idempotent (§ audit LOT 5.B) : un double dispose ne doit jamais
    // relancer d'appel plateforme sur un objet déjà libéré.
    if (_disposed) return;
    _disposed = true;
    _bannerAd.dispose();
  }
}

/// Implémentation réelle de [BannerAdLoader], adossée au SDK Google Mobile
/// Ads. Non testée directement en `flutter_test` (canal de plateforme
/// natif) — voir les tests de `BannerAdSlotController`, qui dépendent de
/// l'interface [BannerAdLoader] via un fake, jamais de cette classe.
class GoogleBannerAdLoader implements BannerAdLoader {
  @override
  Future<LoadedBannerAd?> load({
    required AdSurface surface,
    required int width,
  }) async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (size == null) return null;

    final completer = Completer<LoadedBannerAd?>();

    final bannerAd = BannerAd(
      size: size,
      adUnitId: AdsConfig.testBannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(
              _GoogleLoadedBannerAd(ad as BannerAd, size.height.toDouble()),
            );
          }
        },
        onAdFailedToLoad: (ad, error) {
          // Le SDK ne libère jamais lui-même une annonce en échec — à la
          // charge de l'appelant (§ audit LOT 5.B).
          ad.dispose();
          if (kDebugMode) {
            debugPrint(
              '[Monetization] Échec chargement bannière ($surface, '
              '${error.code}): ${error.message}',
            );
          }
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    try {
      await bannerAd.load();
    } catch (e) {
      // Ne doit jamais faire remonter d'exception à l'appelant (§ audit) :
      // un échec de chargement reste un simple `null`.
      if (kDebugMode) debugPrint('[Monetization] Exception chargement bannière: $e');
      bannerAd.dispose();
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }
}
