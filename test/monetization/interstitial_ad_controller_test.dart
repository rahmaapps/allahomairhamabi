import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ads_availability.dart';
import 'package:test_1/monetization/interstitial_ad_controller.dart';
import 'package:test_1/monetization/interstitial_trigger.dart';
import 'package:test_1/user_prefs.dart';

import 'fakes/fake_consent_service.dart';
import 'fakes/fake_interstitial_ad_loader.dart';

const _trigger = InterstitialTrigger.leavingSearch;

({
  InterstitialAdController controller,
  FakeInterstitialAdLoader loader,
  FakeConsentService consent,
}) _build({bool canRequestAds = true}) {
  final consent = FakeConsentService()..canRequestAdsValue = canRequestAds;
  final availability = AdsAvailability(consent)..markSdkInitialized();
  final loader = FakeInterstitialAdLoader();
  return (
    controller: InterstitialAdController(
      adsAvailability: availability,
      loader: loader,
    ),
    loader: loader,
    consent: consent,
  );
}

/// Amène le controller à l'état `ready` : la première transition éligible
/// ne fait que précharger (jamais d'affichage), c'est la seconde qui peut
/// présenter une annonce.
Future<void> _primeReady(InterstitialAdController controller) async {
  await controller.maybeShowOnTransition(_trigger);
  await pumpEventQueue();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // `UserPrefs.instance` est un singleton dont le cache interne survit
    // entre les tests d'un même fichier : les deux clés monétisation sont
    // explicitement remises à zéro.
    await UserPrefs.instance.setAdsSuppressedUntil(null);
    await UserPrefs.instance.setLastInterstitialShownAt(null);
  });

  group('InterstitialAdController — policy', () {
    test(
        'canRequestAds faux : aucune requête, aucun affichage, état inchangé',
        () async {
      final f = _build(canRequestAds: false);

      await f.controller.maybeShowOnTransition(_trigger);
      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.loadCallCount, 0);
      expect(f.controller.state, InterstitialAdState.idle);
    });

    test('adsSuppressedUntil actif : aucune requête, aucun affichage',
        () async {
      await UserPrefs.instance.setAdsSuppressedUntil(
        DateTime.now().add(const Duration(minutes: 30)),
      );
      final f = _build();

      await f.controller.maybeShowOnTransition(_trigger);
      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.loadCallCount, 0);
      expect(f.controller.state, InterstitialAdState.idle);
    });

    test('cooldown non écoulé : aucune requête, aucun affichage', () async {
      await UserPrefs.instance.setLastInterstitialShownAt(
        DateTime.now().subtract(const Duration(minutes: 3)),
      );
      final f = _build();

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.loadCallCount, 0);
      expect(f.controller.state, InterstitialAdState.idle);
    });

    test(
        'policy revalidée AU MOMENT du show : une annonce déjà prête n\'est '
        'pas présentée si le consentement a été retiré entre-temps',
        () async {
      final f = _build();
      await _primeReady(f.controller);
      expect(f.controller.state, InterstitialAdState.ready);

      // Le consentement change APRÈS le chargement.
      f.consent.canRequestAdsValue = false;

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.issuedAds.single.showCallCount, 0);
      expect(f.controller.state, InterstitialAdState.ready);
      expect(await UserPrefs.instance.getLastInterstitialShownAt(), isNull);
    });

    test(
        'policy revalidée au show : une annonce prête n\'est pas présentée '
        'si une fenêtre sans publicité a démarré entre-temps', () async {
      final f = _build();
      await _primeReady(f.controller);

      await UserPrefs.instance.setAdsSuppressedUntil(
        DateTime.now().add(const Duration(minutes: 30)),
      );

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.issuedAds.single.showCallCount, 0);
      expect(await UserPrefs.instance.getLastInterstitialShownAt(), isNull);
    });
  });

  group('InterstitialAdController — cycle de présentation', () {
    test(
        'la première transition éligible précharge sans rien afficher ; '
        'seule une annonce prête est présentée', () async {
      final f = _build();

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.loadCallCount, 1);
      expect(f.controller.state, InterstitialAdState.ready);
      expect(f.loader.issuedAds.single.showCallCount, 0,
          reason: 'aucune présentation tant qu\'aucune annonce n\'était '
              'prête au moment de la transition');

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.issuedAds.single.showCallCount, 1);
      expect(f.controller.state, InterstitialAdState.showing);
    });

    test('aucun double affichage sur deux transitions rapprochées '
        '(appels concurrents)', () async {
      final f = _build();
      await _primeReady(f.controller);

      // Deux appels concurrents, sans await entre les deux.
      final first = f.controller.maybeShowOnTransition(_trigger);
      final second = f.controller.maybeShowOnTransition(_trigger);
      await Future.wait([first, second]);
      await pumpEventQueue();

      expect(f.loader.issuedAds.single.showCallCount, 1);
    });

    test('aucun double affichage pendant qu\'une annonce est déjà à l\'écran',
        () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();
      expect(f.controller.state, InterstitialAdState.showing);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.issuedAds.single.showCallCount, 1);
      expect(f.loader.loadCallCount, 1);
    });
  });

  group('InterstitialAdController — cooldown', () {
    test(
        'le cooldown est enregistré UNIQUEMENT après présentation effective',
        () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      // `show()` appelé, mais la présentation n'a pas encore eu lieu.
      expect(await UserPrefs.instance.getLastInterstitialShownAt(), isNull);

      f.loader.issuedAds.single.simulateShowed();
      await pumpEventQueue();

      expect(await UserPrefs.instance.getLastInterstitialShownAt(), isNotNull);
    });

    test('un échec de chargement ne consomme pas le cooldown', () async {
      final f = _build();
      f.loader.succeedNextLoad = false;

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(f.loader.loadCallCount, 1);
      expect(f.controller.state, InterstitialAdState.idle);
      expect(await UserPrefs.instance.getLastInterstitialShownAt(), isNull);
    });

    test('un échec de présentation ne consomme pas le cooldown', () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      f.loader.issuedAds.first.simulateFailedToShow();
      await pumpEventQueue();

      expect(await UserPrefs.instance.getLastInterstitialShownAt(), isNull);
    });

    test('cooldown persisté : relu depuis UserPrefs après « redémarrage »',
        () async {
      final shownAt = DateTime(2026, 5, 1, 12, 0);
      await UserPrefs.instance.setLastInterstitialShownAt(shownAt);

      expect(
        await UserPrefs.instance.getLastInterstitialShownAt(),
        shownAt,
      );
    });
  });

  group('InterstitialAdController — libération et rechargement', () {
    test('annonce libérée après fermeture (dismissed) et suivante '
        'préchargée', () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      final shownAd = f.loader.issuedAds.first;
      shownAd.simulateShowed();
      shownAd.simulateDismissed();
      await pumpEventQueue();

      expect(shownAd.disposeCallCount, 1);
      // Rechargement de la suivante en arrière-plan (une seule tentative).
      expect(f.loader.loadCallCount, 2);
      expect(f.controller.state, InterstitialAdState.ready);
    });

    test('annonce libérée après échec de présentation (failed-to-show)',
        () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      final shownAd = f.loader.issuedAds.first;
      shownAd.simulateFailedToShow();
      await pumpEventQueue();

      expect(shownAd.disposeCallCount, 1);
      expect(f.controller.state, InterstitialAdState.ready);
    });

    test(
        'aucune boucle de retry : un échec de rechargement laisse le '
        'controller au repos, sans nouvelle tentative spontanée', () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      f.loader.succeedNextLoad = false;
      final shownAd = f.loader.issuedAds.first;
      shownAd.simulateShowed();
      shownAd.simulateDismissed();
      await pumpEventQueue();

      final loadsAfterDismiss = f.loader.loadCallCount;
      await pumpEventQueue();

      expect(f.controller.state, InterstitialAdState.idle);
      expect(f.loader.loadCallCount, loadsAfterDismiss,
          reason: 'aucun rechargement automatique supplémentaire après un '
              'échec — la prochaine tentative doit venir d\'une future '
              'transition utilisateur');
    });

    test('une annonce n\'est jamais présentée deux fois (usage unique)',
        () async {
      final f = _build();
      await _primeReady(f.controller);

      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      final firstAd = f.loader.issuedAds.first;
      firstAd.simulateShowed();
      firstAd.simulateDismissed();
      await pumpEventQueue();

      // Cooldown actif : la transition suivante ne présente rien, et
      // surtout pas la même annonce.
      await f.controller.maybeShowOnTransition(_trigger);
      await pumpEventQueue();

      expect(firstAd.showCallCount, 1);
    });
  });
}
