import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Environnement publicitaire sélectionné à la compilation.
enum AdsEnvironment {
  /// Identifiants de démonstration officiels Google — aucune impression
  /// réelle, aucun revenu, aucun risque de trafic invalide.
  test,

  /// Identifiants réels de l'éditeur.
  production,
}

/// Configuration Ads — socle LOT 5.A, étendu au LOT 5.F par la séparation
/// explicite test / production.
///
/// ## Sélection de l'environnement
///
/// `--dart-define=ADS_ENV=test|production`, **défaut : `test`**. La bascule
/// est donc toujours explicite : un build release ordinaire reste en test,
/// et aucune configuration ne peut passer en production « par accident »
/// du seul fait d'être une release.
///
/// Une valeur inconnue retombe sur `test` (jamais production) : côté Dart
/// l'erreur ne peut que dégrader vers le mode sûr, tandis que Gradle, lui,
/// **échoue explicitement** sur une valeur invalide — l'incohérence est donc
/// signalée bruyamment au build, jamais silencieusement en production.
///
/// ## Source unique de vérité
///
/// Les mêmes identifiants sont déclarés dans `android/ads_ids.properties`,
/// lu par Gradle pour injecter l'App ID dans `AndroidManifest.xml`.
/// `test/monetization/ads_config_test.dart` échoue si les deux divergent.
class AdsConfig {
  const AdsConfig._();

  // ==========================================================
  // Environnement
  // ==========================================================

  static const String testEnvName = 'test';
  static const String productionEnvName = 'production';

  /// Nom de la variable `--dart-define` pilotant l'environnement.
  static const String adsEnvDefineName = 'ADS_ENV';

  static const String _rawAdsEnv =
      String.fromEnvironment(adsEnvDefineName, defaultValue: testEnvName);

  /// Résolution pure, testable sans recompilation : tout ce qui n'est pas
  /// exactement `production` est traité comme `test`.
  static AdsEnvironment resolveEnvironment(String raw) =>
      raw == productionEnvName ? AdsEnvironment.production : AdsEnvironment.test;

  /// Environnement réellement compilé dans ce binaire.
  static AdsEnvironment get environment => resolveEnvironment(_rawAdsEnv);

  static bool get isProduction => environment == AdsEnvironment.production;

  // ==========================================================
  // Identifiants de TEST (démonstration officielle Google)
  // https://developers.google.com/admob/android/test-ads
  // ==========================================================

  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  static const String testAndroidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String testAndroidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  /// Préfixe éditeur des identifiants de démonstration Google. Sert aux
  /// contrôles : un identifiant de production ne doit JAMAIS le porter.
  static const String googleDemoPublisherPrefix = 'ca-app-pub-3940256099942544';

  // ==========================================================
  // Identifiants de PRODUCTION
  // ==========================================================

  /// Préfixe des valeurs non encore renseignées. Aucun identifiant de
  /// production n'est inventé : les vraies valeurs seront injectées ici et
  /// dans `android/ads_ids.properties` une fois le compte et les unités
  /// AdMob créés.
  static const String productionPlaceholderPrefix = 'PLACEHOLDER_PRODUCTION_';

  static const String productionAppId = 'PLACEHOLDER_PRODUCTION_APP_ID';

  /// **Une seule** unité Banner pour les trois surfaces autorisées (HOME,
  /// Recherche, Favoris) — décision produit LOT 5.F. La distinction des
  /// surfaces reste portée par `AdSurface`, jamais par l'unité.
  static const String productionBannerAdUnitId =
      'PLACEHOLDER_PRODUCTION_BANNER_AD_UNIT_ID';

  static const String productionInterstitialAdUnitId =
      'PLACEHOLDER_PRODUCTION_INTERSTITIAL_AD_UNIT_ID';

  static bool isProductionPlaceholder(String value) =>
      value.startsWith(productionPlaceholderPrefix);

  /// `true` seulement quand les trois identifiants de production ont été
  /// réellement renseignés.
  static bool get hasProductionIds =>
      !isProductionPlaceholder(productionAppId) &&
      !isProductionPlaceholder(productionBannerAdUnitId) &&
      !isProductionPlaceholder(productionInterstitialAdUnitId);

