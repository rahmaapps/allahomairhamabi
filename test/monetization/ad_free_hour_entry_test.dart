// Tests LOT 5.G.B — logique de la ligne « une heure sans publicité »
// (Paramètres, B1/B3/B5/B6). Le rendu de la ligne est couvert par
// test/widgets/ad_free_hour_settings_row_test.dart.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ad_free_hour_entry.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/monetization/reward_service.dart';
import 'package:test_1/monetization/rewarded_wording.dart';
import 'package:test_1/user_prefs.dart';

import 'fakes/fake_reward_service.dart';

class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
}

void main() {
  late _Clock clock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setAdsSuppressedUntil(null);
    await UserPrefs.instance.setShareAsImageUnlockPending(false);
    clock = _Clock(DateTime(2026, 9, 22, 10, 0));
  });

  AdFreeHourEntry build(FakeRewardService service) => AdFreeHourEntry(
        rewardService: service,
        clock: clock.call,
        // Le minuteur réel n'est pas utile ici : `tick()` est appelé
        // explicitement.
        tickInterval: const Duration(days: 1),
      );

  test('1. état normal → invitation (B6)', () async {
    final entry = build(FakeRewardService());
    await entry.refresh();

    expect(entry.state, AdFreeHourEntryState.idle);
    expect(entry.label, RewardedWording.invitation);
    entry.dispose();
  });

  test('2/3. activation → confirmation puis requestReward(adFreeHour)',
      () async {
    final service = FakeRewardService(clock: clock.call);
    final entry = build(service);
    var confirmCount = 0;

    await entry.activate(confirm: () async {
      confirmCount++;
      // Aucun Rewarded avant la confirmation.
      expect(service.requestedKinds, isEmpty);
      return true;
    });

    expect(confirmCount, 1);
    expect(service.requestedKinds, [RewardKind.adFreeHour]);
    entry.dispose();
  });

  test('confirmation refusée → aucun Rewarded', () async {
    final service = FakeRewardService();
    final entry = build(service);

    final result = await entry.activate(confirm: () async => false);

    expect(result, AdFreeHourResult.cancelled);
    expect(service.requestedKinds, isEmpty);
    expect(entry.state, AdFreeHourEntryState.idle);
    entry.dispose();
  });

  for (final outcome in [
    RewardOutcome.dismissedWithoutReward,
    RewardOutcome.failed,
    RewardOutcome.unavailable,
  ]) {
    test('4. récompense non obtenue ($outcome) → état normal', () async {
      final entry = build(FakeRewardService(outcome: outcome));

      final result = await entry.activate(confirm: () async => true);

      expect(result, AdFreeHourResult.notEarned);
      expect(entry.state, AdFreeHourEntryState.idle);
      expect(entry.label, RewardedWording.invitation);
      expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
      entry.dispose();
    });
  }

  test(
      '5. récompense obtenue → adsSuppressedUntil actif, fixé par '
      'l\'infrastructure (jamais par Paramètres)', () async {
    final entry = build(FakeRewardService(clock: clock.call));

    final result = await entry.activate(confirm: () async => true);

    expect(result, AdFreeHourResult.earned);
    expect(entry.state, AdFreeHourEntryState.active);
    expect(
      await UserPrefs.instance.getAdsSuppressedUntil(),
      clock.now.add(const Duration(hours: 1)),
    );
    entry.dispose();
  });

  test('pendant le chargement → libellé « جارٍ تحميل الإعلان… »', () async {
    final service = FakeRewardService(clock: clock.call)
      ..gate = Completer<void>();
    final entry = build(service);

    final future = entry.activate(confirm: () async => true);
    await pumpEventQueue();

    expect(entry.state, AdFreeHourEntryState.loading);
    expect(entry.label, RewardedWording.loading);
    // Une seconde activation pendant le chargement est ignorée.
    expect(
      await entry.activate(confirm: () async => true),
      AdFreeHourResult.cancelled,
    );

    service.gate!.complete();
    await future;
    expect(service.requestedKinds, hasLength(1));
    entry.dispose();
  });

  test('7. heure déjà active → aucun Rewarded, aucune confirmation', () async {
    await UserPrefs.instance
        .setAdsSuppressedUntil(clock.now.add(const Duration(minutes: 20)));
    final service = FakeRewardService();
    final entry = build(service);
    var confirmCount = 0;

    final result = await entry.activate(confirm: () async {
      confirmCount++;
      return true;
    });

    expect(result, AdFreeHourResult.alreadyActive);
    expect(confirmCount, 0);
    expect(service.requestedKinds, isEmpty);
    entry.dispose();
  });

  test('8. heure active → temps restant réel, jamais masquée (B5)', () async {
    await UserPrefs.instance.setAdsSuppressedUntil(
      clock.now.add(const Duration(minutes: 42, seconds: 17)),
    );
    final entry = build(FakeRewardService(offerable: false));
    await entry.refresh();

    expect(entry.state, AdFreeHourEntryState.active);
    expect(entry.label, 'لا إعلانات لمدة ساعة — متبقٍ 42:17');

    clock.now = clock.now.add(const Duration(seconds: 18));
    entry.tick();
    expect(entry.label, 'لا إعلانات لمدة ساعة — متبقٍ 41:59');
    entry.dispose();
  });

  test('9. expiration → retour automatique à l\'état normal', () async {
    await UserPrefs.instance
        .setAdsSuppressedUntil(clock.now.add(const Duration(seconds: 3)));
    final entry = build(FakeRewardService());
    await entry.refresh();
    expect(entry.state, AdFreeHourEntryState.active);

    clock.now = clock.now.add(const Duration(seconds: 3));
    entry.tick();
    await pumpEventQueue();

    expect(entry.state, AdFreeHourEntryState.idle);
    expect(entry.label, RewardedWording.invitation);
    entry.dispose();
  });

  test(
      'Rewarded indisponible → invitation affichée, aucune sollicitation '
      'automatique du service Rewarded', () async {
    final service = FakeRewardService(offerable: false);
    final entry = build(service);
    await entry.refresh();

    expect(entry.state, AdFreeHourEntryState.idle);
    expect(entry.label, RewardedWording.invitation);
    expect(service.requestedKinds, isEmpty);
    expect(service.canOfferCallCount, 0);
    entry.dispose();
  });

  test(
      'Rewarded indisponible au tap → retour à l\'invitation, sans crash ni '
      'récompense', () async {
    final service = FakeRewardService(
      offerable: false,
      outcome: RewardOutcome.unavailable,
    );
    final entry = build(service);

    final result = await entry.activate(confirm: () async => true);

    expect(result, AdFreeHourResult.notEarned);
    expect(entry.state, AdFreeHourEntryState.idle);
    expect(entry.label, RewardedWording.invitation);
    expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNull);
    entry.dispose();
  });

  test('format mm:ss, borné', () {
    expect(
      AdFreeHourEntry.formatRemaining(const Duration(minutes: 42, seconds: 17)),
      '42:17',
    );
    expect(AdFreeHourEntry.formatRemaining(const Duration(seconds: 5)), '00:05');
    expect(AdFreeHourEntry.formatRemaining(const Duration(hours: 1)), '60:00');
    expect(AdFreeHourEntry.formatRemaining(const Duration(seconds: -3)), '00:00');
  });
}
