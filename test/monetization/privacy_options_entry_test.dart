// Tests LOT 5.E — entrée « خيارات الخصوصية » (options de confidentialité UMP).
//
// Portée : la décision d'afficher la ligne et l'ouverture du formulaire,
// isolées dans `PrivacyOptionsEntry` et branchées sur l'interface
// `ConsentService` du LOT 5.A via un fake.
//
// Hors portée — limitation déjà documentée dans ce projet pour cet écran
// précis (voir `test/settings_screen_lot3g_test.dart`,
// `test/onboarding_screen_test.dart`, `test/phase7_*`) : un test widget de
// `SettingsScreen` est impossible en `flutter_test` simple, `_bootstrap()`
// attendant `NotificationService.ensureInitialized()` (canal de plateforme
// natif non mockable), ce qui laisse l'écran bloqué sur son état de
// chargement. Le rendu réel de la ligne et le formulaire UMP lui-même
// relèvent donc de la validation sur appareil réel.
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/consent_service.dart';
import 'package:test_1/monetization/privacy_options_entry.dart';

import 'fakes/fake_consent_service.dart';

/// Fake dédié aux cas d'erreur : `GoogleUmpConsentService` (LOT 5.A, non
/// modifié par ce lot) n'enveloppe ni `isPrivacyOptionsRequired()` ni
/// `showPrivacyOptionsForm()` dans un `try/catch` — une exception de
/// plateforme est donc un cas réel, que `PrivacyOptionsEntry` doit
/// absorber.
class _ThrowingConsentService implements ConsentService {
  _ThrowingConsentService({
    this.throwOnIsRequired = false,
    this.throwOnShowForm = false,
  });

  final bool throwOnIsRequired;
  final bool throwOnShowForm;

  @override
  Future<void> requestConsentUpdate() async {}

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    if (throwOnIsRequired) throw Exception('canal de plateforme indisponible');
    return true;
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    if (throwOnShowForm) throw Exception('formulaire UMP indisponible');
  }
}

void main() {
  group('PrivacyOptionsEntry — visibilité de la ligne', () {
    test('requise par Google → la ligne doit être affichée', () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = true;
      final entry = PrivacyOptionsEntry(consentService: consent);

      expect(await entry.isRequired(), isTrue);
    });

    test('non requise → la ligne doit être absente', () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = false;
      final entry = PrivacyOptionsEntry(consentService: consent);

      expect(await entry.isRequired(), isFalse);
    });

    test(
        'statut réévalué à chaque interrogation — jamais mis en cache '
        '(l\'état UMP du démarrage peut ne pas être encore exploitable)',
        () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = false;
      final entry = PrivacyOptionsEntry(consentService: consent);

      expect(await entry.isRequired(), isFalse);

      // L'état UMP devient exploitable après coup (mise à jour du
      // consentement terminée en tâche de fond, réseau revenu...).
      consent.privacyOptionsRequiredValue = true;

      expect(await entry.isRequired(), isTrue);
    });
  });

  group('PrivacyOptionsEntry — ouverture du formulaire', () {
    test('activation → le service UMP existant est appelé une seule fois',
        () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = true;
      final entry = PrivacyOptionsEntry(consentService: consent);

      expect(await entry.open(), isTrue);
      expect(consent.showPrivacyOptionsFormCallCount, 1);
    });

    test('deux activations rapprochées n\'ouvrent qu\'un seul formulaire',
        () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = true;
      final entry = PrivacyOptionsEntry(consentService: consent);

      // Volontairement sans `await` sur le premier appel : c'est le cas
      // réel d'un double tap sur la ligne.
      final first = entry.open();
      final second = entry.open();
      await Future.wait([first, second]);

      expect(consent.showPrivacyOptionsFormCallCount, 1);
    });

    test('une nouvelle activation reste possible après la précédente',
        () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = true;
      final entry = PrivacyOptionsEntry(consentService: consent);

      await entry.open();
      await entry.open();

      expect(consent.showPrivacyOptionsFormCallCount, 2);
    });
  });

  group('PrivacyOptionsEntry — erreurs de plateforme', () {
    test(
        'exception sur isPrivacyOptionsRequired : aucune exception propagée, '
        'ligne absente', () async {
      final entry = PrivacyOptionsEntry(
        consentService: _ThrowingConsentService(throwOnIsRequired: true),
      );

      expect(await entry.isRequired(), isFalse);
    });

    test(
        'exception sur showPrivacyOptionsForm : aucune exception propagée, '
        'échec signalé à l\'appelant (toast, jamais un crash)', () async {
      final entry = PrivacyOptionsEntry(
        consentService: _ThrowingConsentService(throwOnShowForm: true),
      );

      expect(await entry.open(), isFalse);
    });

    test('un échec ne bloque pas les ouvertures suivantes', () async {
      final entry = PrivacyOptionsEntry(
        consentService: _ThrowingConsentService(throwOnShowForm: true),
      );

      expect(await entry.open(), isFalse);
      // La garde de concurrence a bien été relâchée malgré l'exception.
      expect(await entry.open(), isFalse);
    });
  });

  group('PrivacyOptionsEntry — activation Ads post-consentement (A2)', () {
    test(
        'après fermeture du formulaire, le système d\'activation Ads est '
        'notifié — sans redémarrage de l\'application', () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = true;
      var settledCount = 0;
      final entry = PrivacyOptionsEntry(
        consentService: consent,
        onConsentSettled: () async => settledCount++,
      );

      expect(await entry.open(), isTrue);

      expect(consent.showPrivacyOptionsFormCallCount, 1);
      expect(settledCount, 1);
    });

    test('formulaire en échec : aucune activation tentée', () async {
      var settledCount = 0;
      final entry = PrivacyOptionsEntry(
        consentService: _ThrowingConsentService(throwOnShowForm: true),
        onConsentSettled: () async => settledCount++,
      );

      expect(await entry.open(), isFalse);
      expect(settledCount, 0);
    });

    test(
        'échec de l\'activation Ads : l\'ouverture du formulaire reste un '
        'succès et rien n\'est propagé', () async {
      final consent = FakeConsentService()..privacyOptionsRequiredValue = true;
      final entry = PrivacyOptionsEntry(
        consentService: consent,
        onConsentSettled: () async => throw Exception('SDK indisponible'),
      );

      expect(await entry.open(), isTrue);
    });
  });

  group('PrivacyOptionsEntry — périmètre', () {
    test('ne dépend que de l\'interface ConsentService du LOT 5.A', () {
      // Un fake suffit à piloter entièrement la classe : aucune dépendance
      // au plugin `google_mobile_ads` n'est introduite par le LOT 5.E.
      expect(
        PrivacyOptionsEntry(consentService: FakeConsentService()),
        isA<PrivacyOptionsEntry>(),
      );
    });
  });
}
