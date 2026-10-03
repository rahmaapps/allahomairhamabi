// Tests LOT 5.D — policy d'éligibilité à la demande d'évaluation.
//
// Policy strictement pure : aucune E/S, aucun canal de plateforme, aucune
// horloge réelle (`now` est toujours injecté). Les bornes exactes des deux
// délais verrouillés (7 jours d'ancienneté, 90 jours de cooldown) sont
// testées des deux côtés, à la seconde près.
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/review/review_policy.dart';
import 'package:test_1/review/review_trigger.dart';

void main() {
  final now = DateTime(2026, 9, 19, 12, 0);
  const trigger = ReviewTrigger.leavingFavorites;

  /// Toutes conditions réunies par défaut — chaque test ne fait varier que
  /// le critère qu'il exerce.
  bool canRequest({
    ReviewTrigger trigger = ReviewTrigger.leavingFavorites,
    DateTime? firstOpenAt,
    DateTime? lastPromptedAt,
    bool adPresenting = false,
  }) {
    return ReviewPolicy.canRequestReview(
      trigger: trigger,
      firstOpenAt: firstOpenAt ?? now.subtract(const Duration(days: 365)),
      lastPromptedAt: lastPromptedAt,
      adPresenting: adPresenting,
      now: now,
    );
  }

  group('ReviewPolicy — déclencheur (D1)', () {
    test('le retour Favoris → HOME est autorisé', () {
      expect(ReviewPolicy.isTriggerEligible(trigger), isTrue);
    });

    test(
        'aucune autre transition n\'existe comme déclencheur : l\'enum est '
        'strictement limité au retour Favoris → HOME (donc ni Recherche, ni '
        'DuaRead, ni Grave Visit, ni Onboarding, ni « دعاء آخر » ne sont '
        'même représentables)', () {
      expect(ReviewTrigger.values, [ReviewTrigger.leavingFavorites]);
    });
  });

  group('ReviewPolicy — ancienneté de l\'installation (D3 : 7 jours)', () {
    test('valeur produit verrouillée', () {
      expect(ReviewPolicy.minimumAppAge, const Duration(days: 7));
    });

    test('moins de 7 jours → aucune sollicitation', () {
      expect(
        ReviewPolicy.isAppOldEnough(
          firstOpenAt: now.subtract(const Duration(days: 6, hours: 23, minutes: 59)),
          now: now,
        ),
        isFalse,
      );
      expect(
        canRequest(
          firstOpenAt: now.subtract(const Duration(days: 6, hours: 23, minutes: 59)),
        ),
        isFalse,
      );
    });

    test('exactement 7 jours → éligible (borne incluse)', () {
      expect(
        ReviewPolicy.isAppOldEnough(
          firstOpenAt: now.subtract(const Duration(days: 7)),
          now: now,
        ),
        isTrue,
      );
      expect(
        canRequest(firstOpenAt: now.subtract(const Duration(days: 7))),
        isTrue,
      );
    });

    test('plus de 7 jours → éligible', () {
      expect(
        canRequest(firstOpenAt: now.subtract(const Duration(days: 30))),
        isTrue,
      );
    });

    test('date de premier usage absente → aucune sollicitation', () {
      expect(
        ReviewPolicy.isAppOldEnough(firstOpenAt: null, now: now),
        isFalse,
      );
      // Appel direct : le helper `canRequest` substitue une valeur par
      // défaut à `null`, il ne peut donc pas exercer ce cas.
      expect(
        ReviewPolicy.canRequestReview(
          trigger: trigger,
          firstOpenAt: null,
          lastPromptedAt: null,
          adPresenting: false,
          now: now,
        ),
        isFalse,
      );
    });

    test('date de premier usage dans le futur (horloge reculée) → refus', () {
      expect(
        canRequest(firstOpenAt: now.add(const Duration(days: 3))),
        isFalse,
      );
    });
  });

  group('ReviewPolicy — cooldown entre sollicitations (D4/D5 : 90 jours)',
      () {
    test('valeur produit verrouillée', () {
      expect(ReviewPolicy.promptCooldown, const Duration(days: 90));
    });

    test('aucune sollicitation antérieure → éligible si ancienneté OK', () {
      expect(
        ReviewPolicy.isCooldownElapsed(lastPromptedAt: null, now: now),
        isTrue,
      );
      expect(canRequest(lastPromptedAt: null), isTrue);
    });

    test('moins de 90 jours depuis la dernière → aucune sollicitation', () {
      expect(
        ReviewPolicy.isCooldownElapsed(
          lastPromptedAt: now.subtract(const Duration(days: 89, hours: 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        canRequest(
          lastPromptedAt: now.subtract(const Duration(days: 89, hours: 23)),
        ),
        isFalse,
      );
    });

    test('exactement 90 jours → éligible (borne incluse)', () {
      expect(
        ReviewPolicy.isCooldownElapsed(
          lastPromptedAt: now.subtract(const Duration(days: 90)),
          now: now,
        ),
        isTrue,
      );
      expect(
        canRequest(lastPromptedAt: now.subtract(const Duration(days: 90))),
        isTrue,
      );
    });

    test('plus de 90 jours → éligible', () {
      expect(
        canRequest(lastPromptedAt: now.subtract(const Duration(days: 200))),
        isTrue,
      );
    });

    test(
        'le cooldown prime sur l\'ancienneté : une app installée depuis des '
        'années reste muette tant que les 90 jours ne sont pas écoulés', () {
      expect(
        canRequest(
          firstOpenAt: now.subtract(const Duration(days: 900)),
          lastPromptedAt: now.subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
    });
  });

  group('ReviewPolicy — publicité plein écran (D6)', () {
    test('publicité en cours ou juste présentée → aucune sollicitation', () {
      expect(canRequest(adPresenting: true), isFalse);
    });

    test(
        'le refus publicitaire prime sur toutes les autres conditions '
        'réunies', () {
      expect(
        ReviewPolicy.canRequestReview(
          trigger: trigger,
          firstOpenAt: now.subtract(const Duration(days: 365)),
          lastPromptedAt: null,
          adPresenting: true,
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('ReviewPolicy — décision complète', () {
    test('true uniquement quand toutes les conditions sont réunies', () {
      expect(canRequest(), isTrue);
    });
  });
}