  // ==========================================================
  // Accesseurs neutres — SEULS points d'entrée pour les loaders
  // ==========================================================

  /// App ID effectif. Miroir exact de la valeur injectée dans le manifest
  /// par Gradle pour le même environnement.
  static String get appId => isProduction ? productionAppId : testAppId;

  /// Ad Unit ID de bannière effectif.
  ///
  /// iOS : l'application n'est distribuée que sur Android (aucun
  /// `GADApplicationIdentifier` dans `ios/Runner/Info.plist`). Les
  /// identifiants iOS de démonstration sont conservés par robustesse en
  /// environnement de test ; aucune unité iOS de production n'existe, et
  /// aucune n'est inventée ici.
  static String get bannerAdUnitId {
    if (isProduction) return productionBannerAdUnitId;
    if (Platform.isIOS) return testIosBannerAdUnitId;
    return testAndroidBannerAdUnitId;
  }

  /// Ad Unit ID d'interstitiel effectif — même règle que [bannerAdUnitId].
  static String get interstitialAdUnitId {
    if (isProduction) return productionInterstitialAdUnitId;
    if (Platform.isIOS) return testIosInterstitialAdUnitId;
    return testAndroidInterstitialAdUnitId;
  }

  // ==========================================================
  // Appareils de test
  // ==========================================================

  /// `--dart-define=ADS_TEST_DEVICE_IDS=<id1>,<id2>`.
  ///
  /// Volontairement **vide par défaut** et jamais renseignée en dur dans le
  /// dépôt : un identifiant d'appareil est personnel, et une valeur
  /// committée ne pourrait de toute façon jamais transformer « tous les
  /// utilisateurs » en appareils de test — seule la liste explicite passée
  /// au build est transmise au SDK.
  ///
  /// Procédure : lancer l'app une fois, relever dans `logcat` la ligne
  /// `setTestDeviceIds(Arrays.asList("..."))` émise par le SDK, puis
  /// reconstruire avec cet identifiant.
  static const String testDeviceIdsDefineName = 'ADS_TEST_DEVICE_IDS';

  static const String _rawTestDeviceIds =
      String.fromEnvironment(testDeviceIdsDefineName, defaultValue: '');

  /// Découpage pur et testable. Les entrées vides sont ignorées : une
  /// chaîne vide donne une liste vide, jamais `['']`.
  static List<String> parseTestDeviceIds(String raw) => raw
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  static List<String> get testDeviceIds => parseTestDeviceIds(_rawTestDeviceIds);

  // ==========================================================
  // Configuration globale des requêtes publicitaires
  // ==========================================================

  /// Plafond de maturité du contenu publicitaire.
  ///
  /// `G` (« general audiences ») est cohérent avec le positionnement de
  /// l'application. **Ce n'est pas une garantie de filtrage** : il s'agit
  /// d'un plafond déclaratif appliqué par Google à partir de la
  /// classification fournie par les annonceurs. Le blocage effectif de
  /// catégories incompatibles se configure dans la console AdMob
  /// (Blocking controls) et se contrôle a posteriori dans l'Ad Review
  /// Center — aucune combinaison ne garantit 0 % d'annonce indésirable.
  static String get maxAdContentRating => MaxAdContentRating.g;

  /// Configuration appliquée **une seule fois**, au point central
  /// d'initialisation du SDK (`AdsSdkInitializer`) — jamais dupliquée dans
  /// les loaders.
  static RequestConfiguration buildRequestConfiguration({
    List<String>? deviceIds,
  }) {
    final ids = deviceIds ?? testDeviceIds;
    return RequestConfiguration(
      maxAdContentRating: maxAdContentRating,
      testDeviceIds: ids.isEmpty ? null : ids,
    );
  }

  // ==========================================================
  // Debug UMP (inchangé depuis le LOT 5.A)
  // ==========================================================

  /// Mettre à `true` localement (jamais commité) pour forcer le
  /// formulaire UMP en géographie EEE pendant un test manuel. `false` par
  /// défaut : le comportement suit la géographie réelle de l'appareil,
  /// comme en production.
  static const bool forceEeaConsentDebug = false;

  static ConsentDebugSettings? get debugSettings {
    if (!forceEeaConsentDebug) return null;
    return ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
    );
  }
}
