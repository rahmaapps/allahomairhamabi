import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ad_surface.dart';
import 'package:test_1/monetization/ads_availability.dart';
import 'package:test_1/monetization/banner_ad_slot_controller.dart';
import 'package:test_1/user_prefs.dart';

import 'fakes/fake_banner_ad_loader.dart';
import 'fakes/fake_consent_service.dart';

BannerAdSlotController _buildController({
  AdSurface surface = AdSurface.home,
  required FakeConsentService consent,
  required FakeBannerAdLoader loader,
  bool sdkInitialized = true,
}) {
  final availability = AdsAvailability(consent);
  if (sdkInitialized) availability.markSdkInitialized();
  return BannerAdSlotController(
    surface: surface,
    adsAvailability: availability,
    loader: loader,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // `UserPrefs.instance` est un singleton dont le cache interne
    // (`_sp`) survit entre les tests d'un même fichier — un
    // `setAdsSuppressedUntil` laissé par un test précédent doit être
    // explicitement effacé, `setMockInitialValues` seul ne le fait pas.
    await UserPrefs.instance.setAdsSuppressedUntil(null);
  });

  group('BannerAdSlotController — policy (réutilise AdsPolicy LOT 5.A)', () {
    test('surface non éligible → refused, aucun appel au loader', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(
        surface: AdSurface.duaRead,
        consent: consent,
        loader: loader,
      );

      await controller.requestLoad(width: 400);

      expect(controller.state, BannerAdSlotState.refused);
      expect(loader.loadCallCount, 0);
    });

    test('canRequestAds() faux (consentement non exploitable) → refused, '
        'aucun appel au loader', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = false;
      final controller = _buildController(consent: consent, loader: loader);

      await controller.requestLoad(width: 400);

      expect(controller.state, BannerAdSlotState.refused);
      expect(loader.loadCallCount, 0);
    });

    test('adsSuppressedUntil actif → refused, aucun appel au loader',
        () async {
      await UserPrefs.instance.setAdsSuppressedUntil(
        DateTime.now().add(const Duration(minutes: 30)),
      );
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      await controller.requestLoad(width: 400);

      expect(controller.state, BannerAdSlotState.refused);
      expect(loader.loadCallCount, 0);
    });
  });

  group('BannerAdSlotController — cycle de chargement', () {
    test('passe par loading avant résolution du loader', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      // Laisse les micro-tâches de policy (async) s'exécuter jusqu'à
      // l'appel effectif du loader, sans attendre sa résolution.
      await pumpEventQueue();

      expect(controller.state, BannerAdSlotState.loading);
      expect(loader.loadCallCount, 1);

      loader.completeWithSuccess();
      await future;
    });

    test('succès → loaded, loadedAd exposé', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      await pumpEventQueue();
      final ad = loader.completeWithSuccess(height: 90);
      await future;

      expect(controller.state, BannerAdSlotState.loaded);
      expect(controller.loadedAd, ad);
      expect(controller.loadedAd!.height, 90);
    });

    test('échec → failed, loadedAd reste null (aucun espace résiduel)',
        () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      await pumpEventQueue();
      loader.completeWithFailure();
      await future;

      expect(controller.state, BannerAdSlotState.failed);
      expect(controller.loadedAd, isNull);
    });

    test('une seule instance par controller : un second requestLoad() est '
        'un no-op (aucun second appel au loader)', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      await pumpEventQueue();
      loader.completeWithSuccess();
      await future;

      await controller.requestLoad(width: 500);

      expect(loader.loadCallCount, 1);
    });
  });

  group('BannerAdSlotController — dispose et late callbacks', () {
    test('dispose() libère l\'annonce chargée exactement une fois',
        () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      await pumpEventQueue();
      final ad = loader.completeWithSuccess();
      await future;

      controller.dispose();

      expect(ad.disposeCallCount, 1);
    });

    test(
        'late callback après dispose : une annonce résolue APRÈS dispose() '
        'est immédiatement libérée, jamais assignée à loadedAd', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      await pumpEventQueue();

      controller.dispose();
      final lateAd = loader.completeWithSuccess();
      await future;

      expect(lateAd.disposeCallCount, 1);
      expect(controller.loadedAd, isNull);
    });

    test('dispose() avant toute résolution n\'appelle jamais notifyListeners '
        'après coup (pas d\'exception ChangeNotifier)', () async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final controller = _buildController(consent: consent, loader: loader);

      final future = controller.requestLoad(width: 400);
      await pumpEventQueue();

      controller.dispose();
      loader.completeWithFailure();

      // Ne doit lever aucune exception (notifyListeners post-dispose).
      await future;
    });
  });
}
