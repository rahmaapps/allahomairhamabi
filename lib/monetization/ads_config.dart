import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Configuration Ads — socle LOT 5.A + bannières LOT 5.B. Aucune publicité
/// réelle en production n'est visée par ces deux lots. N'utilise que des
/// identifiants de TEST officiels Google (jamais de production) tant
/// qu'aucun lot n'active l'affichage réel (§17 audit LOT 5.A).
class AdsConfig {
  const AdsConfig._();

  /// App ID de TEST Google Mobile Ads — identique pour tous les
  /// développeurs (https://developers.google.com/admob/android/test-ads).
  /// Déclaré dans AndroidManifest.xml
  /// (meta-data `com.google.android.gms.ads.APPLICATION_ID`). À remplacer
  /// par le véritable App ID AdMob de l'app uniquement lors du lot qui
  /// active réellement l'affichage de publicités (hors périmètre 5.A).
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Ad Unit ID de TEST Google pour une bannière (LOT 5.B — audit §17 :
  /// « utiliser uniquement l'ID Banner de test officiel Google »). Jamais
  /// un id de production. L'app ne cible que Android en pratique
  /// (`ios: false` dans pubspec.yaml) ; l'id iOS de test est inclus par
  /// robustesse si le plugin est néanmoins compilé pour cette plateforme.
  static String get testBannerAdUnitId {
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  /// Ad Unit ID de TEST Google pour un interstitiel (LOT 5.C). Jamais un
  /// id de production — même discipline que [testBannerAdUnitId].
  static String get testInterstitialAdUnitId {
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  /// Mettre à `true` localement (jamais commité) pour forcer le
  /// formulaire UMP en géographie EEE pendant un test manuel du socle
  /// 5.A. `false` par défaut : le comportement suit la géographie réelle
  /// de l'appareil, comme en production.
  static const bool forceEeaConsentDebug = false;

  static ConsentDebugSettings? get debugSettings {
    if (!forceEeaConsentDebug) return null;
    return ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
    );
  }
}
