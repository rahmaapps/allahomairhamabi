import 'package:flutter/foundation.dart';

import '../user_prefs.dart';
import 'ad_activity_probe.dart';
import 'in_app_review_availability.dart';
import 'interstitial_ad_activity_probe.dart';
import 'review_availability.dart';
import 'review_policy.dart';
import 'review_trigger.dart';

/// Service applicatif unique pilotant la demande d'évaluation (LOT 5.D).
///
/// Une demande d'évaluation n'appartient à aucun écran : elle est évaluée
/// sur une transition de navigation éligible, d'où une **instance
/// applicative unique** ([instance]) — garantie structurelle contre les
/// doubles sollicitations. Même patron que `InterstitialAdController`, mais
/// service entièrement distinct : aucune logique publicitaire n'est
/// redéfinie ni réutilisée ici, hormis la lecture seule de
/// [interstitialAdActivityProbe] exigée par D6.
///
/// Aucun écran ne connaît la policy : HOME se contente d'appeler
/// [maybeRequestOnTransition] après le retour depuis Favoris.
class ReviewPromptController {
  ReviewPromptController({
    required ReviewAvailability availability,
    required AdActivityProbe adActivityProbe,
  })  : _availability = availability,
        _adActivityProbe = adActivityProbe;

  /// Instance applicative unique, branchée sur le mécanisme natif réel.
  static final ReviewPromptController instance = ReviewPromptController(
    availability: InAppReviewAvailability(),
    adActivityProbe: interstitialAdActivityProbe,
  );

  final ReviewAvailability _availability;
  final AdActivityProbe _adActivityProbe;

  /// Garde contre les appels concurrents : deux transitions rapprochées ne
  /// doivent jamais déclencher deux évaluations — donc deux sollicitations —
  /// en parallèle pendant les `await` de la policy.
  bool _evaluating = false;

  /// Point d'entrée unique, appelé APRÈS qu'une transition de navigation a
  /// déjà eu lieu — la navigation n'attend donc jamais l'évaluation.
  ///
  /// Ne lève jamais d'exception, quelle qu'en soit l'origine (mécanisme
  /// natif absent, canal de plateforme indisponible, stockage illisible) :
  /// en cas d'erreur, aucune sollicitation n'est émise et aucun cooldown
  /// n'est consommé (D7).
  Future<void> maybeRequestOnTransition(ReviewTrigger trigger) async {
    if (_evaluating) return;

    _evaluating = true;
    try {
      await _evaluateAndRequest(trigger);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Review] Évaluation non bloquante — erreur ignorée: $e');
      }
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _evaluateAndRequest(ReviewTrigger trigger) async {
    final adPresenting = await _adActivityProbe();
    final firstOpenAt = await UserPrefs.instance.getFirstOpenAt();
    final lastPromptedAt = await UserPrefs.instance.getLastReviewPromptedAt();

    final allowed = ReviewPolicy.canRequestReview(
      trigger: trigger,
      firstOpenAt: firstOpenAt,
      lastPromptedAt: lastPromptedAt,
      adPresenting: adPresenting,
    );
    if (!allowed) return;

    // Mécanisme natif indisponible : aucune sollicitation, et surtout aucun
    // cooldown consommé — sans quoi une installation hors Play Store
    // brûlerait 90 jours pour un dialogue qui n'a jamais pu exister.
    if (!await _availability.isAvailable()) return;

    if (!await _availability.requestReview()) return;

    // Demande effectivement émise. Google ne renvoie JAMAIS l'issue réelle
    // (application notée, dialogue fermé, ou dialogue jamais affiché par
    // décision de Google) : consommer le cooldown dès l'émission est donc
    // la seule lecture correcte de D5 — un refus ou une fermeture se voit
    // appliquer exactement le même délai de 90 jours qu'une notation, et
    // aucune nouvelle tentative n'a lieu entre-temps.
    await UserPrefs.instance.setLastReviewPromptedAt(DateTime.now());
  }
}
