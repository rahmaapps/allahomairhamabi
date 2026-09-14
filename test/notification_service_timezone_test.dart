// TEST CIBLÉ LOT 4.C — validation de la correction B1
// (`NotificationService._nextInstanceOfTime`/`_nextInstanceOfWeekday`).
//
// Ces deux méthodes sont privées : on ne peut pas les appeler directement
// depuis ce fichier (bibliothèque distincte), et on ne modifie pas
// `notification_service.dart` pour les exposer. On les exerce donc de deux
// façons complémentaires, sans toucher à la logique de production :
//
// 1) De bout en bout, via l'API publique réellement utilisée par
//    `SettingsScreen` (`scheduleDailyReminder`/`scheduleWeeklyReminder`), en
//    interceptant l'appel de canal de plateforme `zonedSchedule` envoyé par
//    `flutter_local_notifications` (canal `dexterous.com/flutter/local_notifications`).
//    Ce canal transporte `TZDateTime.toMap()`, qui inclut `timeZoneName:
//    location.name` — exactement le champ que le plugin natif utilise pour
//    recalculer chaque occurrence récurrente (`matchDateTimeComponents`).
//    Avant B1 ce champ valait toujours "UTC" (bug identifié à l'audit) ;
//    après B1 il doit refléter le fuseau réellement configuré (`tz.local`).
//
// 2) Directement sur le pattern `timezone` utilisé par la correction
//    (`tz.TZDateTime(tz.local, y, m, d, h, min)`), comparé à l'ancien
//    pattern bugué (`tz.TZDateTime.from(instant.toUtc(), tz.UTC)`), sur une
//    vraie transition DST documentée (Europe/Paris, dernier dimanche de
//    mars 2026) — pour prouver que l'heure murale locale est bien préservée
//    par le nouveau pattern, et dériverait avec l'ancien.
//
// LIMITATION : `_nextInstanceOfTime`/`_nextInstanceOfWeekday` utilisent en
// interne `tz.TZDateTime.now(tz.local)` (l'horloge réelle, non injectable
// sans modifier la production). Le test (2) ne peut donc pas forcer « now »
// au moment exact d'une transition DST à l'intérieur de ces méthodes elles-
// mêmes : il reproduit fidèlement leur construction (`tz.TZDateTime(tz.local,
// ...)`) sur des dates fixes qui encadrent une vraie transition DST, plutôt
// que de simuler « l'app tourne la veille du changement d'heure ». Le test
// (1) reste lui un appel réel des méthodes privées (via l'API publique),
// mais à la date d'exécution du test, pas à une date DST choisie.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:test_1/notification_service.dart';

