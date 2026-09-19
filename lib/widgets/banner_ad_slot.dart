import 'package:flutter/material.dart';

import '../monetization/ad_surface.dart';
import '../monetization/ads_availability.dart';
import '../monetization/banner_ad_loader.dart';
import '../monetization/banner_ad_slot_controller.dart';
import '../monetization/google_banner_ad_loader.dart';
import '../monetization/monetization_bootstrap.dart';

/// Emplacement de bannière AdMob adaptive anchored (LOT 5.B). Hauteur NULLE
/// tant qu'aucune annonce n'est chargée avec succès — jamais de retard du
/// contenu principal, jamais d'espace résiduel en cas d'échec/refus
/// (§ audit LOT 5.B).
///
/// À placer UNIQUEMENT sur `Scaffold.bottomNavigationBar` de HOME
/// (`AdSurface.home`), Recherche (`AdSurface.search`) et Favoris
/// (`AdSurface.favorites`). Ne JAMAIS l'ajouter à DuaRead, Grave Visit,
/// Onboarding, Splash ou Settings — `AdsPolicy` refuse déjà ces surfaces
/// en interne, mais la règle produit verrouillée reste : ce composant n'est
/// tout simplement jamais importé par ces écrans.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({
    super.key,
    required this.surface,
    AdsAvailability? adsAvailability,
    BannerAdLoader? loader,
  })  : _adsAvailability = adsAvailability,
        _loader = loader;

  final AdSurface surface;

  /// Injection réservée aux tests. `null` en usage réel : utilise le
  /// socle LOT 5.A (`MonetizationBootstrap.adsAvailability`) et
  /// l'implémentation Google (`GoogleBannerAdLoader`).
  final AdsAvailability? _adsAvailability;
  final BannerAdLoader? _loader;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  late final BannerAdSlotController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BannerAdSlotController(
      surface: widget.surface,
      adsAvailability:
          widget._adsAvailability ?? MonetizationBootstrap.adsAvailability,
      loader: widget._loader ?? GoogleBannerAdLoader(),
    )..addListener(_onControllerChanged);

    // §audit LOT 5.B : le contenu principal s'affiche immédiatement — le
    // chargement ne démarre qu'APRÈS le premier frame, jamais pendant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final width = MediaQuery.sizeOf(context).width.truncate();
      _controller.requestLoad(width: width);
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadedAd = _controller.loadedAd;

    // idle / refused / loading / failed : hauteur nulle, aucun espace
    // résiduel — seul l'état `loaded` rend un widget de taille non nulle.
    if (_controller.state != BannerAdSlotState.loaded || loadedAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: loadedAd.height,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: loadedAd.buildAdWidget(),
        ),
      ),
    );
  }
}
