// Tests LOT 5.H — cohérence des politiques de confidentialité avec l'état
// réel de l'application.
//
// Assertions structurelles sur les fichiers servis par le site (mêmes URL
// qu'avant) : les deux langues doivent rester équivalentes et couvrir ce que
// le code fait réellement — bannières, interstitiels, annonces avec
// récompense, consentement UMP, identifiant publicitaire.
//
// LOT 68-B.0.1 : le site public vit dans `site/` (seul dossier publié par
// GitHub Pages) ; les URL publiques sont inchangées.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ads_config.dart';

/// Contenu du fichier avec les espaces normalisés : les politiques sont
/// mises en forme sur plusieurs lignes, une expression comme « Privacy
/// Sandbox » peut donc être coupée par un retour à la ligne.
String _read(String path) => File(path)
    .readAsStringSync()
    .replaceAll(RegExp(r'\s+'), ' ');

void main() {
  final ar = _read('site/privacy_ar.html');
  final fr = _read('site/privacy_fr.html');

  group('Politiques AR / FR — équivalence', () {
    test('les deux versions existent et ont les mêmes sections', () {
      expect(ar, isNotEmpty);
      expect(fr, isNotEmpty);
      expect(
        '<h2>'.allMatches(ar).length,
        '<h2>'.allMatches(fr).length,
      );
    });

    test('date de mise à jour présente dans les deux', () {
      expect(ar, contains('آخر تحديث'));
      expect(fr, contains('Dernière mise à jour'));
    });
  });

  group('Annonces avec récompense (LOT 5.H)', () {
    test('AR décrit le Rewarded, volontaire, avec ses deux contreparties', () {
      expect(ar, contains('Rewarded'));
      expect(ar, contains('اختيارية'));
      expect(ar, contains('إيقاف الإعلانات لمدة ساعة'));
      expect(ar, contains('المشاركة كصورة'));
    });

    test('FR décrit le Rewarded, facultatif, avec ses deux contreparties', () {
      expect(fr, contains('Rewarded'));
      expect(fr, contains('facultatives'));
      expect(fr, contains('pendant une heure'));
      expect(fr, contains('partage comme image'));
    });

    test('jamais présenté comme un achat, un abonnement ou un paiement', () {
      // Le texte nie explicitement ces qualifications ; il ne doit jamais
      // les présenter comme le fonctionnement réel.
      expect(fr, contains('ni d\'un achat'));
      expect(fr, contains('ni d\'un abonnement'));
      expect(fr, contains('ni d\'un paiement'));
      expect(fr, contains('ni d\'une obligation'));
      expect(ar, contains('وليست هذه المكافأة شراءً'));

      // Aucune trace d'un moyen de paiement ou d'un don, absents de l'app.
      for (final forbidden in const [
        'PayPal',
        'Stripe',
        'Google Play Billing',
        'in-app purchase',
      ]) {
        expect(ar.contains(forbidden), isFalse, reason: forbidden);
        expect(fr.contains(forbidden), isFalse, reason: forbidden);
      }
    });

    test('le partage texte reste annoncé comme gratuit', () {
      expect(fr, contains('texte d\'un doua reste toujours gratuit'));
      expect(ar, contains('مشاركة نص'));
    });
  });

  group('Cohérence avec le code publicitaire', () {
    test('les trois formats réellement intégrés sont décrits', () {
      // Chaque langue décrit les mêmes formats dans ses propres termes.
      expect(ar, contains('شريطية (Banner)'));
      expect(ar, contains('بينية (Interstitial)'));
      expect(fr, contains('bannières'));
      expect(fr, contains('interstitiels'));
      for (final source in [ar, fr]) {
        expect(source, contains('Rewarded'));
      }
      // Les trois unités existent bien côté configuration.
      expect(AdsConfig.bannerAdUnitId, isNotEmpty);
      expect(AdsConfig.interstitialAdUnitId, isNotEmpty);
      expect(AdsConfig.rewardedAdUnitId, isNotEmpty);
    });

    test('consentement UMP et point d\'entrée « خيارات الخصوصية » décrits', () {
      for (final source in [ar, fr]) {
        expect(source, contains('User Messaging Platform'));
        expect(source, contains('خيارات الخصوصية'));
      }
    });

    test('identifiant publicitaire et traitement par des tiers décrits', () {
      for (final source in [ar, fr]) {
        expect(source, contains('Advertising ID'));
        expect(source, contains('Privacy Sandbox'));
      }
      expect(fr, contains('services publicitaires tiers'));
      expect(ar, contains('خدمات الإعلان التابعة لجهات خارجية'));
    });

    test('aucun identifiant AdMob n\'est exposé dans les politiques', () {
      for (final source in [ar, fr]) {
        expect(source.contains('ca-app-pub-'), isFalse);
      }
    });
  });

  group('Lien utilisé par l\'application (inchangé)', () {
    test('« عن التطبيق » pointe toujours vers le site qui sert la politique',
        () {
      final settings = _read('lib/settings_screen.dart');
      expect(
        settings,
        contains("'https://rahmaapps.github.io/allahomairhamabi/'"),
      );
    });

    test('la page d\'accueil du site lie toujours la politique', () {
      expect(_read('site/index.html'), contains('href="privacy_ar.html"'));
    });

    test('l\'entrée « خيارات الخصوصية » reste branchée dans les Paramètres',
        () {
      final settings = _read('lib/settings_screen.dart');
      expect(settings, contains('خيارات الخصوصية'));
      expect(settings, contains('_openPrivacyOptions'));
      expect(settings, contains('_privacyOptionsRequired'));
    });
  });
}