const MethodChannel _flnChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUpAll(() {
    tzdata.initializeTimeZones();
    // Force la façade `FlutterLocalNotificationsPlugin` sur sa branche
    // Android — sinon, sur l'hôte de test (Windows/Linux/macOS),
    // `zonedSchedule()` lève `UnimplementedError`. `FlutterLocalNotificationsPlugin`
    // et `NotificationService` sont tous deux des singletons paresseux :
    // ceci doit donc être posé avant toute première référence à
    // `NotificationService.instance` dans ce fichier.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_flnChannel, (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'canScheduleExactNotifications':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_flnChannel, null);
  });

  group('B1 — TZDateTime planifié dans tz.local (et non tz.UTC)', () {
    test(
      'rappel quotidien : timeZoneName + heure murale transmis à zonedSchedule()',
      () async {
        tz.setLocalLocation(tz.getLocation('Europe/Paris'));

        final ok = await NotificationService.instance.scheduleDailyReminder(
          periodId: 'period_morning',
          hour: 9,
          minute: 30,
        );
        expect(ok, isTrue);

        final zonedCall = calls.firstWhere((c) => c.method == 'zonedSchedule');
        final args = Map<String, dynamic>.from(zonedCall.arguments as Map);

        // Avant B1 : toujours "UTC" (tz.TZDateTime.from(_, tz.UTC)).
        expect(args['timeZoneName'], 'Europe/Paris');
        expect(args['scheduledDateTime'], contains('09:30:00'));
      },
    );

    test(
      'rappel hebdomadaire (vendredi) : timeZoneName + heure murale transmis à zonedSchedule()',
      () async {
        tz.setLocalLocation(tz.getLocation('Europe/Paris'));

        final ok = await NotificationService.instance.scheduleWeeklyReminder(
          periodId: 'period_friday',
          weekday: DateTime.friday,
          hour: 9,
          minute: 0,
        );
        expect(ok, isTrue);

        final zonedCall = calls.lastWhere((c) => c.method == 'zonedSchedule');
        final args = Map<String, dynamic>.from(zonedCall.arguments as Map);

        expect(args['timeZoneName'], 'Europe/Paris');
        expect(args['scheduledDateTime'], contains('09:00:00'));
      },
    );

    test(
      'un fuseau différent (Africa/Casablanca) est répercuté tel quel — '
      'pas figé sur une valeur fixe',
      () async {
        tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));

        await NotificationService.instance.scheduleDailyReminder(
          periodId: 'period_evening',
          hour: 20,
          minute: 0,
        );

        final zonedCall = calls.lastWhere((c) => c.method == 'zonedSchedule');
        final args = Map<String, dynamic>.from(zonedCall.arguments as Map);
        expect(args['timeZoneName'], 'Africa/Casablanca');
      },
    );
  });

  group('B1 — préservation de l’heure murale locale à travers une transition DST', () {
    test(
      'tz.TZDateTime(tz.local, ...) (pattern B1) préserve 09:00 murale autour du '
      'passage à l’heure d’été 2026 (Europe/Paris) ; l’ancien pattern UTC en dérive',
      () {
        final paris = tz.getLocation('Europe/Paris');

        // Dernier dimanche de mars 2026 = 29 mars (avance d'heure 02:00 -> 03:00
        // CEST) : 28 mars 09:00 est la veille, encore en heure d'hiver (UTC+1).
        final before = tz.TZDateTime(paris, 2026, 3, 28, 9, 0);
        final afterSameWallClock = tz.TZDateTime(paris, 2026, 3, 29, 9, 0);

        // Propriété que B1 restaure : construire directement le lendemain
        // dans tz.local avec la même heure murale conserve bien 09:00 heure
        // locale, quel que soit le décalage UTC réel ce jour-là (+1h -> +2h).
        expect(afterSameWallClock.hour, 9);
        expect(afterSameWallClock.minute, 0);
        // Le jour du changement d'heure ne dure que 23h : la différence
        // n'est donc PAS 24h pile — preuve que l'heure murale, et non un
        // delta UTC fixe, a bien été préservée.
        expect(afterSameWallClock.difference(before), const Duration(hours: 23));
        expect(afterSameWallClock.difference(before), isNot(const Duration(days: 1)));

        // Ancien pattern (avant B1) : tz.TZDateTime.from(instant.toUtc(), tz.UTC)
        // puis .add(Duration(days: 1)) — reproduit ici pour comparaison. UTC
        // n'ayant pas de DST, "+1 jour" ajoute toujours exactement 24h ;
        // réinterprété dans le fuseau réel de l'utilisateur une fois la
        // transition franchie, cela correspond à 10:00 (et non 09:00) —
        // exactement la dérive que B1 corrige.
        final beforeAsUtc = tz.TZDateTime.from(before, tz.UTC);
        final afterOldBuggyPattern = beforeAsUtc.add(const Duration(days: 1));
        final afterOldBuggyPatternInParis =
            tz.TZDateTime.from(afterOldBuggyPattern, paris);

        expect(afterOldBuggyPatternInParis.hour, 10);
        expect(afterOldBuggyPatternInParis.hour, isNot(9));
      },
    );
  });
}
