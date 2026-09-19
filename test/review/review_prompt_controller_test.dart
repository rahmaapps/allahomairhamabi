// Tests LOT 5.D — service de sollicitation d'évaluation.
//
// Aucun dialogue Google Play n'est jamais affiché : le controller dépend de
// l'abstraction `ReviewAvailability`, injectée ici par un fake. C'est
// précisément ce qui rend la fonctionnalité testable de bout en bout sans
// compte Play Store, sans appareil réel et sans canal de plateforme.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_1/review/review_policy.dart';
import 'package:test_1/review/review_prompt_controller.dart';
import 'package:test_1/review/review_trigger.dart';
import 'package:test_1/user_prefs.dart';

import 'fakes/fake_review_availability.dart';

const _trigger = ReviewTrigger.leavingFavorites;

({ReviewPromptController controller, FakeReviewAvailability availability})
    _build({bool adPresenting = false}) {
  final availability = FakeReviewAvailability();
  return (
    controller: ReviewPromptController(
      availability: availability,
      adActivityProbe: () async => adPresenting,
    ),
    availability: availability,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // `UserPrefs.instance` est un singleton dont le cache interne survit
    // entre les tests d'un même fichier : les deux clés du LOT 5.D sont
    // explicitement remises à zéro (même précaution que les tests LOT 5.C).
    await UserPrefs.instance.setFirstOpenAt(null);
    await UserPrefs.instance.setLastReviewPromptedAt(null);
    await UserPrefs.instance.setLastInterstitialShownAt(null);
  });

  /// Installation suffisamment ancienne pour satisfaire D3.
  Future<void> installedSince(Duration age) =>
      UserPrefs.instance.setFirstOpenAt(DateTime.now().subtract(age));

  group('ReviewPromptController — ancienneté (D3)', () {
    test('moins de 7 jours : aucune sollicitation, aucun cooldown consommé',
        () async {
      await installedSince(const Duration(days: 6, hours: 23));
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 0);
      expect(f.availability.isAvailableCallCount, 0,
          reason: 'la policy doit refuser AVANT de solliciter la plateforme');
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull);
    });

    test('exactement 7 jours : sollicitation émise', () async {
      await installedSince(ReviewPolicy.minimumAppAge);
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 1);
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNotNull);
    });

    test('date de premier usage jamais enregistrée : aucune sollicitation',
        () async {
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 0);
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull);
    });
  });

  group('ReviewPromptController — cooldown 90 jours (D4/D5)', () {
    test('aucune sollicitation antérieure : émise', () async {
      await installedSince(const Duration(days: 30));
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 1);
    });

    test('moins de 90 jours depuis la dernière : aucune sollicitation',
        () async {
      await installedSince(const Duration(days: 365));
      await UserPrefs.instance.setLastReviewPromptedAt(
        DateTime.now().subtract(const Duration(days: 89, hours: 23)),
      );
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 0);
    });

    test('exactement 90 jours depuis la dernière : à nouveau émise',
        () async {
      await installedSince(const Duration(days: 365));
      await UserPrefs.instance.setLastReviewPromptedAt(
        DateTime.now().subtract(ReviewPolicy.promptCooldown),
      );
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 1);
    });

    test(
        'refus / fermeture du dialogue : aucun retry immédiat, le cooldown '
        'de 90 jours s\'applique exactement comme pour une notation '
        '(Google ne renvoyant jamais l\'issue réelle du dialogue)', () async {
      await installedSince(const Duration(days: 365));
      final f = _build();

      await f.controller.maybeRequestOnTransition(_trigger);
      expect(f.availability.requestReviewCallCount, 1);

      final promptedAt = await UserPrefs.instance.getLastReviewPromptedAt();
      expect(promptedAt, isNotNull);

      // Retours Favoris → HOME suivants, immédiatement après.
      await f.controller.maybeRequestOnTransition(_trigger);
      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 1);
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), promptedAt,
          reason: 'le cooldown ne doit pas être repoussé par des '
              'transitions qui n\'ont rien sollicité');
    });

    test('cooldown persisté : relu depuis UserPrefs après « redémarrage »',
        () async {
      final promptedAt = DateTime(2026, 9, 19, 12, 0);
      await UserPrefs.instance.setLastReviewPromptedAt(promptedAt);

      expect(
        await UserPrefs.instance.getLastReviewPromptedAt(),
        promptedAt,
      );
    });
  });

  group('ReviewPromptController — indisponibilité et erreurs (D7)', () {
    test(
        'mécanisme natif indisponible (hors Play Store) : aucune exception, '
        'aucune sollicitation, et surtout AUCUN cooldown consommé',
        () async {
      await installedSince(const Duration(days: 365));
      final f = _build();
      f.availability.available = false;

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.isAvailableCallCount, 1);
      expect(f.availability.requestReviewCallCount, 0);
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull,
          reason: 'une installation hors Play Store ne doit jamais brûler '
              '90 jours pour un dialogue qui n\'a pas pu exister');
    });

    test('demande échouée : aucun cooldown consommé', () async {
      await installedSince(const Duration(days: 365));
      final f = _build();
      f.availability.requestSucceeds = false;

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 1);
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull);
    });

    test('exception plateforme sur isAvailable : aucune exception propagée',
        () async {
      await installedSince(const Duration(days: 365));
      final f = _build();
      f.availability.throwOnIsAvailable = true;

      await expectLater(
        f.controller.maybeRequestOnTransition(_trigger),
        completes,
      );
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull);
    });

    test('exception plateforme sur requestReview : aucune exception propagée',
        () async {
      await installedSince(const Duration(days: 365));
      final f = _build();
      f.availability.throwOnRequestReview = true;

      await expectLater(
        f.controller.maybeRequestOnTransition(_trigger),
        completes,
      );
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull);
    });

    test('sonde publicitaire en erreur : refus silencieux, aucun blocage',
        () async {
      await installedSince(const Duration(days: 365));
      final availability = FakeReviewAvailability();
      final controller = ReviewPromptController(
        availability: availability,
        adActivityProbe: () async => throw StateError('sonde en erreur'),
      );

      await expectLater(
        controller.maybeRequestOnTransition(_trigger),
        completes,
      );
      expect(availability.requestReviewCallCount, 0);
    });

    test(
        'le controller reste utilisable après une erreur (garde de '
        'concurrence correctement relâchée)', () async {
      await installedSince(const Duration(days: 365));
      final f = _build();
      f.availability.throwOnIsAvailable = true;

      await f.controller.maybeRequestOnTransition(_trigger);

      f.availability.throwOnIsAvailable = false;
      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.requestReviewCallCount, 1);
    });
  });

  group('ReviewPromptController — publicité plein écran (D6)', () {
    test('publicité en cours ou juste présentée : aucune sollicitation',
        () async {
      await installedSince(const Duration(days: 365));
      final f = _build(adPresenting: true);

      await f.controller.maybeRequestOnTransition(_trigger);

      expect(f.availability.isAvailableCallCount, 0);
      expect(f.availability.requestReviewCallCount, 0);
      expect(await UserPrefs.instance.getLastReviewPromptedAt(), isNull);
    });
  });

  group('ReviewPromptController — concurrence', () {
    test('deux transitions rapprochées ne sollicitent qu\'une seule fois',
        () async {
      await installedSince(const Duration(days: 365));
      final f = _build();

      final first = f.controller.maybeRequestOnTransition(_trigger);
      final second = f.controller.maybeRequestOnTransition(_trigger);
      await Future.wait([first, second]);

      expect(f.availability.requestReviewCallCount, 1);
    });
  });
}
