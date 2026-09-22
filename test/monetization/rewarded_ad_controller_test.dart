// Tests LOT 5.G.A — infrastructure Rewarded.
//
// Tout passe par `FakeRewardedAdLoader` : aucun compte AdMob, aucun canal
// natif. Chaque callback Google est simulé explicitement, dans l'ordre
// voulu, pour prouver qu'AUCUNE récompense n'est accordée hors
// `onUserEarnedReward`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ads_availability.dart';
import 'package:test_1/monetization/ads_free_status.dart';
import 'package:test_1/monetization/reward_effects.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/monetization/reward_service.dart';
import 'package:test_1/monetization/rewarded_ad_controller.dart';
import 'package:test_1/user_prefs.dart';

import 'fakes/fake_consent_service.dart';
import 'fakes/fake_rewarded_ad_loader.dart';

/// Horloge pilotable : permet de prouver l'instant exact de démarrage de
/// la fenêtre sans publicité.
class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
}

class _Fixture {
  _Fixture({
    bool canRequestAds = true,
    bool adUnitConfigured = true,
    Duration loadTimeout = RewardedAdController.defaultLoadTimeout,
    Duration readyAdTtl = RewardedAdController.defaultReadyAdTtl,
    bool countEffects = false,
  })  : consent = FakeConsentService()..canRequestAdsValue = canRequestAds,
        loader = FakeRewardedAdLoader(),
        clock = _Clock(DateTime(2026, 9, 22, 10, 0)) {
    final availability = AdsAvailability(consent)..markSdkInitialized();
    controller = RewardedAdController(
      adsAvailability: availability,
      loader: loader,
      isAdUnitConfigured: () => adUnitConfigured,
      clock: clock.call,
      loadTimeout: loadTimeout,
      readyAdTtl: readyAdTtl,
      applyEffect: countEffects
          ? (kind, earnedAt) async {
              effects.add((kind, earnedAt));
              await RewardEffects.apply(kind, earnedAt: earnedAt);
            }
          : null,
    );
  }

