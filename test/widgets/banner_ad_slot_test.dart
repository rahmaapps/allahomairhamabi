import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ad_surface.dart';
import 'package:test_1/monetization/ads_availability.dart';
import 'package:test_1/user_prefs.dart';
import 'package:test_1/widgets/banner_ad_slot.dart';

import '../monetization/fakes/fake_banner_ad_loader.dart';
import '../monetization/fakes/fake_consent_service.dart';

Widget _wrap(Widget bottomNavigationBar) {
  return MaterialApp(
    home: Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: bottomNavigationBar,
    ),
  );
}

Size _sizeOfSlot(WidgetTester tester) =>
    tester.getSize(find.byType(BannerAdSlot));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // `UserPrefs.instance` est un singleton dont le cache interne survit
    // entre les tests d'un même fichier (voir même correctif dans
    // banner_ad_slot_controller_test.dart).
    await UserPrefs.instance.setAdsSuppressedUntil(null);
  });

  group('BannerAdSlot — hauteur (§ audit LOT 5.B : jamais de retard/gap)',
      () {
    testWidgets('premier build : hauteur nulle, contenu principal déjà '
        'affiché', (tester) async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent)..markSdkInitialized();

      await tester.pumpWidget(_wrap(BannerAdSlot(
        surface: AdSurface.home,
        adsAvailability: availability,
        loader: loader,
      )));

      // Avant même que le loader n'ait été sollicité (aucun `pump`
      // supplémentaire) : le slot doit déjà occuper une hauteur nulle.
      expect(_sizeOfSlot(tester).height, 0);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('après succès de chargement : hauteur = celle de l\'annonce',
        (tester) async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent)..markSdkInitialized();

      await tester.pumpWidget(_wrap(BannerAdSlot(
        surface: AdSurface.home,
        adsAvailability: availability,
        loader: loader,
      )));
      // Exécute le postFrameCallback → requestLoad() → chaîne async policy
      // (canRequestAds/adsSuppressedUntil) jusqu'à l'appel effectif du
      // loader, sans attendre sa résolution.
      await tester.pumpAndSettle();

      loader.completeWithSuccess(height: 60);
      await tester.pumpAndSettle(); // notifyListeners → rebuild

      expect(find.byKey(const Key('fake-banner-ad')), findsOneWidget);
      expect(_sizeOfSlot(tester).height, 60);
    });

    testWidgets(
        'après échec de chargement : retour à hauteur nulle, aucun espace '
        'résiduel', (tester) async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent)..markSdkInitialized();

      await tester.pumpWidget(_wrap(BannerAdSlot(
        surface: AdSurface.home,
        adsAvailability: availability,
        loader: loader,
      )));
      await tester.pumpAndSettle();

      loader.completeWithFailure();
      await tester.pumpAndSettle();

      expect(_sizeOfSlot(tester).height, 0);
      expect(find.byKey(const Key('fake-banner-ad')), findsNothing);
    });

    testWidgets(
        'canRequestAds() faux : aucune requête, hauteur nulle en permanence',
        (tester) async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = false;
      final availability = AdsAvailability(consent)..markSdkInitialized();

      await tester.pumpWidget(_wrap(BannerAdSlot(
        surface: AdSurface.home,
        adsAvailability: availability,
        loader: loader,
      )));
      await tester.pumpAndSettle();

      expect(loader.loadCallCount, 0);
      expect(_sizeOfSlot(tester).height, 0);
    });
  });

  group('BannerAdSlot — navigation répétée (Recherche/Favoris)', () {
    testWidgets(
        'aucune accumulation d\'instances : chaque ouverture charge une '
        'annonce et chaque fermeture la libère (dispose systématique)',
        (tester) async {
      final loader = FakeBannerAdLoader();
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent)..markSdkInitialized();
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ));

      for (var i = 0; i < 3; i++) {
        navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (_) => Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: BannerAdSlot(
              surface: AdSurface.search,
              adsAvailability: availability,
              loader: loader,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(loader.loadCallCount, i + 1,
            reason: 'chaque ouverture doit déclencher exactement un '
                'nouveau chargement (pas de réutilisation d\'état)');

        loader.completeWithSuccess();
        await tester.pumpAndSettle();

        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      }

      expect(loader.issuedAds.length, 3);
      for (final ad in loader.issuedAds) {
        expect(ad.disposeCallCount, 1,
            reason: 'aucune fuite : chaque annonce doit être libérée '
                'exactement une fois au retour arrière');
      }
    });
  });
}
