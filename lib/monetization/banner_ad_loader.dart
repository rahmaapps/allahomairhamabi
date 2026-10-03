import 'package:flutter/widgets.dart';

import 'ad_surface.dart';

/// Résultat d'un chargement de bannière réussi. Opaque côté appelant : le
/// widget d'affichage n'a jamais besoin de connaître le type concret de
/// l'annonce (réel `google_mobile_ads` ou fake de test) — seulement sa
/// hauteur et comment la peindre.
abstract class LoadedBannerAd {
  /// Hauteur réelle de l'annonce chargée (px logiques) — jamais une valeur
  /// devinée, toujours celle rapportée par le SDK (ou le fake en test).
  double get height;

  /// Construit le widget d'affichage. Ne doit être appelé qu'après un
  /// chargement confirmé — jamais de manière optimiste (§ audit LOT 5.B :
  /// `AdWidget` uniquement après `onAdLoaded`).
  Widget buildAdWidget();

  /// Libère les ressources natives associées. Doit être idempotent :
  /// appelable plusieurs fois sans effet de bord au-delà du premier appel.
  void dispose();
}

/// Abstraction du chargement d'une bannière adaptive anchored. La vraie
/// implémentation (`GoogleBannerAdLoader`) appelle un canal de plateforme
/// natif non mockable en `flutter_test` (même limitation déjà documentée
/// pour `ConsentService`/`RewardService`, LOT 5.A) — `BannerAdSlotController`
/// dépend donc de cette interface, jamais directement du plugin, pour
/// rester testable via un fake.
abstract class BannerAdLoader {
  /// Charge une bannière adaptive anchored pour [surface], dimensionnée à
  /// [width] (largeur logique de l'écran, px, tronquée). Retourne `null`
  /// en cas d'échec — ne lève jamais d'exception : un échec de chargement
  /// (réseau indisponible, aucun remplissage, etc.) doit laisser l'app
  /// pleinement fonctionnelle sans bannière (§ audit LOT 5.B).
  Future<LoadedBannerAd?> load({required AdSurface surface, required int width});
}
