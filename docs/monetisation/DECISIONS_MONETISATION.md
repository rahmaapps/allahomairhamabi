# Décisions produit — Monétisation & Évaluation

> **Statut : VERROUILLÉES.** Ce document **transcrit** des décisions produit déjà validées. Il ne les interprète pas, ne les complète pas et ne les arbitre pas. Aucune implémentation future, aucune contrainte technique et aucun lot ultérieur ne peut les modifier sans une nouvelle validation produit explicite.
>
> Créé au LOT 5.E. Dernière mise à jour : 2026-09-19.

## Note de traçabilité (à confirmer lors de l'audit produit)

Deux séries distinctes coexistent et ne doivent pas être confondues :

- **Série « Monétisation » — D1 à D15** (LOTS 5.A, 5.B, 5.C) ;
- **Série « Évaluation » — D1 à D7** (LOT 5.D), numérotation indépendante.

La série Monétisation a été validée sous forme d'énoncés, **sans numérotation fournie**. La numérotation D1–D15 ci-dessous suit **l'ordre de transcription** des énoncés validés : aucune décision n'a été ajoutée, retirée ni reformulée, mais **la correspondance numéro ↔ énoncé reste à confirmer par le produit**. Si une numérotation canonique existe par ailleurs, c'est elle qui fait foi ; seuls les numéros devront alors être réalignés, jamais le contenu.

---

## Série Monétisation — D1 à D15

### Principes généraux

| # | Décision (énoncé validé) | Portée | Preuve dans le code |
|---|---|---|---|
| **D1** | Publicité classique **modérée**. | Ensemble de l'app | `lib/monetization/ads_policy.dart` (surfaces restreintes + cooldown) |
| **D2** | Rewarded **volontaire** — jamais imposé à l'utilisateur. | Rewarded | `lib/monetization/reward_service.dart` (aucune présentation automatique) |
| **D3** | **Suppression temporaire** des publicités (contrepartie d'un Rewarded). | Bannières + interstitiels | `AdsFreeStatus`, `UserPrefs.adsSuppressedUntil` |
| **D4** | **Share as Image** pouvant être débloqué par un Rewarded. | Partage Premium | `RewardKind.shareAsImageUnlock`, `AdSurface.shareAsImage` |
| **D5** | **Soutien de l'application sans contrepartie numérique.** | Soutien | *(non implémenté — voir `ETAT_LOTS_5.md`)* |
| **D6** | **Pas de publicité pendant la lecture spirituelle.** | DuaRead, Grave Visit | `AdsPolicy._bannerEligibleSurfaces`, `test/review/review_scope_test.dart` |
| **D7** | **Préserver l'expérience contemplative.** | Principe transverse, prévaut en cas de doute | Ensemble des exclusions D9 / D12 |

### Bannières (LOT 5.B)

| # | Décision (énoncé validé) | Preuve dans le code |
|---|---|---|
| **D8** | Bannières **uniquement** sur : HOME, Recherche, Favoris. | `AdsPolicy._bannerEligibleSurfaces` ; `BannerAdSlot` importé par ces 3 écrans seulement |
| **D9** | **Aucune bannière** sur : DuaRead, Grave Visit, Onboarding, Splash, Paramètres. | `AdsPolicy.isBannerEligible` (liste d'autorisation) + absence d'import |

### Interstitiels (LOT 5.C)

| # | Décision (énoncé validé) | Preuve dans le code |
|---|---|---|
| **D10** | Déclencheurs **uniquement** : Recherche → HOME et Favoris → HOME. | `InterstitialTrigger` (2 valeurs), `AdsPolicy._eligibleInterstitialTriggers` |
| **D11** | **Maximum 1 interstitiel toutes les 10 minutes.** | `AdsPolicy.interstitialCooldown`, `UserPrefs.lastInterstitialShownAt` (persisté) |
| **D12** | **Aucun interstitiel** : au lancement, à l'onboarding, au splash, sur HOME → Recherche/Favoris, dans DuaRead, dans Grave Visit, dans les Paramètres, dans Person Selection, sur « دعاء آخر », à la sortie de l'app. | Liste d'autorisation explicite + `InterstitialTrigger` ne représente aucune de ces transitions |

### Consentement et architecture (LOT 5.A)

| # | Décision (énoncé validé) | Preuve dans le code |
|---|---|---|
| **D13** | Consentement géré par **Google UMP**. `canRequestAds()` est **l'unique porte** avant toute requête publicitaire — jamais un booléen local « l'utilisateur a accepté ». | `ConsentService`, `AdsAvailability`, `GoogleUmpConsentService` |
| **D14** | Rewarded : **architecture seulement**. Aucune publicité Rewarded réelle tant qu'un lot ne l'active pas explicitement. | `RewardService` (abstraction) + `NoopRewardService` ; aucun `RewardedAd` dans le projet |
| **D15** | Suppression temporaire = **1 heure**, accordée **uniquement** sur `onUserEarnedReward` effectivement déclenché (jamais sur une simple fermeture de l'annonce). | `RewardEffects.adRemovalDuration`, contrat de `RewardService.requestReward` |

---

## Série Évaluation — D1 à D7 (LOT 5.D)

Numérotation **indépendante** de la série Monétisation.

| # | Décision (énoncé validé) | Preuve dans le code |
|---|---|---|
| **D1** | Déclencheur unique : **retour Favoris → HOME**. | `ReviewTrigger` (1 seule valeur), `ReviewPolicy._eligibleTriggers` |
| **D2** | **Aucun compteur d'usage** : ni ouvertures, ni sessions, ni douʿās consultés. Seules deux dates sont persistées. | `UserPrefs` : `first_open_at`, `last_review_prompted_at` |
| **D3** | Ancienneté de l'application **≥ 7 jours**. | `ReviewPolicy.minimumAppAge` |
| **D4** | Cooldown de **90 jours** entre deux sollicitations. | `ReviewPolicy.promptCooldown` |
| **D5** | **Refus ou fermeture = même cooldown** de 90 jours. | `ReviewPromptController` : cooldown consommé dès l'émission |
| **D6** | **Exclusions strictes** : jamais pendant ni immédiatement autour d'une publicité plein écran, ni sur les transitions exclues (lancement, onboarding, DuaRead, Grave Visit, Recherche → HOME, Paramètres…). | `AdActivityProbe`, `interstitialAdActivityProbe`, `test/review/review_scope_test.dart` |
| **D7** | **Google Play In-App Review via une abstraction**, aucune sollicitation bloquante, aucune exception propagée. | `ReviewAvailability`, `InAppReviewAvailability` |

---

## Ce que ce document n'est pas

- Il ne décrit **pas** l'état d'implémentation : voir [`ETAT_LOTS_5.md`](ETAT_LOTS_5.md).
- Il ne contient **aucune** décision nouvelle prise par un lot technique.
- Il ne contient **aucun** identifiant, secret, clé ou paramètre de compte.
