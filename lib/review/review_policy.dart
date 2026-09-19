import 'review_trigger.dart';

/// Policy pure (aucune dépendance widget, aucun accès au stockage, aucun
/// appel plateforme — entièrement testable) qui détermine si une demande
/// d'évaluation peut être émise. Toutes les entrées sont injectées par
/// l'appelant : la policy ne lit jamais `UserPrefs` elle-même, exactement
/// comme `AdsPolicy` pour la monétisation.
///
/// Décisions produit verrouillées (LOT 5.D) :
/// - D1 : déclencheur unique, retour Favoris → HOME ;
/// - D3 : au moins 7 jours depuis le premier usage ;
/// - D4/D5 : au maximum une sollicitation tous les 90 jours, refus et
///   fermeture compris ;
/// - D6 : jamais pendant ni immédiatement autour d'une publicité plein
///   écran.
class ReviewPolicy {
  const ReviewPolicy._();

  /// Ancienneté minimale de l'installation avant toute sollicitation (D3).
  static const Duration minimumAppAge = Duration(days: 7);

  /// Espacement minimal entre deux sollicitations (D4/D5).
  static const Duration promptCooldown = Duration(days: 90);

  /// Liste d'autorisation explicite : tout ce qui n'y figure pas est refusé
  /// par défaut, y compris une valeur d'enum qui serait ajoutée plus tard.
  static const Set<ReviewTrigger> _eligibleTriggers = {
    ReviewTrigger.leavingFavorites,
  };

  static bool isTriggerEligible(ReviewTrigger trigger) =>
      _eligibleTriggers.contains(trigger);

  /// `true` si [minimumAppAge] est entièrement écoulée depuis
  /// [firstOpenAt]. Une date absente (`null`) refuse la sollicitation :
  /// sans preuve d'ancienneté, on ne sollicite pas — et une horloge
  /// reculée (date dans le futur) refuse également, l'écart étant négatif.
  static bool isAppOldEnough({required DateTime? firstOpenAt, DateTime? now}) {
    if (firstOpenAt == null) return false;
    final age = (now ?? DateTime.now()).difference(firstOpenAt);
    return age >= minimumAppAge;
  }

  /// `true` si aucune sollicitation n'a jamais été émise ([lastPromptedAt]
  /// `null`) ou si [promptCooldown] est entièrement écoulé.
  static bool isCooldownElapsed({
    required DateTime? lastPromptedAt,
    DateTime? now,
  }) {
    if (lastPromptedAt == null) return true;
    final elapsed = (now ?? DateTime.now()).difference(lastPromptedAt);
    return elapsed >= promptCooldown;
  }

  /// Décision finale. [adPresenting] est un simple booléen fourni par
  /// l'appelant : la policy ignore tout du système publicitaire, elle ne
  /// fait qu'en refuser la concomitance (D6).
  static bool canRequestReview({
    required ReviewTrigger trigger,
    required DateTime? firstOpenAt,
    required DateTime? lastPromptedAt,
    required bool adPresenting,
    DateTime? now,
  }) {
    if (!isTriggerEligible(trigger)) return false;
    if (adPresenting) return false;
    if (!isAppOldEnough(firstOpenAt: firstOpenAt, now: now)) return false;
    if (!isCooldownElapsed(lastPromptedAt: lastPromptedAt, now: now)) {
      return false;
    }
    return true;
  }
}
