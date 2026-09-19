# État des LOTS 5 — Monétisation, Évaluation, Conformité

> Dernière mise à jour : 2026-09-19. Décisions produit associées : [`DECISIONS_MONETISATION.md`](DECISIONS_MONETISATION.md).

## Vue d'ensemble

| Lot | Objet | Statut | Commit |
|---|---|---|---|
| **5.A** | Architecture Monétisation + Privacy/Consent | **TERMINÉ** | `d0784fd` |
| **5.B** | Bannières | **TERMINÉ** | `d0784fd` |
| **5.C** | Interstitiels | **TERMINÉ** | `d0784fd` |
| **5.D** | Évaluation / In-App Review | **VALIDÉ / TERMINÉ** | `547a95b` |
| **5.E** | Privacy Options + Privacy Policy + Documentation + Git hygiene | **TERMINÉ** *(sous réserve de l'audit produit)* | voir commit LOT 5.E |

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

---

## Hors périmètre — volontairement non fait

Ces points restent **bloquants pour une mise en production réelle** de la monétisation, et ne relèvent d'aucun des lots 5.A → 5.E :

| Élément | Nature | Raison |
|---|---|---|
| **Vrais identifiants AdMob de production** (App ID, Ad Units) | Configuration externe + code | Aucun compte/unité de production disponible ; l'app n'utilise que les identifiants de **test** Google |
| Séparation test / production des identifiants, `testDeviceIds` | Code | Dépend des identifiants de production |
| `maxAdContentRating` et blocage de catégories publicitaires | Code + console AdMob | Lot de filtrage ultérieur ; aucun filtrage ne garantit 0 publicité indésirable |
| **Configuration finale Play Console** : déclaration « contient des annonces », Sécurité des données (identifiant publicitaire), URL de politique, classification du contenu, public cible, `versionCode` | Externe | Hors périmètre de tout lot technique |
| **Publication** de la politique de confidentialité mise à jour | Externe | Les fichiers sont à jour dans le dépôt ; leur mise en ligne est une action de publication distincte |
| **Rewarded réel** (chargement, présentation, `onUserEarnedReward`, points d'appel UI) | Code + décision produit | Architecture seule à ce jour (D14) |
| **Share as Image conditionné par un Rewarded** | Code + décision produit | Share as Image est aujourd'hui gratuit et inconditionnel (D4 non activée) |
| **Soutien de l'application** (D5) | Code + décision produit + conformité Play | Totalement absent du code |
| **Validation visuelle sur appareil réel** : bannières, interstitiels, cooldowns, formulaire UMP, In-App Review, build release sous R8 | Validation | Canaux de plateforme non testables en `flutter_test` |

## Anomalie préexistante connue

`test/settings_screen_lot3g_test.dart` — `WorkManagerService.initialDelayForNextFriday` : échec d'exactement 1 h (`Expected 9, Actual 8`), cohérent avec un changement d'offset UTC du fuseau local entre les deux dates du test. Le code concerné est **mort** (conservé uniquement pour ce test) et **sans rapport** avec les lots 5.A → 5.E. **Anomalie préexistante, explicitement hors périmètre du LOT 5.E — ce n'est pas une régression.**
