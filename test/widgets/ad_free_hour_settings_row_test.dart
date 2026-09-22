// Tests widget LOT 5.G.B — ligne « une heure sans publicité » des Paramètres.
//
// `SettingsScreen` lui-même n'est pas testable en widget (`_bootstrap()`
// attend un canal de plateforme natif — limitation documentée dans
// test/settings_screen_lot3g_test.dart) : la ligne est donc testée seule,
// avec la VRAIE feuille de confirmation et le vrai toast du Design System.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/monetization/ad_free_hour_entry.dart';
import 'package:test_1/monetization/reward_kind.dart';
import 'package:test_1/monetization/reward_service.dart';
import 'package:test_1/monetization/rewarded_wording.dart';
import 'package:test_1/settings_screen.dart';
import 'package:test_1/theme/app_theme.dart';
import 'package:test_1/user_prefs.dart';

import '../monetization/fakes/fake_reward_service.dart';

Future<void> _pumpRow(WidgetTester tester, AdFreeHourEntry entry) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: AdFreeHourSettingsRow(entry: entry)),
    ),
  );
  await entry.refresh();
  await tester.pump();
}

/// Retire la ligne (et son écouteur) avant de libérer le contrôleur et son
/// minuteur d'affichage.
Future<void> _tearDown(WidgetTester tester, AdFreeHourEntry entry) async {
  await tester.pumpWidget(const SizedBox.shrink());
  entry.dispose();
  await tester.pump(const Duration(seconds: 5)); // toast éventuel
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.setAdsSuppressedUntil(null);
  });

  testWidgets('1. état normal : invitation affichée', (tester) async {
    final entry = AdFreeHourEntry(rewardService: FakeRewardService());
    await _pumpRow(tester, entry);

    expect(find.text(RewardedWording.invitation), findsOneWidget);
    await _tearDown(tester, entry);
  });

  testWidgets(
      '2/3/5/6. tap → confirmation → requestReward(adFreeHour) → message de '
      'succès et temps restant', (tester) async {
    final service = FakeRewardService();
    final entry = AdFreeHourEntry(rewardService: service);
    await _pumpRow(tester, entry);

    await tester.tap(find.text(RewardedWording.invitation));
    await tester.pumpAndSettle();

    // Confirmation affichée ; aucun Rewarded tant qu'elle n'est pas validée.
    expect(find.text(RewardedWording.confirmation), findsOneWidget);
    expect(service.requestedKinds, isEmpty);

    await tester.tap(find.text(RewardedWording.confirmAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(service.requestedKinds, [RewardKind.adFreeHour]);
    expect(await UserPrefs.instance.getAdsSuppressedUntil(), isNotNull);
    expect(find.text(RewardedWording.adFreeHourEarned), findsOneWidget);
    expect(find.textContaining('لا إعلانات لمدة ساعة — متبقٍ'), findsOneWidget);

    await _tearDown(tester, entry);
  });

  testWidgets('confirmation annulée → aucun Rewarded', (tester) async {
    final service = FakeRewardService();
    final entry = AdFreeHourEntry(rewardService: service);
    await _pumpRow(tester, entry);

    await tester.tap(find.text(RewardedWording.invitation));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RewardedWording.cancelAction));
    await tester.pumpAndSettle();

    expect(service.requestedKinds, isEmpty);
    expect(find.text(RewardedWording.invitation), findsOneWidget);
    await _tearDown(tester, entry);
  });

  testWidgets('4. récompense non obtenue → invitation, aucun message',
      (tester) async {
    final service =
        FakeRewardService(outcome: RewardOutcome.dismissedWithoutReward);
    final entry = AdFreeHourEntry(rewardService: service);
    await _pumpRow(tester, entry);

    await tester.tap(find.text(RewardedWording.invitation));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RewardedWording.confirmAction));
    await tester.pumpAndSettle();

    expect(service.requestedKinds, [RewardKind.adFreeHour]);
    expect(find.text(RewardedWording.invitation), findsOneWidget);
    expect(find.text(RewardedWording.adFreeHourEarned), findsNothing);
    await _tearDown(tester, entry);
  });

  testWidgets(
      '7/8. heure active : temps restant affiché, tap sans aucun Rewarded',
      (tester) async {
    await UserPrefs.instance.setAdsSuppressedUntil(
      DateTime.now().add(const Duration(minutes: 30)),
    );
    final service = FakeRewardService();
    final entry = AdFreeHourEntry(rewardService: service);
    await _pumpRow(tester, entry);

    final active = find.textContaining('لا إعلانات لمدة ساعة — متبقٍ');
    expect(active, findsOneWidget);

    await tester.tap(active);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(RewardedWording.confirmation), findsNothing);
    expect(service.requestedKinds, isEmpty);
    await _tearDown(tester, entry);
  });

  testWidgets('Rewarded non proposable → ligne absente, séparateur compris',
      (tester) async {
    final entry =
        AdFreeHourEntry(rewardService: FakeRewardService(offerable: false));
    await _pumpRow(tester, entry);

    expect(find.text(RewardedWording.invitation), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AdFreeHourSettingsRow),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
    await _tearDown(tester, entry);
  });
}
