import 'package:flutter/foundation.dart';

import '../user_prefs.dart';
import 'ad_surface.dart';
import 'ads_availability.dart';
import 'ads_free_status.dart';
import 'ads_policy.dart';
import 'banner_ad_loader.dart';

/// États du cycle de vie d'un emplacement de bannière. Une seule tentative
/// de chargement par instance — aucune retry automatique (§ audit LOT 5.B).
enum BannerAdSlotState {
  /// Aucune tentative de chargement n'a encore été demandée.
  idle,

  /// Policy refusée (surface non éligible, `canRequestAds` faux, ou
  /// suppression temporaire active) — jamais de requête réseau émise.
  refused,

  /// Chargement en cours.
  loading,

  /// Annonce chargée avec succès — voir [loadedAd].
  loaded,

  /// Échec de chargement — l'app reste pleinement fonctionnelle, aucun
  /// espace résiduel ne doit être rendu par l'appelant.
  failed,
}

/// État machine pur (aucune dépendance widget, entièrement testable) qui
/// pilote le cycle de vie d'un emplacement de bannière :
/// idle → refused OU idle → loading → (loaded | failed).
///
/// Réutilise strictement `AdsPolicy`/`AdsAvailability`/`AdsFreeStatus` du
/// LOT 5.A — ne redéfinit aucune règle de décision ici.
class BannerAdSlotController extends ChangeNotifier {
  BannerAdSlotController({
    required this.surface,
    required AdsAvailability adsAvailability,
    required BannerAdLoader loader,
  })  : _adsAvailability = adsAvailability,
        _loader = loader;

  final AdSurface surface;
  final AdsAvailability _adsAvailability;
  final BannerAdLoader _loader;

  BannerAdSlotState _state = BannerAdSlotState.idle;
  BannerAdSlotState get state => _state;

  LoadedBannerAd? _loadedAd;
  LoadedBannerAd? get loadedAd => _loadedAd;

  bool _disposed = false;
  bool _requested = false;

  /// À appeler une seule fois par instance (typiquement après le premier
  /// frame, voir `BannerAdSlot`). Un second appel est un no-op : garantit
  /// "une seule instance par BannerAdSlot" (§ audit LOT 5.B) — jamais deux
  /// chargements concurrents pour le même emplacement.
  Future<void> requestLoad({required int width}) async {
    if (_requested || _disposed) return;
    _requested = true;

    if (!AdsPolicy.isBannerEligible(surface)) {
      _setState(BannerAdSlotState.refused);
      return;
    }

    final canRequestAds = await _adsAvailability.canRequestAds();
    if (_disposed) return;

    final adsSuppressedUntil = await UserPrefs.instance.getAdsSuppressedUntil();
    if (_disposed) return;

    final allowed = AdsPolicy.canShowBanner(
      surface: surface,
      canRequestAds: canRequestAds,
      adsFreeStatus: AdsFreeStatus(adsSuppressedUntil),
    );

    if (!allowed) {
      _setState(BannerAdSlotState.refused);
      return;
    }

    _setState(BannerAdSlotState.loading);

    final result = await _loader.load(surface: surface, width: width);

    if (_disposed) {
      // Late callback après dispose (§ audit LOT 5.B) : une annonce
      // arrivée après la destruction du widget n'est JAMAIS assignée à
      // l'état — libérée immédiatement pour éviter toute fuite native.
      result?.dispose();
      return;
    }

    if (result == null) {
      _setState(BannerAdSlotState.failed);
    } else {
      _loadedAd = result;
      _setState(BannerAdSlotState.loaded);
    }
  }

  void _setState(BannerAdSlotState next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadedAd?.dispose();
    _loadedAd = null;
    super.dispose();
  }
}
