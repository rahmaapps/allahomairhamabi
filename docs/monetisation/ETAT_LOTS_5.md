# État des LOTS 5 — Monétisation, Évaluation, Conformité

> Dernière mise à jour : 2026-09-19. Décisions produit associées : [`DECISIONS_MONETISATION.md`](DECISIONS_MONETISATION.md).

## Vue d'ensemble

| Lot | Objet | Statut | Commit |
|---|---|---|---|
| **5.A** | Architecture Monétisation + Privacy/Consent | **TERMINÉ** | `d0784fd` |
| **5.B** | Bannières | **TERMINÉ** | `d0784fd` |
| **5.C** | Interstitiels | **TERMINÉ** | `d0784fd` |
| **5.D** | Évaluation / In-App Review | **VALIDÉ / TERMINÉ** | `547a95b` |
| **5.E** | Privacy Options + Privacy Policy + Documentation + Git hygiene | **TERMINÉ** *(sous réserve de l'audit produit)* | `d1483dd` |
| **5.F** | Préparation production : séparation test/production, App ID unique, test device, `maxAdContentRating`, correction A2 | **TERMINÉ** *(sous réserve de l'audit produit)* | voir commit LOT 5.F |

---

## LOT 5.A — Architecture Monétisation + Privacy/Consent — TERMINÉ

Socle, sans aucun affichage publicitaire.

- `ConsentService` (interface) + `GoogleUmpConsentService` (UMP réel) ;
- `AdsAvailability` : SDK initialisé **ET** `canRequestAds()` — source unique de vérité (D13) ;
- `AdsSdkInitializer`, `MonetizationBootstrap.runAtLaunch()` appelé à chaque lancement, jamais `await`é avant `runApp` ;
- `AdsPolicy` / `AdSurface` / `AdsFreeStatus` : policies pures, testables ;
- `RewardService` (abstraction) + `NoopRewardService` + `RewardEffects` + `RewardKind` (D14, D15) ;
- `AdsConfig` : identifiants **de test Google uniquement** ;
- `AndroidManifest.xml` : `INTERNET`, `ACCESS_NETWORK_STATE`, `APPLICATION_ID` de test.

## LOT 5.B — Bannières — TERMINÉ

- `BannerAdSlot` (widget) + `BannerAdSlotController` + `BannerAdLoader` / `GoogleBannerAdLoader` ;
- Bannière adaptive anchored, **hauteur nulle** tant qu'aucune annonce n'est chargée, aucun espace résiduel en cas d'échec ;
- Une seule tentative de chargement par instance, aucune boucle de retry ;
- Surfaces : HOME, Recherche, Favoris (D8) — jamais ailleurs (D9).

## LOT 5.C — Interstitiels — TERMINÉ

- `InterstitialAdController` (instance applicative unique) + `InterstitialAdLoader` / `GoogleInterstitialAdLoader` ;
- Déclencheurs : Recherche → HOME, Favoris → HOME (D10) ;
- Cooldown de 10 minutes persisté, consommé **uniquement** après présentation effective (D11) ;
- Policy réévaluée à l'instant de la présentation, jamais réutilisée depuis le chargement ;
- La navigation n'attend jamais la publicité.

## LOT 5.D — Évaluation / In-App Review — VALIDÉ / TERMINÉ

- `lib/review/` : `ReviewTrigger`, `ReviewPolicy`, `ReviewAvailability`, `InAppReviewAvailability`, `AdActivityProbe`, `interstitialAdActivityProbe`, `ReviewPromptController` ;
- Décisions D1–D7 de la série Évaluation ;
- Lecture **seule** de l'état interstitiel pour satisfaire D6 : aucun fichier de `lib/monetization/` n'est modifié par ce lot ;
- Intégré à l'historique Git au LOT 5.E sans aucun changement de comportement.

## LOT 5.E — Privacy Options + Privacy Policy + Documentation + Git hygiene

Lot de **conformité, documentation et hygiène** — aucune fonctionnalité de monétisation ajoutée.

- `PrivacyOptionsEntry` (`lib/monetization/privacy_options_entry.dart`) : premier et unique consommateur de `isPrivacyOptionsRequired()` / `showPrivacyOptionsForm()`, restés sans appelant depuis le LOT 5.A ;
- Entrée **« خيارات الخصوصية »** dans Paramètres, section `التطبيق`, entre `عن التطبيق` et `مشاركة التطبيق` : présente uniquement quand Google l'exige, statut réinterrogé à chaque ouverture de l'écran, erreurs absorbées avec toast arabe, navigation jamais bloquée ;
- `privacy_ar.html` / `privacy_fr.html` réécrites pour refléter fidèlement AdMob, l'UMP, l'identifiant publicitaire, les données réellement stockées localement et les choix offerts à l'utilisateur — versions AR et FR strictement alignées (mêmes 13 sections, même contenu) ;
- Documentation : ce fichier, `DECISIONS_MONETISATION.md`, mise à jour de `docs/V1.2_PROGRESS.md` ;
- `.gitignore` : `android/key.properties` et `android/local.properties`.

**Aucune** modification fonctionnelle des lots 5.A à 5.D.

## LOT 5.F — Préparation production

Lot **technique** : aucune décision produit modifiée, aucune surface publicitaire touchée, aucun identifiant de production inventé.

- **Environnement explicite** : `--dart-define=ADS_ENV=test|production`, **défaut `test`**. Un build release ordinaire reste en test ; la production ne s'active jamais implicitement.
- **Source unique de vérité pour l'App ID** : `android/ads_ids.properties`, lu par Gradle pour alimenter le placeholder `${admobAppId}` du manifest, et contrôlé côté Dart par `test/monetization/ads_config_test.dart`. Le manifest ne peut plus diverger de `AdsConfig`.
- **Fail-fast** : un build `ADS_ENV=production` échoue tant que les identifiants réels ne sont pas renseignés, et une valeur `ADS_ENV` invalide échoue aussi.
- **Accesseurs neutres** : `AdsConfig.appId` / `bannerAdUnitId` / `interstitialAdUnitId` — **une seule** unité Banner pour HOME, Recherche et Favoris (les surfaces restent distinguées par `AdSurface`).
- **Appareils de test** : `--dart-define=ADS_TEST_DEVICE_IDS=<id1>,<id2>`, vide par défaut, jamais committé.
- **`maxAdContentRating = G`** appliqué au point central d'initialisation. **Plafond déclaratif, pas une garantie de filtrage** : le blocage de catégories se fait dans la console AdMob et se contrôle a posteriori dans l'Ad Review Center.
- **Correction A2** : `AdsActivation` rejoue le contrôle `canRequestAds()` après la fermeture des options de confidentialité — le SDK devient initialisable dans la même session, sans redémarrage. Idempotent, sûr en concurrence, non bloquant, n'affiche aucune publicité. Un refus continue d'interdire toute requête.

### Commandes de build

```bash
# Développement / QA — identifiants de démonstration Google (défaut)
flutter build apk --debug
flutter build apk --release

# Production — refusé tant que les identifiants réels ne sont pas renseignés
flutter build appbundle --release --dart-define=ADS_ENV=production

# Validation sur appareil réel avec identifiants de production
flutter build apk --release --dart-define=ADS_ENV=production --dart-define=ADS_TEST_DEVICE_IDS=<ID_APPAREIL>
```

Pour passer en production : renseigner les six valeurs réelles dans `android/ads_ids.properties` **et** les trois constantes `production*` de `lib/monetization/ads_config.dart` (le test de cohérence échoue si les deux divergent).

---

## Hors périmètre — volontairement non fait

Ces points restent **bloquants pour une mise en production réelle** de la monétisation, et ne relèvent d'aucun des lots 5.A → 5.E :

| Élément | Nature | Raison |
|---|---|---|
| **Vrais identifiants AdMob de production** (App ID, Ad Units) | Configuration externe | Le mécanisme de bascule existe (LOT 5.F) ; seules les **valeurs** manquent — compte et unités AdMob à créer |
| Blocage de catégories publicitaires (Blocking controls, Ad Review Center) | Console AdMob | Configuration manuelle ; aucun filtrage ne garantit 0 publicité indésirable |
| **Configuration finale Play Console** : déclaration « contient des annonces », Sécurité des données (identifiant publicitaire), URL de politique, classification du contenu, public cible, `versionCode` | Externe | Hors périmètre de tout lot technique |
| **Publication** de la politique de confidentialité mise à jour | Externe | Les fichiers sont à jour dans le dépôt ; leur mise en ligne est une action de publication distincte |
| **Rewarded réel** (chargement, présentation, `onUserEarnedReward`, points d'appel UI) | Code + décision produit | Architecture seule à ce jour (D14) |
| **Share as Image conditionné par un Rewarded** | Code + décision produit | Share as Image est aujourd'hui gratuit et inconditionnel (D4 non activée) |
| **Soutien de l'application** (D5) | Code + décision produit + conformité Play | Totalement absent du code |
| **Validation visuelle sur appareil réel** : bannières, interstitiels, cooldowns, formulaire UMP, In-App Review, build release sous R8 | Validation | Canaux de plateforme non testables en `flutter_test` |

## Anomalie préexistante connue

`test/settings_screen_lot3g_test.dart` — `WorkManagerService.initialDelayForNextFriday` : échec d'exactement 1 h (`Expected 9, Actual 8`), cohérent avec un changement d'offset UTC du fuseau local entre les deux dates du test. Le code concerné est **mort** (conservé uniquement pour ce test) et **sans rapport** avec les lots 5.A → 5.E. **Anomalie préexistante, explicitement hors périmètre du LOT 5.E — ce n'est pas une régression.**
