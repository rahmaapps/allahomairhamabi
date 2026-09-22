// Tests LOT 5.G.B — porte Rewarded du Partage comme image (B2/B3/B4).
//
// Le rendu PNG et l'invocation du système de partage sont injectés : chaque
// test observe EXACTEMENT à quel moment l'autorisation one-shot est
// consommée.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ads_availability.dart';
import 'package:test_1/monetization/reward_effects.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/monetization/reward_service.dart';
import 'package:test_1/monetization/rewarded_ad_controller.dart';
import 'package:test_1/monetization/share_as_image_flow.dart';
import 'package:test_1/user_prefs.dart';

import 'fakes/fake_consent_service.dart';
import 'fakes/fake_reward_service.dart';
import 'fakes/fake_rewarded_ad_loader.dart';

final _png = Uint8List.fromList([1, 2, 3]);

/// Journal d'un passage dans le flux.
class _Probe {
  int confirmCount = 0;
  int renderCount = 0;
  int shareCount = 0;
  int earnedToastCount = 0;
  final List<ShareAsImagePhase> phases = [];

  /// État de l'autorisation observé AU MOMENT où le système de partage est
  /// invoqué.
  bool? grantPresentAtShare;
  bool? grantPresentAtRender;
}

Future<ShareAsImageResult> _run(
  ShareAsImageFlow flow,
  _Probe probe, {
  bool confirmed = true,
  Future<Uint8List?> Function()? render,
  bool shareThrows = false,
}) {
  return flow.run(
    confirm: () async {
      probe.confirmCount++;
      return confirmed;
    },
    render: () async {
      probe.renderCount++;
      probe.grantPresentAtRender = await RewardEffects.hasShareAsImageUnlock();
      if (render != null) return render();
      return _png;
    },
    share: (png) async {
      probe.shareCount++;
      probe.grantPresentAtShare = await RewardEffects.hasShareAsImageUnlock();
      if (shareThrows) throw Exception('share indisponible');
    },
    onRewardEarned: () => probe.earnedToastCount++,
    onPhase: probe.phases.add,
  );
}

