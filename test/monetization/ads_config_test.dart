// Tests LOT 5.F — séparation test / production des identifiants AdMob.
//
// Deux natures d'assertions :
// - comportementales (résolution d'environnement, accesseurs neutres,
//   configuration des requêtes) ;
// - structurelles, en lisant les fichiers du dépôt, pour garantir qu'il
//   n'existe qu'UNE source de vérité pour l'App ID : un manifest et un
//   `AdsConfig` sur des environnements différents feraient échouer ce
//   fichier.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:test_1/monetization/ads_config.dart';

/// Lecture minimale d'un fichier `.properties` (clé=valeur, `#` en
/// commentaire).
Map<String, String> _readProperties(String path) {
  final result = <String, String>{};
  for (final rawLine in File(path).readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separator = line.indexOf('=');
    if (separator == -1) continue;
    result[line.substring(0, separator).trim()] =
        line.substring(separator + 1).trim();
  }
  return result;
}

void main() {
  group('AdsConfig — environnement', () {
    test('le défaut compilé est TEST, jamais production', () {
      // Aucun --dart-define n'est passé à `flutter test` : c'est très
      // exactement la situation d'un build local ordinaire.
      expect(AdsConfig.environment, AdsEnvironment.test);
      expect(AdsConfig.isProduction, isFalse);
    });

    test('« production » sélectionne explicitement la production', () {
      expect(
        AdsConfig.resolveEnvironment(AdsConfig.productionEnvName),
        AdsEnvironment.production,
      );
    });

    test('« test » et toute valeur inconnue retombent sur TEST', () {
      expect(
        AdsConfig.resolveEnvironment(AdsConfig.testEnvName),
        AdsEnvironment.test,
      );
      // Une faute de frappe ne doit JAMAIS activer la production.
      for (final raw in ['prod', 'Production', 'PRODUCTION', '', 'release']) {
        expect(
          AdsConfig.resolveEnvironment(raw),
          AdsEnvironment.test,
          reason: '« $raw » ne doit pas activer la production',
        );
      }
    });
  });

  group('AdsConfig — identifiants', () {
    test('les accesseurs neutres renvoient les IDs de test par défaut', () {
      expect(AdsConfig.appId, AdsConfig.testAppId);
      expect(
        AdsConfig.bannerAdUnitId,
        anyOf(
          AdsConfig.testAndroidBannerAdUnitId,
          AdsConfig.testIosBannerAdUnitId,
        ),
      );
      expect(
        AdsConfig.interstitialAdUnitId,
        anyOf(
          AdsConfig.testAndroidInterstitialAdUnitId,
          AdsConfig.testIosInterstitialAdUnitId,
        ),
      );
    });

    test('les identifiants de test sont bien ceux de démonstration Google',
        () {
      for (final id in [
        AdsConfig.testAppId,
        AdsConfig.testAndroidBannerAdUnitId,
        AdsConfig.testIosBannerAdUnitId,
        AdsConfig.testAndroidInterstitialAdUnitId,
        AdsConfig.testIosInterstitialAdUnitId,
      ]) {
        expect(id, startsWith(AdsConfig.googleDemoPublisherPrefix));
      }
    });

    test(
        'aucun identifiant de production inventé : placeholder explicite, '
        'jamais un ID de démonstration', () {
      for (final id in [
        AdsConfig.productionAppId,
        AdsConfig.productionBannerAdUnitId,
        AdsConfig.productionInterstitialAdUnitId,
      ]) {
        // Tant que les vraies valeurs n'existent pas : placeholder reconnaissable.
        // Une fois injectées : n'importe quoi SAUF un ID de démonstration.
        expect(
          AdsConfig.isProductionPlaceholder(id) ||
              !id.startsWith(AdsConfig.googleDemoPublisherPrefix),
          isTrue,
          reason: 'ID de production invalide : $id',
        );
      }
    });

    test('les identifiants de production sont renseignés', () {
      expect(AdsConfig.hasProductionIds, isTrue);
    });

    test(
        'aucun identifiant de TEST ne peut se retrouver dans le chemin '
        'production', () {
      expect(AdsConfig.productionAppId, isNot(AdsConfig.testAppId));
      expect(
        AdsConfig.productionBannerAdUnitId,
        isNot(anyOf(
          AdsConfig.testAndroidBannerAdUnitId,
          AdsConfig.testIosBannerAdUnitId,
        )),
      );
      expect(
        AdsConfig.productionInterstitialAdUnitId,
        isNot(anyOf(
          AdsConfig.testAndroidInterstitialAdUnitId,
          AdsConfig.testIosInterstitialAdUnitId,
        )),
      );
    });

    test('les 3 identifiants de production viennent du MÊME compte AdMob', () {
      // Attrape une erreur de copier-coller entre comptes : l'App ID et les
      // deux unités doivent partager le même identifiant éditeur.
      final publisher = AdsConfig.productionAppId.split('~').first;

      expect(publisher, startsWith('ca-app-pub-'));
      expect(AdsConfig.productionBannerAdUnitId, startsWith('$publisher/'));
      expect(AdsConfig.productionInterstitialAdUnitId,
          startsWith('$publisher/'));
    });

    test('Rewarded : ID de démonstration Google en environnement TEST', () {
      expect(
        AdsConfig.rewardedAdUnitId,
        anyOf(
          AdsConfig.testAndroidRewardedAdUnitId,
          AdsConfig.testIosRewardedAdUnitId,
        ),
      );
      expect(
        AdsConfig.testAndroidRewardedAdUnitId,
        startsWith(AdsConfig.googleDemoPublisherPrefix),
      );
      expect(AdsConfig.isRewardedAdUnitConfigured, isTrue);
    });

    test(
        'Rewarded production : jamais un ID de test, jamais inventé ; tant '
        'que placeholder, suivi à part sans bloquer Banner/Interstitial', () {
      final id = AdsConfig.productionRewardedAdUnitId;

      expect(id, isNot(AdsConfig.testAndroidRewardedAdUnitId));
      expect(id, isNot(AdsConfig.testIosRewardedAdUnitId));
      expect(
        AdsConfig.isProductionPlaceholder(id) ||
            !id.startsWith(AdsConfig.googleDemoPublisherPrefix),
        isTrue,
      );
      // L'absence de l'unité Rewarded ne dégrade pas les IDs déjà raccordés.
      expect(AdsConfig.hasProductionIds, isTrue);
      expect(
        AdsConfig.hasProductionRewardedId,
        !AdsConfig.isProductionPlaceholder(id),
      );
      // Une fois renseignée, elle doit venir du même compte que l'App ID.
      if (AdsConfig.hasProductionRewardedId) {
        final publisher = AdsConfig.productionAppId.split('~').first;
        expect(id, startsWith('$publisher/'));
      }
    });

    test(
        'LOT 5.G.C — valeurs attendues : TEST démo Google, PRODUCTION réelle, '
        'aucun placeholder, Banner/Interstitial inchangés', () {
      final properties = _readProperties('android/ads_ids.properties');

      // A. TEST → IDs de démonstration Google, inchangés.
      expect(AdsConfig.environment, AdsEnvironment.test);
      expect(
        AdsConfig.testAndroidRewardedAdUnitId,
        'ca-app-pub-3940256099942544/5224354917',
      );
      expect(AdsConfig.rewardedAdUnitId, isNot(AdsConfig.productionRewardedAdUnitId));

      // B. PRODUCTION → unité Rewarded réelle, identique dans les deux sources.
      const expectedRewarded = 'ca-app-pub-2998944710358464/7965966915';
      expect(AdsConfig.productionRewardedAdUnitId, expectedRewarded);
      expect(properties['production.rewardedAdUnitId'], expectedRewarded);

      // C. Plus aucun placeholder dans le chemin production.
      expect(AdsConfig.hasProductionRewardedId, isTrue);
      for (final entry in properties.entries) {
        if (entry.key.startsWith('production.')) {
          expect(
            AdsConfig.isProductionPlaceholder(entry.value),
            isFalse,
            reason: entry.key,
          );
        }
      }

      // D/E. Banner et Interstitial inchangés (test et production).
      expect(
        AdsConfig.productionBannerAdUnitId,
        'ca-app-pub-2998944710358464/4992782235',
      );
      expect(
        AdsConfig.productionInterstitialAdUnitId,
        'ca-app-pub-2998944710358464/7219490327',
      );
      expect(
        AdsConfig.testAndroidBannerAdUnitId,
        'ca-app-pub-3940256099942544/6300978111',
      );
      expect(
        AdsConfig.testAndroidInterstitialAdUnitId,
        'ca-app-pub-3940256099942544/1033173712',
      );
      expect(AdsConfig.productionAppId, 'ca-app-pub-2998944710358464~3134659675');
    });

    test('Banner et Interstitial sont deux unités distinctes', () {
      expect(
        AdsConfig.productionBannerAdUnitId,
        isNot(AdsConfig.productionInterstitialAdUnitId),
      );
    });

    test('formes attendues : « ~ » pour un App ID, « / » pour une unité', () {
      expect(AdsConfig.testAppId, contains('~'));
      expect(AdsConfig.testAndroidBannerAdUnitId, contains('/'));
      expect(AdsConfig.testAndroidInterstitialAdUnitId, contains('/'));
    });

    test('une seule unité Banner est prévue pour les 3 surfaces', () {
      // La distinction des surfaces est portée par `AdSurface`, jamais par
      // des unités distinctes (décision produit LOT 5.F).
      final properties = _readProperties('android/ads_ids.properties');
      final bannerKeys =
          properties.keys.where((k) => k.contains('banner')).toList();
      expect(bannerKeys.length, 2); // test.* et production.*
    });
  });

  group('AdsConfig — source unique de vérité (Dart ↔ Gradle ↔ Manifest)', () {
    final properties = _readProperties('android/ads_ids.properties');

    test('android/ads_ids.properties reflète exactement AdsConfig', () {
      expect(properties['test.appId'], AdsConfig.testAppId);
      expect(
        properties['test.bannerAdUnitId'],
        AdsConfig.testAndroidBannerAdUnitId,
      );
      expect(
        properties['test.interstitialAdUnitId'],
        AdsConfig.testAndroidInterstitialAdUnitId,
      );
      expect(properties['production.appId'], AdsConfig.productionAppId);
      expect(
        properties['production.bannerAdUnitId'],
        AdsConfig.productionBannerAdUnitId,
      );
      expect(
        properties['production.interstitialAdUnitId'],
        AdsConfig.productionInterstitialAdUnitId,
      );
      expect(
        properties['test.rewardedAdUnitId'],
        AdsConfig.testAndroidRewardedAdUnitId,
      );
      expect(
        properties['production.rewardedAdUnitId'],
        AdsConfig.productionRewardedAdUnitId,
      );
    });

    test('AndroidManifest n\'embarque plus aucun App ID en dur', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(manifest, contains(r'android:value="${admobAppId}"'));
      expect(
        manifest.contains('ca-app-pub-'),
        isFalse,
        reason: 'L\'App ID doit venir de Gradle, jamais du manifest',
      );
    });

    test('Gradle lit bien le même fichier et alimente le placeholder', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('ads_ids.properties'));
      expect(gradle, contains('manifestPlaceholders["admobAppId"]'));
      // Fail-fast : un build production avec placeholder doit échouer.
      expect(gradle, contains('PLACEHOLDER_PRODUCTION_'));
      // Défaut test, même quand gradle est appelé sans dart-defines.
      expect(gradle, contains('dart-defines'));
    });
  });

  group('AdsConfig — configuration globale des requêtes', () {
    test('maxAdContentRating vaut G', () {
      expect(AdsConfig.maxAdContentRating, MaxAdContentRating.g);
      expect(AdsConfig.maxAdContentRating, 'G');
      expect(
        AdsConfig.buildRequestConfiguration().maxAdContentRating,
        MaxAdContentRating.g,
      );
    });

    test('aucun appareil de test par défaut', () {
      // Rien n'est codé en dur dans le dépôt : sans --dart-define, aucun
      // appareil n'est déclaré comme appareil de test.
      expect(AdsConfig.testDeviceIds, isEmpty);
      expect(AdsConfig.buildRequestConfiguration().testDeviceIds, isNull);
    });

    test('les identifiants d\'appareils de test sont transmis au SDK', () {
      final configuration = AdsConfig.buildRequestConfiguration(
        deviceIds: const ['DEVICE_A', 'DEVICE_B'],
      );

      expect(configuration.testDeviceIds, ['DEVICE_A', 'DEVICE_B']);
    });

    test('analyse d\'une liste --dart-define : séparateurs et espaces', () {
      expect(AdsConfig.parseTestDeviceIds(''), isEmpty);
      expect(AdsConfig.parseTestDeviceIds('   '), isEmpty);
      expect(AdsConfig.parseTestDeviceIds('A'), ['A']);
      expect(AdsConfig.parseTestDeviceIds(' A , B ,, C '), ['A', 'B', 'C']);
    });

    test('aucun identifiant d\'appareil personnel n\'est committé', () {
      final source = File('lib/monetization/ads_config.dart').readAsStringSync();

      // La seule source possible est le --dart-define ; aucune valeur par
      // défaut autre que la chaîne vide.
      expect(
        source,
        contains(
          "String.fromEnvironment(testDeviceIdsDefineName, defaultValue: '')",
        ),
      );
    });
  });
}
