import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'review_availability.dart';

/// Implémentation réelle de [ReviewAvailability], adossée à l'API Google
/// Play In-App Review via le package `in_app_review` (D7). Non testée
/// directement en `flutter_test` (canal de plateforme natif) — voir les
/// tests de `ReviewPromptController`, qui dépendent de l'interface via un
/// fake.
///
/// `openStoreListing()` n'est volontairement JAMAIS appelé : un repli vers
/// la fiche Play Store sortirait l'utilisateur de l'application, ce qui
/// serait bien plus intrusif que la demande native elle-même et n'est
/// couvert par aucune décision produit du LOT 5.D.
class InAppReviewAvailability implements ReviewAvailability {
  InAppReviewAvailability({InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      // Hors contexte Play Store (build sideloadé, émulateur sans Play
      // Services, environnement de test) : indisponible, jamais une erreur.
      if (kDebugMode) {
        debugPrint('[Review] Mécanisme natif indisponible: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> requestReview() async {
    try {
      await _inAppReview.requestReview();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Review] Échec de la demande d\'évaluation: $e');
      }
      return false;
    }
  }
}