ShareAsImageFlow _flow(RewardService service, {bool adFree = false}) =>
    ShareAsImageFlow(rewardService: service, isAdFreeActive: () async => adFree);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setAdsSuppressedUntil(null);
    await UserPrefs.instance.setShareAsImageUnlockPending(false);
  });

  group('Partage TEXTE — toujours gratuit (test 10)', () {
    test('le partage texte de HOME ne passe par aucune porte Rewarded', () {
      final source = File('lib/home_screen.dart').readAsStringSync();
      final start = source.indexOf('void _shareDuaText()');
      final end = source.indexOf('Share.share(', start);
      expect(start, isNonNegative);
      final body = source.substring(start, end + 200);

      for (final token in const [
        'ShareAsImageFlow',
        '_shareAsImageFlow',
        'Reward',
        'showRewardedConfirmation',
      ]) {
        expect(body.contains(token), isFalse, reason: token);
      }
    });

    test('le partage texte de DuaRead ne passe par aucune porte Rewarded', () {
      final source =
          File('lib/screens/dua_read_screen.dart').readAsStringSync();
      expect(source, contains('Share.share('));
      expect(source.contains('Reward'), isFalse);
      expect(source.contains('ShareAsImageFlow'), isFalse);
    });
  });

  group('B3 — heure sans publicité active (test 11)', () {
    test('image gratuite, aucun Rewarded, aucune autorisation consommée',
        () async {
      await RewardEffects.grantShareAsImageUnlock();
      final service = FakeRewardService();
      final probe = _Probe();

      final result = await _run(_flow(service, adFree: true), probe);

      expect(result, ShareAsImageResult.shared);
      expect(probe.confirmCount, 0);
      expect(service.requestedKinds, isEmpty);
      expect(service.canOfferCallCount, 0);
      // L'autorisation déjà gagnée est conservée pour plus tard.
      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);
    });
  });

  group('B2 — Rewarded indisponible ou en échec : image gratuite', () {
    test('12. indisponible → aucune confirmation, partage immédiat', () async {
      final service = FakeRewardService(offerable: false);
      final probe = _Probe();

      final result = await _run(_flow(service), probe);

      expect(result, ShareAsImageResult.shared);
      expect(probe.confirmCount, 0);
      expect(service.requestedKinds, isEmpty);
      expect(probe.phases, [ShareAsImagePhase.preparingImage]);
    });

    for (final outcome in [RewardOutcome.failed, RewardOutcome.unavailable]) {
      test('13. Rewarded en échec ($outcome) → image gratuite, sans message',
          () async {
        final service = FakeRewardService(outcome: outcome);
        final probe = _Probe();

        final result = await _run(_flow(service), probe);

        expect(result, ShareAsImageResult.shared);
        expect(probe.shareCount, 1);
        expect(probe.earnedToastCount, 0);
        expect(service.requestedKinds, [RewardKind.shareAsImageUnlock]);
      });
    }

    test('aucune tentative répétée automatique', () async {
      final service = FakeRewardService(outcome: RewardOutcome.failed);

      await _run(_flow(service), _Probe());

      expect(service.requestedKinds, hasLength(1));
    });
  });

  group('Rewarded disponible', () {
    test('14. récompense gagnée → image déverrouillée et partagée', () async {
      final service = FakeRewardService();
      final probe = _Probe();

      final result = await _run(_flow(service), probe);

      expect(result, ShareAsImageResult.shared);
      expect(probe.confirmCount, 1);
      expect(probe.earnedToastCount, 1);
      expect(service.requestedKinds, [RewardKind.shareAsImageUnlock]);
      expect(probe.phases, [
        ShareAsImagePhase.loadingAd,
        ShareAsImagePhase.preparingImage,
      ]);
    });

    test('confirmation refusée → aucun Rewarded, aucun partage', () async {
      final service = FakeRewardService();
      final probe = _Probe();

      final result = await _run(_flow(service), probe, confirmed: false);

      expect(result, ShareAsImageResult.cancelled);
      expect(service.requestedKinds, isEmpty);
      expect(probe.renderCount, 0);
      expect(probe.shareCount, 0);
    });

    test('annonce fermée avant la récompense → retour à la feuille', () async {
      final service =
          FakeRewardService(outcome: RewardOutcome.dismissedWithoutReward);
      final probe = _Probe();

      final result = await _run(_flow(service), probe);

      expect(result, ShareAsImageResult.cancelled);
      expect(probe.shareCount, 0);
      expect(probe.earnedToastCount, 0);
    });
  });

  group('B4 — consommation de l\'autorisation one-shot', () {
    test('15. rendu PNG échoué → autorisation conservée', () async {
      final service = FakeRewardService();
      final probe = _Probe();

      final result =
          await _run(_flow(service), probe, render: () async => null);

      expect(result, ShareAsImageResult.renderFailed);
      expect(probe.shareCount, 0);
      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);

      // Tentative suivante : l'autorisation est utilisée, sans nouveau
      // Rewarded.
      final retry = _Probe();
      expect(await _run(_flow(service), retry), ShareAsImageResult.shared);
      expect(service.requestedKinds, hasLength(1));
      expect(retry.confirmCount, 0);
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
    });

    test(
        '16. consommée à l\'invocation du système de partage — pas avant le '
        'rendu', () async {
      final service = FakeRewardService();
      final probe = _Probe();

      await _run(_flow(service), probe);

      expect(probe.grantPresentAtRender, isTrue);
      expect(probe.grantPresentAtShare, isFalse);
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
    });

    test('invocation du partage en échec → autorisation restituée', () async {
      await RewardEffects.grantShareAsImageUnlock();
      final probe = _Probe();

      final result =
          await _run(_flow(FakeRewardService()), probe, shareThrows: true);

      expect(result, ShareAsImageResult.shareFailed);
      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);
    });

    test('17. double consommation impossible', () async {
      await RewardEffects.grantShareAsImageUnlock();
      final service = FakeRewardService(offerable: false);

      await _run(_flow(service), _Probe());
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);

      // Deuxième partage : plus d'autorisation, rien à consommer — et le
      // Rewarded indisponible laisse le partage gratuit (B2).
      expect(await _run(_flow(service), _Probe()), ShareAsImageResult.shared);
      expect(await RewardEffects.consumeShareAsImageUnlock(), isFalse);
    });

    test('deux flux concurrents : un seul s\'exécute', () async {
      final service = FakeRewardService()..gate = Completer<void>();
      final flow = _flow(service);

      final first = _run(flow, _Probe());
      final second = await _run(flow, _Probe());
      service.gate!.complete();

      expect(second, ShareAsImageResult.cancelled);
      expect(await first, ShareAsImageResult.shared);
      expect(service.requestedKinds, hasLength(1));
    });

    test('18. aucune consommation au clic initial', () async {
      await RewardEffects.grantShareAsImageUnlock();
      final renderGate = Completer<Uint8List?>();
      final probe = _Probe();

      final future = _run(
        _flow(FakeRewardService()),
        probe,
        render: () => renderGate.future,
      );
      await pumpEventQueue();

      // Le flux a démarré (clic), le rendu est en cours : rien de consommé.
      expect(probe.renderCount, 1);
      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);

      renderGate.complete(_png);
      await future;
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
    });

    test(
        '19. aucune consommation à onUserEarnedReward directement (vraie '
        'infrastructure 5.G.A, loader simulé)', () async {
      final loader = FakeRewardedAdLoader();
      final availability = AdsAvailability(
        FakeConsentService()..canRequestAdsValue = true,
      )..markSdkInitialized();
      final controller = RewardedAdController(
        adsAvailability: availability,
        loader: loader,
        isAdUnitConfigured: () => true,
      );
      final probe = _Probe();

      final future = _run(_flow(controller), probe);
      await pumpEventQueue();
      final ad = loader.issuedAds.first
        ..simulateShowed()
        ..simulateEarned();
      await pumpEventQueue();

      // Récompense reçue, annonce encore affichée : autorisation PRÉSENTE.
      expect(await RewardEffects.hasShareAsImageUnlock(), isTrue);
      expect(probe.shareCount, 0);

      ad.simulateDismissed();
      expect(await future, ShareAsImageResult.shared);
      expect(probe.grantPresentAtShare, isFalse);
      expect(await RewardEffects.hasShareAsImageUnlock(), isFalse);
    });
  });

  group('Protection (tests 20–22)', () {
    test('20. Rewarded indisponible : jamais bloquant ni en erreur', () async {
      for (final service in [
        FakeRewardService(offerable: false),
        FakeRewardService(outcome: RewardOutcome.failed),
        FakeRewardService(outcome: RewardOutcome.unavailable),
      ]) {
        expect(await _run(_flow(service), _Probe()), ShareAsImageResult.shared);
      }
    });

    const readingScreens = {
      'lib/screens/dua_read_screen.dart': 'DuaRead',
      'lib/screens/grave_visit_read_screen.dart': 'Grave Visit',
      'lib/screens/onboarding_screen.dart': 'Onboarding',
      'lib/main.dart': 'Splash / lancement',
    };
    readingScreens.forEach((path, label) {
      test('21/22. aucun Rewarded dans $label', () {
        final source = File(path).readAsStringSync();
        for (final token in const [
          'Reward',
          'ShareAsImageFlow',
          'AdFreeHour',
          'showRewardedConfirmation',
        ]) {
          expect(source.contains(token), isFalse, reason: '$token dans $path');
        }
      });
    });

    test('le Rewarded n\'est branché que dans Paramètres et la feuille HOME',
        () {
      expect(
        File('lib/settings_screen.dart').readAsStringSync(),
        contains('AdFreeHourSettingsRow(entry: _adFreeHour)'),
      );
      final home = File('lib/home_screen.dart').readAsStringSync();
      // Aucun bouton Rewarded sur HOME : seule la feuille de partage image
      // utilise le flux, jamais la ligne « une heure sans publicité ».
      expect(home.contains('AdFreeHour'), isFalse);
      expect(home, contains('_shareAsImageFlow.run('));
    });
  });
}