  final FakeConsentService consent;
  final FakeRewardedAdLoader loader;
  final _Clock clock;
  late final RewardedAdController controller;
  final List<(RewardKind, DateTime)> effects = [];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // `UserPrefs.instance` garde un cache interne entre les tests d'un même
    // fichier : les clés concernées sont remises à zéro explicitement.
    await UserPrefs.instance.setAdsSuppressedUntil(null);
    await UserPrefs.instance.setShareAsImageUnlockPending(false);
  });

  group('RewardedAdController — conditions préalables (aucune tentative)', () {
    test('1. canRequestAds == false → aucune requête, unavailable', () async {
      final f = _Fixture(canRequestAds: false);

      final outcome =
          await f.controller.requestRewardOutcome(RewardKind.adFreeHour);

      expect(outcome, RewardOutcome.unavailable);
      expect(f.loader.loadCallCount, 0);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
    });

    test('2. unité non configurée (placeholder production) → unavailable',
        () async {
      final f = _Fixture(adUnitConfigured: false);

      final outcome =
          await f.controller.requestRewardOutcome(RewardKind.adFreeHour);

      expect(outcome, RewardOutcome.unavailable);
      expect(f.loader.loadCallCount, 0);
    });

    test('2b. fenêtre sans publicité active → unavailable, aucune requête',
        () async {
      final f = _Fixture();
      await UserPrefs.instance
          .setAdsSuppressedUntil(f.clock.now.add(const Duration(minutes: 30)));

      final outcome = await f.controller
          .requestRewardOutcome(RewardKind.shareAsImageUnlock);

      expect(outcome, RewardOutcome.unavailable);
      expect(f.loader.loadCallCount, 0);
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
    });

    test('décision pure : chaque condition est nécessaire', () {
      final now = DateTime(2026, 9, 22, 10);
      const inactive = AdsFreeStatus(null);
      final active = AdsFreeStatus(now.add(const Duration(minutes: 1)));

      expect(
        RewardedAdController.isAttemptAllowed(
          adUnitConfigured: true,
          canRequestAds: true,
          adsFreeStatus: inactive,
          now: now,
        ),
        isTrue,
      );
      for (final (configured, canRequest, status) in [
        (false, true, inactive),
        (true, false, inactive),
        (true, true, active),
      ]) {
        expect(
          RewardedAdController.isAttemptAllowed(
            adUnitConfigured: configured,
            canRequestAds: canRequest,
            adsFreeStatus: status,
            now: now,
          ),
          isFalse,
        );
      }
    });
  });

  group('RewardedAdController — échecs : aucune récompense', () {
    test('3. échec de chargement → failed, aucune récompense', () async {
      final f = _Fixture(countEffects: true)..loader.succeedNextLoad = false;

      final outcome =
          await f.controller.requestRewardOutcome(RewardKind.adFreeHour);

      expect(outcome, RewardOutcome.failed);
      expect(f.effects, isEmpty);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
    });

    test('3b. exception au chargement → failed, jamais propagée', () async {
      final f = _Fixture(countEffects: true)..loader.throwOnLoad = true;

      final outcome =
          await f.controller.requestRewardOutcome(RewardKind.adFreeHour);

      expect(outcome, RewardOutcome.failed);
      expect(f.effects, isEmpty);
    });

    test('3c. délai de chargement dépassé → failed ; annonce tardive libérée',
        () async {
      final f = _Fixture(
        countEffects: true,
        loadTimeout: const Duration(milliseconds: 20),
      )..loader.manualCompletion = true;

      final outcome =
          await f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      expect(outcome, RewardOutcome.failed);

      // Le SDK finit par répondre, trop tard : l'annonce ne doit ni être
      // conservée, ni présentée, ni fuir.
      final late = f.loader.completePendingLoad();
      await pumpEventQueue();

      expect(late.showCallCount, 0);
      expect(late.disposeCallCount, 1);
      expect(f.effects, isEmpty);
    });

    test('4. échec de présentation → failed, aucune récompense', () async {
      final f = _Fixture(countEffects: true);

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first.simulateFailedToShow();

      expect(await future, RewardOutcome.failed);
      expect(f.effects, isEmpty);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
    });

    test(
        '5/8. fermeture sans onUserEarnedReward → dismissedWithoutReward, '
        'adsSuppressedUntil inchangé', () async {
      final f = _Fixture(countEffects: true);
      final previous = f.clock.now.subtract(const Duration(hours: 3));
      await UserPrefs.instance.setAdsSuppressedUntil(previous);

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      final ad = f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateDismissed();

      expect(await future, RewardOutcome.dismissedWithoutReward);
      expect(ad.disposeCallCount, greaterThanOrEqualTo(1));
      expect(f.effects, isEmpty);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), previous);
    });

    test('requestReward (bool) : false sur toute issue autre que earned',
        () async {
      final f = _Fixture();

      final future = f.controller.requestReward(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateDismissed();

      expect(await future, isFalse);
    });
  });

  group('RewardedAdController — onUserEarnedReward', () {
    test('6. récompense accordée exactement une fois → earned', () async {
      final f = _Fixture(countEffects: true);

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateEarned()
        ..simulateDismissed();

      expect(await future, RewardOutcome.earned);
      expect(f.effects, hasLength(1));
      expect(f.effects.single.$1, RewardKind.adFreeHour);
    });

    test(
        '7. adFreeHour : adsSuppressedUntil = instant du callback + 1h — ni '
        'le chargement, ni le début du show, ni la fermeture', () async {
      final f = _Fixture();
      final requestedAt = f.clock.now;

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      final ad = f.loader.issuedAds.first;

      f.clock.now = requestedAt.add(const Duration(seconds: 2));
      ad.simulateShowed();

      final rewardTime = requestedAt.add(const Duration(seconds: 31));
      f.clock.now = rewardTime;
      ad.simulateEarned();

      f.clock.now = requestedAt.add(const Duration(seconds: 45));
      ad.simulateDismissed();

      expect(await future, RewardOutcome.earned);
      expect(
        await UserPrefs.instance.getAdsSuppressedUntil(),
        rewardTime.add(const Duration(hours: 1)),
      );
    });

    test('9. récompense persistée : relue directement dans le stockage',
        () async {
      final f = _Fixture();

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateEarned()
        ..simulateDismissed();
      await future;

      final raw = (await SharedPreferences.getInstance())
          .getInt('ads_suppressed_until');
      expect(raw, isNotNull);
      expect(
        DateTime.fromMillisecondsSinceEpoch(raw!),
        f.clock.now.add(const Duration(hours: 1)),
      );
      // Jamais un booléen : c'est une date d'expiration.
      expect(
        (await SharedPreferences.getInstance()).get('ads_suppressed_until'),
        isA<int>(),
      );
    });

    test('10. shareAsImageUnlock : autorisation one-shot accordée', () async {
      final f = _Fixture();

      final future = f.controller
          .requestRewardOutcome(RewardKind.shareAsImageUnlock);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateEarned()
        ..simulateDismissed();

      expect(await future, RewardOutcome.earned);
      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);
      // Le Rewarded de partage n'ouvre AUCUNE fenêtre sans publicité.
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);

      expect(await RewardEffects.consumeShareAsImageUnlock(), isTrue);
      expect(await RewardEffects.consumeShareAsImageUnlock(), isFalse);
    });

    test('11. double callback onUserEarnedReward → une seule récompense',
        () async {
      final f = _Fixture(countEffects: true);

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      final ad = f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateEarned();
      f.clock.now = f.clock.now.add(const Duration(seconds: 5));
      ad
        ..simulateEarned()
        ..simulateDismissed();

      expect(await future, RewardOutcome.earned);
      expect(f.effects, hasLength(1));
    });

    test(
        'onUserEarnedReward sans onShowed préalable : récompense toujours '
        'honorée (seul le callback de récompense fait foi)', () async {
      final f = _Fixture(countEffects: true);

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateEarned()
        ..simulateDismissed();

      expect(await future, RewardOutcome.earned);
      expect(f.effects, hasLength(1));
    });
  });

  group('RewardedAdController — concurrence et cycle de vie', () {
    test('12. double show impossible : une seule présentation', () async {
      final f = _Fixture()..loader.manualCompletion = true;

      final first =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      final second = await f.controller
          .requestRewardOutcome(RewardKind.shareAsImageUnlock);

      expect(second, RewardOutcome.unavailable);

      await pumpEventQueue();
      final ad = f.loader.completePendingLoad();
      await pumpEventQueue();
      ad
        ..simulateShowed()
        ..simulateDismissed();
      await first;

      expect(f.loader.loadCallCount, greaterThanOrEqualTo(1));
      expect(ad.showCallCount, 1);
    });

    test(
        '13. callbacks tardifs après fin du cycle / dispose : aucun effet '
        'indésirable', () async {
      final f = _Fixture(countEffects: true);

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      final ad = f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateDismissed();
      expect(await future, RewardOutcome.dismissedWithoutReward);

      // Rafale de callbacks arrivant après la fermeture.
      ad
        ..simulateEarned()
        ..simulateShowed()
        ..simulateDismissed()
        ..simulateFailedToShow();
      await pumpEventQueue();

      expect(f.effects, isEmpty);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
      expect(f.controller.isShowing, isFalse);
    });

    test('une nouvelle demande est possible après la précédente', () async {
      final f = _Fixture();

      final first =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateDismissed();
      await first;
      await pumpEventQueue();

      final second = f.controller
          .requestRewardOutcome(RewardKind.shareAsImageUnlock);
      await pumpEventQueue();
      f.loader.issuedAds.last
        ..simulateShowed()
        ..simulateEarned()
        ..simulateDismissed();

      expect(await second, RewardOutcome.earned);
    });

    test(
        'préchargement suivant après la fin du Rewarded, puis réutilisé '
        'sans nouveau chargement', () async {
      final f = _Fixture();

      final first =
          f.controller.requestRewardOutcome(RewardKind.shareAsImageUnlock);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateDismissed();
      await first;
      await pumpEventQueue();

      expect(f.loader.loadCallCount, 2);
      expect(f.controller.state, RewardedAdState.ready);

      final second = f.controller
          .requestRewardOutcome(RewardKind.shareAsImageUnlock);
      await pumpEventQueue();
      expect(f.loader.loadCallCount, 2); // annonce préchargée réutilisée

      f.loader.issuedAds[1]
        ..simulateShowed()
        ..simulateDismissed();
      await second;
    });

    test('aucun préchargement pendant une fenêtre sans publicité', () async {
      final f = _Fixture();

      final future =
          f.controller.requestRewardOutcome(RewardKind.adFreeHour);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateEarned()
        ..simulateDismissed();
      await future;
      await pumpEventQueue();

      // L'heure sans publicité vient de commencer : rien n'est préchargé.
      expect(f.loader.loadCallCount, 1);
      expect(f.controller.state, RewardedAdState.idle);
    });

    test('annonce préchargée expirée : libérée et remplacée', () async {
      final f = _Fixture(readyAdTtl: const Duration(minutes: 55));

      final first =
          f.controller.requestRewardOutcome(RewardKind.shareAsImageUnlock);
      await pumpEventQueue();
      f.loader.issuedAds.first
        ..simulateShowed()
        ..simulateDismissed();
      await first;
      await pumpEventQueue();
      final stale = f.loader.issuedAds[1];

      f.clock.now = f.clock.now.add(const Duration(minutes: 56));
      final second = f.controller
          .requestRewardOutcome(RewardKind.shareAsImageUnlock);
      await pumpEventQueue();

      expect(stale.disposeCallCount, 1);
      expect(stale.showCallCount, 0);
      expect(f.loader.loadCallCount, 3);

      f.loader.issuedAds.last
        ..simulateShowed()
        ..simulateDismissed();
      await second;
    });
  });

  group('RewardedAdController — testabilité et périmètre', () {
    test('14. pilotable entièrement par un fake, implémente RewardService',
        () {
      final f = _Fixture();
      expect(f.controller, isA<RewardService>());
      expect(f.controller.state, RewardedAdState.idle);
    });

    test(
        'aucun écran n\'appelle directement le Rewarded (LOT 5.G.B : '
        'uniquement via AdFreeHourEntry / ShareAsImageFlow ; jamais dans '
        'DuaRead ni Grave Visit ; aucun Rewarded automatique)', () {
      const screens = [
        'lib/home_screen.dart',
        'lib/search_screen.dart',
        'lib/favorites_screen.dart',
        'lib/settings_screen.dart',
        'lib/main.dart',
        'lib/screens/dua_read_screen.dart',
        'lib/screens/grave_visit_read_screen.dart',
        'lib/screens/onboarding_screen.dart',
        'lib/screens/person_selection_screen.dart',
      ];
      for (final path in screens) {
        final source = File(path).readAsStringSync();
        for (final token in const [
          'RewardedAdController',
          'RewardService',
          'requestReward',
          'RewardKind',
          'RewardedAd',
        ]) {
          expect(source.contains(token), isFalse, reason: '$token dans $path');
        }
      }
    });
  });
}
