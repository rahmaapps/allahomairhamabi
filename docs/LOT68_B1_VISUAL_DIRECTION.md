# LOT 68-B.1 — Direction visuelle et structure du nouveau site

> **Nature :** document d'analyse et de proposition. **Aucune implémentation** : aucun HTML, CSS, JS, asset ni capture n'est créé ou modifié par ce lot.
> **Date :** 25 septembre 2026
> **Référence fonctionnelle :** code de l'application sur `github-migration` @ `46fb8ff` (lu en lecture seule via `git show`, sans changer de branche)
> **Site actuel :** `site/` (identique à la production, publié par `.github/workflows/deploy-site.yml`)

**Légende des statuts (obligatoire pour chaque proposition importante) :**

| Statut | Signification |
|---|---|
| ✅ **DÉCISION EXISTANTE** | Déjà validée dans le projet (doc verrouillée ou code publié). Citée avec sa source. |
| 💡 **PROPOSITION** | Nouvelle proposition de design ou d'UX. **Nécessite validation.** |
| ⏳ **À CONFIRMER** | Fait ou état à vérifier, ou décision produit non tranchée. |

---

### DÉCISIONS VALIDÉES — LOT 68-B.1

> ✅ **Validées par Hamza le 25/09/2026.** Ces décisions sont désormais des **décisions existantes** du projet. Elles **prévalent sur toute formulation antérieure** de ce document, et les passages contradictoires ont été alignés.

| # | Sujet | Décision validée |
|---|---|---|
| 1 | **Éditeur** | `Rahma Applications` (identique à la fiche Google Play) |
| 2 | **H1 et sous-titre** | H1 : `اللَّهُمَّ ارْحَمْ أَبِي` · Sous-titre : `أدعية مختارة لوالدك ووالدتك ولكل من تحب` |
| 3 | **Section Grave Visit** | **OUI**, section `عند زيارة القبر`. Présentation sobre et factuelle. **Ne pas** mentionner de source affichée, **ne pas** mentionner l'insertion du prénom, **ne pas** prétendre qu'il y a plusieurs douʿās sur cet écran. |
| 4 | **Transparence publicité** | **OUI**. Bloc `بوضوح`, texte exact ci-dessous. **Jamais** `100% بدون إعلانات`. |
| 5 | **Captures** | **OUI**, captures propres **sans publicité visible**. La publicité est expliquée **par le texte**. Les **3 images réellement générées** par Share as Image sont montrées. **L'annonce elle-même n'est jamais capturée.** |
| 6 | **Données fictives** | Prénom : `محمد` · Rappel du matin : `07:30` |
| 7 | **Langue** | Landing page **arabe uniquement** pour B.3, **RTL**, **pas de sélecteur FR/EN**. La politique **FR reste accessible depuis le footer**. |

**Texte validé du bloc `بوضوح` :**

> **مجاني، مع إعلانات محدودة.**
> - إعلانات محدودة في بعض أقسام التطبيق.
> - لا إعلانات أثناء قراءة الدعاء أو في صفحة زيارة القبر.
> - بعض الميزات، مثل مشاركة الدعاء كصورة، قد تتطلب إعلانًا اختياريًا.
> - مشاركة الدعاء كنص مجانية دائمًا.
> - لا حساب ولا تسجيل، وتُحفظ اختياراتك ومفضلاتك على جهازك.

**Formulation validée des rappels (site) :** `صباحًا في الوقت الذي تختاره، ومساءً، ويوم الجمعة إن أردت`. **Aucun horaire n'est cité dans le texte** de la landing page. La capture C6 montre, elle, les trois horaires configurés (07:30 / 20:00 / 09:00).

**Architecture verrouillée :**
1. En-tête
2. Hero
3. لمن تدعو؟
4. كل يوم
5. عند زيارة القبر
6. تذكير
7. شارك الأجر
8. بوضوح
9. CTA Google Play
10. Footer

Le détail est au §28.

**Captures B.2 verrouillées :**
- C1 Home ;
- C2 Choix des proches ;
- C3 Lecture avec `محمد` ;
- C4 Recherche ;
- C5 Grave Visit ;
- C6 Paramètres / rappels ;
- E1–E3 : trois images Share as Image, **présentables comme une seule fonctionnalité** sur le site.

Le détail est au §29.

ℹ️ **Note factuelle (consignée, non bloquante) :** dans l'app, le HOME affiche aussi un douʿā **et** porte une bannière. Dans le texte validé, « أثناء قراءة الدعاء » renvoie à l'écran de lecture (ouvert depuis la Recherche ou les Favoris), qui n'a aucune publicité (D6, D9). Formulation retenue telle que validée.

### CORRECTIONS FACTUELLES — alignement sur le code réel (avant capture B.2)

Constats issus du protocole `docs/LOT68_B2_CAPTURE_PROTOCOL.md` (code `github-migration` @ `46fb8ff`). **Aucune décision validée n'est modifiée.**

| # | Sujet | Fait établi | Application dans ce document |
|---|---|---|---|
| F1 | Sélection des personnes | L'écran `تدعو لـ` liste les 11 relations (puce + champ `الاسم (اختياري)` quand la relation est cochée). Aucune notion de « proche courant » n'est affichée (décision produit antérieure). | C2 décrit uniquement les proches cochés |
| F2 | C1 / C2 | Avec plusieurs proches cochés, le HOME affiche `تدعو لـ N أشخاص`. | **C1 : أبي seul** (personnalisation `محمد` visible) · **C2 : plusieurs proches** (capacité multi-profils) |
| F3 | Personnalisation | Le prénom est inséré par le **HOME**. `DuaReadScreen` n'insère pas le prénom ; il affiche le texte **sauvegardé lors de l'ajout en favori depuis le HOME**. | C3 obtenu par la séquence : أبي → saisie `محمد` → douʿā personnalisé sur le HOME → ♡ → ouverture depuis Favoris |
| F4 | C1 / C3 | Même douʿā pour la continuité : **id 3**. | Texte exact : `اللهم اجعل قبر أبي محمد روضةً من رياض الجنة، وانر دربه بنور هدايتك يا كريم يا رحيم.` |
| F5 | Recherche | `الجنة` donne **292 résultats** sur le corpus complet (aucun compteur affiché dans l'UI). | Donnée **technique de capture uniquement**. Jamais un argument ni un visuel du site. |
| F6 | Rappels | Les **trois** rappels (matin, soir, vendredi) ont une heure **configurable** (défauts 09:00 / 20:00 / 09:00, vendredi désactivé par défaut). | C6 : **07:30 / 20:00 / 09:00**, les trois visibles. Site : formulation générique validée, sans horaire. |
| F7 | Share as Image | Noms visibles dans l'app : **`Dark Luxe`**, **`Emerald`**, **`White`**. | Seuls ces noms sont utilisés pour désigner les modèles. Aucun nom arabe inventé. E1/E2/E3 = les trois exports réels. |
| F8 | Grave Visit | Aucune source affichée, aucune insertion automatique du prénom. | Présentation sobre et factuelle (décision 3) |

---

## 1. Objectif

Définir **ce que le nouveau site raconte, à qui, dans quel ordre, avec quelle identité visuelle et quelles captures réelles**. Un développeur doit pouvoir implémenter le LOT 68-B.3 sans réinventer le produit. Le LOT 68-B.2 doit pouvoir produire les captures sans ambiguïté.

---

## 2. Sources analysées

| Source | Usage |
|---|---|
| `docs/LOT68_AUDIT_SITE.md` (68-A) | Constats sur le site actuel : contenu, visuel, responsive, SEO, privacy |
| `docs/LOT68_B0_ARCHITECTURE_SITE.md` (68-B.0) | URL critiques, `app-ads.txt`, contraintes Pages |
| `docs/LOT68_B01_MIGRATION_SITE.md` (68-B.0.1) | Architecture actuelle : `site/` + workflow Actions |
| `docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md` (`github-migration`) | **Source de vérité UI/UX** : navigation, HOME, Design System Phase 2 (tokens, typo, rayons, ombres, RTL, responsive), specs de chaque écran |
| `docs/ui_ux/LOT_66_REVUE_UX_UI.md`, `LOT_3I_DUAREADSCREEN_SPEC.md` | Revue UX récente, écran de lecture |
| `docs/monetisation/DECISIONS_MONETISATION.md`, `ETAT_LOTS_5.md` | Décisions verrouillées Pub / Rewarded / Évaluation (D1–D15, D1–D7) |
| `docs/V1.2_PROGRESS.md` | Décisions produit V1.2 (Ramadan, Share as Image, IDs) |
| Code Flutter (`github-migration`) | `home_screen.dart`, `settings_screen.dart`, `notification_service.dart`, `dua_personalizer.dart`, `models/person_type.dart`, `monetization/share_as_image_flow.dart`, `monetization/rewarded_wording.dart`, `theme/app_colors.dart`, `theme/app_typography.dart`, `assets/data/duas.json` |
| Fiche Google Play publique | Titre `اللهم ارحم أبي \| دعاء للميت`, éditeur « Rahma Applications », URL de politique déclarée |

⚠️ **Réserve de méthode :** les documents de phase du Design System (`DESIGN_SYSTEM_PHASE2_SPEC.md`, `PHASE3x`…) sont **externes au dépôt** (constat écrit dans `ETAT_CONSOLIDE_UI_UX.md` §0). Ce document s'appuie donc sur leur transcription consolidée et sur le code.

⏳ **Roadmap :** aucune roadmap produit formelle n'existe dans le dépôt, en dehors des sections « éléments ouverts » de `ETAT_CONSOLIDE_UI_UX.md` §7 et §9.D et des « hors périmètre » de `ETAT_LOTS_5.md`. Ce document n'anticipe **aucune** fonctionnalité future.

---

## 3. État actuel du site

Résumé de 68-A, toujours valable puisque le contenu de `site/` n'a pas changé :

- **Page unique, arabe RTL** : logo, H1, accroche centrée sur « ton père », CTA Google Play en **`href="#"`**, liste plate de **15 fonctionnalités avec emojis**, 3 **mockups obsolètes**, lien politique AR, footer minimal.
- **Affirmations fausses** : `تجربة نقية 100% بدون إعلانات` ; partage « عبر واتساب » (intégration supprimée) ; titre « … تجعل **موقعنا** … ».
- **Mockups** montrant l'ancienne UI : chip `دعاء رمضان`, bouton WhatsApp, interrupteurs violets, rappel `بعد الظهر`, bouton `حفظ`, sous-titre « SETTING ».
- **Visuel** déconnecté de l'app : fond vert sombre uniforme, police `Noto Kufi Arabic` déclarée mais jamais chargée, emojis.
- **Mobile** : 4 050 px de hauteur à 375 px de large ; CTA coupé en « Google / Play ».
- **SEO / partage** : aucune meta description, canonical, Open Graph ni favicon.

---

## 4. Positionnement proposé

✅ **DÉCISION EXISTANTE — vocation :** l'app accompagne l'utilisateur dans le **douʿā pour ses défunts proches**. Ce n'est pas une bibliothèque générique. Preuves : le modèle est organisé par personne (`PersonType`, 11 relations) ; le texte de partage de l'app dit `تطبيق أدعية لوالدي الميت 🤍` ; la notification dit `لا تنسَ الدعاء لموتانا الأعزاء`.

✅ **Positionnement validé** :

> **اللَّهُمَّ ارْحَمْ أَبِي**
> أدعية مختارة لوالدك ووالدتك ولكل من تحب.

✅ **Validé** (décision 2) : H1 et sous-titre ci-dessus.

Registre : **personnel, familial, mémoriel, spirituel, simple, respectueux**.
- Pas de superlatifs (« الأفضل », « 100% ») ni d'emojis dans les titres.
- Pas de ton de vente.
- Le site parle comme l'app : phrases courtes et apaisées.

✅ **Tranché (décisions 1 et 2, détail §27.1)** — historique du constat : la fiche Play affiche `اللهم ارحم أبي | دعاء للميت`. L'app affiche `اللَّهُمَّ ارْحَمْ أَبِي` (avec tashkīl). Le brief du lot écrit `اللهم ارحم أبي – أدعية لوالدي الميت`. Il faut **une** forme canonique pour le H1, le `<title>` et l'Open Graph.

---

## 5. Public cible

💡 **PROPOSITION** (déduite du produit, sans donnée d'audience disponible) :

1. **Cœur :** musulman·e arabophone ayant perdu un parent (père ou mère), qui veut une pratique régulière et simple du douʿā.
2. **Élargi :** toute personne endeuillée d'un proche : grand-parent, frère ou sœur, enfant, conjoint·e (les 11 relations de l'app).
3. **Moment clé :** avant ou pendant une visite au cimetière (`دعاء زيارة القبر`).
4. **Relais :** personne qui partage un douʿā ou l'app à sa famille (partage texte ou image, `مشاركة التطبيق`).

Contexte d'arrivée probable : **mobile**, depuis un lien partagé (WhatsApp, réseaux) ou depuis `عن التطبيق` dans l'app. D'où l'approche **mobile-first** et l'importance de l'**Open Graph**.

ℹ️ Périmètre linguistique tranché pour B.3 : landing page arabe uniquement (décision 7). Toute ouverture FR/EN ultérieure fera l'objet d'une décision séparée.

---

## 6. Principes UX

| # | Principe | Statut |
|---|---|---|
| P1 | **Vérité produit** : ne montrer que ce qui existe dans l'app actuelle, captures réelles uniquement. | ✅ Exigence du lot et de 68-A |
| P2 | **Le douʿā est le héros** : comme dans l'app, un seul élément « sacré » par écran porte les privilèges visuels (carte blanche, filet d'or, Lateef). | ✅ Transposé du HOME (§2 « 6 privilèges exclusifs ») |
| P3 | **Sobriété contemplative** : pas d'animations décoratives, pas de compte à rebours, pas de pop-up. | ✅ D7 « Préserver l'expérience contemplative » ; interdits de §3 (aucun dialogue promotionnel) |
| P4 | **Un seul CTA principal** : Google Play. Répété au plus deux fois (hero et fin de page). | 💡 Transposé de la règle « un seul Primary visible par écran » |
| P5 | **Transparence** sur la publicité et les données, dans un bloc court et factuel. | 💡 |
| P6 | **Mobile-first, lecture courte** : chaque section tient en environ un écran mobile. | 💡 |
| P7 | **Arabic-first, RTL natif** : aucun texte arabe dans des images. | ✅ Règles RTL §3 ; 💡 pour « aucun texte dans les images » |

---

## 7. Architecture de la page

✅ **Architecture verrouillée** (décisions validées) ; détail au §28 :

```
1. En-tête ─────────── bande verte (AppBar) : icône · اللَّهُمَّ ارْحَمْ أَبِي
2. Hero ────────────── H1 + sous-titre + CTA Google Play + capture HOME
3. لمن تدعو؟ ───────── 11 proches + prénom inséré dans le douʿā
4. كل يوم ──────────── lire · دعاء آخر · عام / الجمعة · حفظ · بحث
5. عند زيارة القبر ─── Grave Visit
6. تذكير ───────────── matin / soir / vendredi
7. شارك الأجر ──────── partage texte + partage en image (3 modèles)
8. بوضوح ───────────── bloc transparence validé
9. CTA Google Play
10. Footer ─────────── politique AR · politique FR · contact · Rahma Applications · ©
```

Pas de menu de navigation ni de sélecteur de langue (page courte, arabe uniquement). Voir le §15.

---

## 8. Section par section

### 8.1 Hero

- **Message principal (H1)** : le nom de l'app en **Lateef**, `اللَّهُمَّ ارْحَمْ أَبِي`. ✅ Validé (décision 2).
- **Sous-titre (Plex)** : `أدعية مختارة لوالدك ووالدتك ولكل من تحب`. ✅ Validé (décision 2).
- **Micro-ligne factuelle** : `مجاني · لأجهزة Android`. 💡 Android seul est un fait (iOS non publié ; `CFBundleDisplayName` = `Test 1`).
- **CTA** : badge officiel Google Play (§17). ✅ URL existante.
- **Visuel** : **capture réelle du HOME**. Sur desktop, à côté du texte ; sur mobile, sous le CTA et partiellement visible au premier écran pour inviter au défilement. 💡
- **Rôle de l'arabe** : exclusif, sur toute la page. ✅ Validé (décision 7) : aucune traduction, aucun sélecteur de langue.

### 8.2 « لمن تدعو؟ » — profils des proches

✅ **Faits (code) :**
- **11 relations** (`PersonType`) : أبي، أمي، والديّ، جدي، جدتي، أخي، أختي، ابني، ابنتي، زوجي، زوجتي ;
- **multi-sélection** ;
- **prénom optionnel**, **inséré dans le texte du douʿā affiché sur le HOME** (`DuaPersonalizer` : « والدي » devient « أبي محمد ») ; le texte personnalisé est conservé lorsqu'on ajoute le douʿā aux favoris depuis le HOME (F3) ;
- choix accessible dès l'onboarding (`لمن تدعو؟`) puis depuis la ligne « pour qui » du HOME (`تدعو لـ … · تغيير`).

💡 **PROPOSITION de présentation :**
- Titre `لمن تدعو؟`, repris tel quel de l'app (continuité de vocabulaire).
- Les 11 relations en **rangée de chips non interactives**, style chip « personne » de l'app : trait fin, `primaryContainer` pour 2 ou 3 chips « cochées » à titre d'exemple. Pas de liste à puces, pas de cartes.
- Une phrase : « اختر من تدعو له، وأضف اسمه إن شئت ليظهر في الدعاء. »
- Capture : écran de sélection des personnes.

Objectif : faire comprendre en 3 secondes que l'app **ne se limite pas au père**, sans liste longue.

### 8.3 « كل يوم » — expérience principale

⚠️ **Le schéma d'exemple du brief (« Lire / écouter / enregistrer ») ne correspond pas à l'app.** Il n'existe **ni audio ni enregistrement** dans le code. « Enregistrer » ne peut désigner que les **favoris**.

✅ **Faits (code et spec HOME) :**
- carte du douʿā ;
- `دعاء آخر` pour un nouveau douʿā ;
- 2 catégories : `عام` et `دعاء الجمعة` ;
- ♡ favori ;
- `نسخ` / `مشاركة` ;
- recherche plein texte ;
- écran de lecture agrandi depuis Recherche et Favoris ;
- thème clair, sombre ou automatique.

💡 **PROPOSITION — parcours en 3 temps** (fidèle à l'app) :

```
اختر من تدعو له   →   اقرأ الدعاء   →   احفظه أو شاركه
(personnes)           (carte · دعاء آخر ·      (♡ · نسخ · مشاركة)
                       عام / الجمعة)
```

Puis une rangée compacte de 2 ou 3 atouts, avec des icônes au trait cohérentes avec les icônes Material de l'app (`search`, `favorite_border`), sans emoji :
- **البحث** : trouver un douʿā en quelques lettres.
- **المفضلة** : retrouver ses douʿās en un geste.
- **أدعية يوم الجمعة** : un onglet dédié.

Captures : C1 HOME (déjà dans le hero, réutilisable), **C3 écran de lecture**, **C4 Recherche**. Pas de capture Favoris (liste verrouillée du §29).

### 8.4 « عند زيارة القبر » — Grave Visit

✅ **Faits :**
- **disponible et accessible** dans la version actuelle : bandeau `دعاء زيارة القبر · للقراءة عند الزيارة` sous l'AppBar du HOME ;
- choix de la personne, puis écran plein de **lecture seule** ;
- **aucune action** : ni copie, ni partage, ni favori ;
- **aucune publicité** (D6, D9) ;
- texte religieux enrichi au LOT 67.

✅ **Validé (décision 3)** : section `عند زيارة القبر`, sobre et factuelle.
- Section plus aérée que les autres (respiration visuelle) 💡 ;
- texte : voir §27.2 (formulation unique) ;
- une capture de l'écran de lecture (C5).

Pas d'illustration de cimetière et pas d'imagerie funèbre. Seule la carte du douʿā compte.

Interdits validés : ne pas mentionner de **source affichée**, ne pas mentionner l'**insertion du prénom**, ne pas prétendre qu'il y a **plusieurs douʿās** sur cet écran. Faits au §27.2.

### 8.5 « تذكير » — notifications

✅ **Faits (code, à ne pas confondre) :**

| Niveau | Réalité |
|---|---|
| Rappels **de l'app** | 3 rappels, **tous à heure configurable** : `تذكير الصباح` (défaut 09:00, activé), `تذكير المساء` (défaut 20:00, activé), `تذكير الجمعة` (défaut 09:00, désactivé) |
| Contenu | Textes fixes, par exemple `🌅 صباح الرحمة` / `🤲 لا تنسَ الدعاء لموتانا الأعزاء في بداية يومك`, avec les actions `فتح` / `تجاهل`. **La notification ne contient pas le texte d'un douʿā.** |
| Permission Android | Demandée à l'onboarding (`تذكير يومي؟`). En cas de refus, une ligne d'information, sans relance. |

✅ **Formulation validée** : `صباحًا في الوقت الذي تختاره، ومساءً، ويوم الجمعة إن أردت`.
- **Aucun horaire n'est cité** dans le texte de la landing page (la capture C6 montre 07:30 / 20:00 / 09:00).
- Ne jamais écrire que la notification « contient un douʿā ».
- Capture : section `التذكير` des Paramètres, **pas** le volet de notifications Android (UI système, variable selon le constructeur).

### 8.6 « شارك الأجر » — partage et Share as Image

✅ **Faits (code, LOT 5.G.B) :**
- **Partage texte** (`نسخ` / `مشاركة`) : **toujours gratuit**, feuille de partage native.
- **Partage en image** : icône `⤴` du HOME, feuille avec **3 modèles** nommés dans l'app **`Dark Luxe`**, **`Emerald`**, **`White`** (F7), image PNG remise au partage natif.
  - **1 annonce avec récompense = 1 partage**, précédée d'une confirmation (`سيتم عرض إعلان قصير الآن`) ;
  - **gratuit sans annonce** si une heure sans publicité est active ;
  - **gratuit sans annonce** si l'annonce est indisponible (hors ligne, consentement, échec).
- `مشاركة التطبيق` : ligne dans les Paramètres.

💡 **PROPOSITION :**
- Montrer **les 3 images réellement exportées** (pas des maquettes) côte à côte, à poids égal. Même règle que dans l'app : aucun modèle n'est mis en avant.
- Texte : « شارك الدعاء نصًّا، أو كصورة جميلة بأحد ثلاثة تصاميم. »
- Mention de l'annonce facultative : **uniquement via le bloc `بوضوح` validé** (« بعض الميزات، مثل مشاركة الدعاء كصورة، قد تتطلب إعلانًا اختياريًا. »), sans seconde formulation. Les 3 images (E1–E3) sont présentées **comme une seule fonctionnalité**.

### 8.7 « بوضوح » — transparence (voir §19)

### 8.8 CTA final et footer (voir §17 et §18)

---

## 9. Fonctionnalités à mettre en avant

| Fonctionnalité | Intérêt utilisateur | Section | Statut |
|---|---|---|---|
| Choix du ou des proches (11) + prénom dans le douʿā | Personnel, dépasse « le père » | 3 | ✅ fait · 💡 présentation |
| Carte du douʿā + `دعاء آخر` | Cœur de l'usage quotidien | 2 et 4 | ✅ · 💡 |
| `دعاء الجمعة` | Moment spirituel hebdomadaire | 4 | ✅ · 💡 |
| Favoris + Recherche | Retrouver | 4 | ✅ · 💡 |
| `دعاء زيارة القبر` | Moment unique, différenciant | 5 | ✅ fait · ✅ section validée (décision 3) |
| Rappels matin / soir / vendredi | Régularité | 6 | ✅ · 💡 |
| Partage texte + image (3 modèles) | Transmettre, « شارك الأجر » | 7 | ✅ · 💡 |
| Thème clair / sombre | Confort | 4 (mention d'une ligne) | ✅ · 💡 |
| Contenu utilisable hors ligne | Fiabilité | 4 (mention d'une ligne, facultative) | ✅ contenu embarqué · 💡 formulation « الأدعية متاحة دون إنترنت » (les publicités, elles, utilisent le réseau). **Pas dans le bloc `بوضوح`**, dont le texte validé est fixe. |

---

## 10. Fonctionnalités à ne pas mettre en avant

| Élément | Raison | Statut |
|---|---|---|
| **Ramadan** | 374 douʿās présents, **aucune entrée UI dédiée** (atteignables seulement par la Recherche). Décision V1.2 : « bouton Home non ajouté ». `ETAT_CONSOLIDE` §7 : hors périmètre, non tranché. | ✅ Aucune section. 💡 Aucune mention non plus : une mention discrète promettrait un accès que l'UI n'offre pas. |
| Nombre total de douʿās (« 2215 ») | Compteur technique : les mêmes textes sont déclinés par personne (≈ 200 par personne + 15 généraux), et il inclut le Ramadan non exposé. L'afficher serait trompeur. | 💡 Ne pas afficher de chiffre. ⏳ Si un chiffre est voulu, le définir avec le produit. |
| Heure sans publicité (Rewarded) | Mécanique publicitaire, pas un bénéfice spirituel | 💡 Mention dans le bloc transparence seulement |
| In-App Review | Mécanique interne | ✅ Jamais présenté (D7 Évaluation) |
| Consentement UMP / `خيارات الخصوصية` | Conformité | 💡 Couvert par la politique, lien en footer |
| Mode paysage, tablette | Détail technique | 💡 Non présenté |
| Audio, enregistrement, compte, synchronisation | **N'existent pas** | ✅ Ne jamais évoquer |

---

## 11. Screenshots nécessaires

✅ **Remplacé par la liste verrouillée du §29** : 6 captures (C1–C6) et 3 exports (E1–E3). Les règles sur la publicité dans les captures sont au §27.4 (décision 5 : aucune publicité visible, annonce jamais capturée).

---

## 12. Direction visuelle

✅ **Base** : Design System Phase 2 de l'app (`ETAT_CONSOLIDE_UI_UX.md` §3, `lib/theme/*`). Le site doit **ressembler à l'app**.

💡 **PROPOSITION — transposition web :**

| Aspect | Direction | Source |
|---|---|---|
| **Ambiance** | Fond crème, surfaces blanches, vert profond pour l'identité, or réservé aux filets. Sobriété : beaucoup d'air, peu d'éléments par écran. | ✅ tokens ; 💡 dosage |
| **En-tête** | Bande `primary #006A4E` rappelant l'AppBar, titre Lateef ivoire `#FFFBF1`. **Aucune ombre, aucun filet d'or** (règle AppBar). | ✅ |
| **Fond de page** | `bg #FFFBF1` (clair). En sombre, `#101A16`, jamais noir. | ✅ |
| **Élément « sacré »** | **Un seul par section au plus** : carte blanche, `r-hero 24`, ombre `e2`, **filet d'or 2 px** en tête, texte Lateef. Utilisé pour la citation d'un douʿā dans le hero et pour les captures. | ✅ privilèges de la carte N1 ; 💡 transposition |
| **Cartes secondaires** | `surface` + trait `border #EADFC8`, `r-card 16`, `e0`/`e1`. Jamais le filet d'or. | ✅ |
| **Rayons** | 8 (champs) · 12 (boutons) · 16 (cartes) · 24 (hero, captures) · pill (chips) | ✅ |
| **Ombres** | Teintées vert `rgba(0,58,42,α)` : `e1 0 1px 3px/.07`, `e2 0 6px 20px/.10`. **Jamais grises.** | ✅ |
| **Espacements** | Base 4 : `4 · 8 · 12 · 16 · 20 · 24 · 32 · 40`. Marge latérale mobile **20**. Pour le web, 💡 ajouter `64` et `96` (grands intervalles de section desktop, absents de l'app). | ✅ ; 💡 extension |
| **Densité** | Faible : 1 idée par section, 1 à 3 phrases, 0 ou 1 capture. | 💡 |
| **Captures** | Capture nue (sans cadre de téléphone), coins `r 24`, ombre `e2`, trait `border` 1 px. Pas de cadre d'appareil ni d'inclinaison 3D. | 💡 (règle « pas de décor ») |
| **CTA** | Badge Google Play officiel. Éventuel bouton texte secondaire (`secondary` : trait 1,5 `primary`). Hauteur ≥ 48, rayon 12. Survol et focus : `primaryPressed`, **pas d'ondulation**. | ✅ boutons ; 💡 |
| **Icônes** | Au trait, jeu cohérent avec Material Icons (déjà utilisées dans l'app). **Aucun emoji** dans les titres ni les listes. | 💡 |
| **Séparateurs** | Filet `border` 1 px, ou **filet d'or** court (48 px, centré) uniquement devant un contenu sacré. | 💡 |
| **Motif** | Rosace / mashrabiya de l'app (`islamic_bg_motif_painter.dart`, `mashrabiya_painter.dart`) en **filigrane très léger** (≤ 5,5 %, comme dans la carte) dans le hero **uniquement**. Jamais animé. | ✅ « rosace jamais animée » ; 💡 usage web |
| **Animations** | Aucune animation décorative. Au plus un fondu d'apparition ≤ 240 ms, désactivé si `prefers-reduced-motion`. | ✅ grammaire du mouvement ; 💡 |

---

## 13. Typographies

✅ **DÉCISION EXISTANTE (app)** — « 2 polices, jamais 3 » :
- **Lateef** : **uniquement** le texte du douʿā, le titre de l'app, la phrase d'accroche des états vides et les heures ;
- **IBM Plex Sans Arabic** : tout le reste (400 / 500 / 600).

💡 **PROPOSITION — application au site :**

| Rôle web | Police | Taille mobile → desktop | Interligne |
|---|---|---|---|
| Nom de l'app (H1) | Lateef 400 | 40 → 56 px | 1.35 |
| Citation de douʿā (hero, sections) | Lateef 400 | 26 → 30 px | **≥ 2.0** (non négociable) |
| Titres de section (H2) | Plex 600 | 22 → 28 px | 1.5 |
| Texte courant | Plex 400 | 16 → 17 px | 1.75 |
| Libellés, chips, footer | Plex 500 | 13 → 14 px | 1.4 |

- ❌ **Ne pas reprendre `Noto Kufi Arabic`** : non utilisée par l'app, jamais chargée par le site actuel.
- `letter-spacing: 0`, aucun italique, aucune capitale forcée (règles arabes de l'app).
- Chiffres **occidentaux 0-9** dans l'interface (✅ règle verrouillée), sauf dans les textes religieux.
- 💡 **Polices auto-hébergées** (WOFF2 dérivés des `.ttf` déjà embarqués dans `assets/fonts/`), plutôt que Google Fonts. Cela évite une requête tierce et rejoint la politique « aucun tracker » ; les licences OFL le permettent (⏳ à vérifier). `font-display: swap`, préchargement de Plex 400 et Lateef 400.

---

## 14. Couleurs

✅ **Palette = tokens de l'app, sans ajout.**

| Token | Clair | Sombre | Usage web |
|---|---|---|---|
| `bg` | `#FFFBF1` | `#101A16` | Fond de page |
| `surface` | `#FFFFFF` | `#18241F` | Cartes, captures |
| `surfaceAlt` | `#FFF6E7` | `#20302A` | Bloc transparence, footer |
| `primary` | `#006A4E` | `#009F6B` | En-tête, liens, focus |
| `primaryPressed` | `#00563F` | — | Survol et appui |
| `primaryContainer` | `#E4F0EA` | — | Chips « cochées » (section 2) |
| `onPrimary` | `#FFFBF1` | `#062018` | Texte sur vert (**ivoire, jamais blanc pur**) |
| `goldText` / `gold` | `#8A6508` | `#E3C570` | Petits titres or (avec parcimonie) |
| `goldLine` | `#D4AF37` | — | Filets 1–2 px (sacré uniquement) |
| `textPrimary` | `#1E2A24` | `#F3EEE1` | Texte |
| `textSecondary` | `#5C6B63` | `#A6B2AA` | Texte secondaire |
| `border` | `#EADFC8` | `#2C3C35` | Traits |

- ❌ Abandon du fond `#063F1D`, du texte `#FCEECB` et du lien `#B8F3C2` du site actuel : absents du Design System.
- ✅ Contrastes vérifiés côté app : `primary` 8,4:1, `textPrimary` 13,9:1, `goldText` 5,1:1. Le **`goldLine` ne porte jamais de texte**.
- 💡 **Mode sombre du site** via `prefers-color-scheme`, avec les tokens sombres. ⏳ Optionnel : clair seul acceptable pour une première version.

---

## 15. Responsive / mobile

💡 **PROPOSITION :**

| Élément | Mobile (≤ 599 px) | Tablette (600–1023) | Desktop (≥ 1024) |
|---|---|---|---|
| Marge latérale | **20 px** (✅ marge unique de l'app) | 32 px | Auto (conteneur centré) |
| Colonne de texte | Pleine largeur | Max **480 px** (✅ plafond HOME de l'app : « on n'étire jamais la ligne arabe ») | Max 480 px |
| Conteneur global | — | — | Max **1040 px** |
| Hero | Texte → CTA → capture (partiellement visible au premier écran) | Idem, capture plus grande | **2 colonnes** : texte à droite (RTL), capture à gauche |
| Sections avec capture | Empilées : titre → texte → capture | Idem | 2 colonnes **alternées** (miroir RTL) |
| Captures | Largeur ~ 260 px, centrées | ~ 300 px | ~ 320 px ; `srcset` 1x/2x, WebP, `loading="lazy"` hors hero |
| Modèles de partage (3) | **3 de front** même à 320 px (✅ règle de la feuille de partage), vignettes ~ 96 px | ~ 140 px | ~ 180 px |
| Chips des 11 proches | Retour à la ligne, centrées | Idem | Idem |
| CTA | Badge ≥ 48 px de haut, **jamais coupé sur deux lignes** | Idem | Idem |
| Navigation | **Aucune** : page courte. Seul l'en-tête porte l'icône, le nom et un mini-CTA. | Idem | Idem |
| Footer | Liens empilés | En ligne | En ligne |

- **Cible basse 320 px** (✅ même cible que l'app, 320 × 568) : rien ne doit y être tronqué.
- **Budget de longueur** 💡 : environ **6 à 7 hauteurs d'écran** à 375 × 812, soit environ 5 000 px au maximum en comptant les captures, pour 8 sections. C'est à peine plus long qu'aujourd'hui (4 050 px) pour une information bien plus complète. Le budget s'appuie sur la liste verrouillée du §29 (6 captures + 3 exports présentés comme une seule fonctionnalité). ⏳ Budget à valider sur maquette.
- Zones tactiles ≥ 48 × 48 (✅). Focus visible (trait `primary` 2 px).

---

## 16. SEO

💡 **PROPOSITION**, à implémenter au LOT 68-B.3 :

| Élément | Recommandation |
|---|---|
| `<html>` | `lang="ar" dir="rtl"` (✅ déjà correct) |
| `<title>` | Identique au nom Google Play : `اللهم ارحم أبي \| دعاء للميت` (voir §27.1) |
| `meta description` | 140–160 caractères, factuelle, sans « 100% » ni superlatif |
| `canonical` | `https://rahmaapps.github.io/allahomairhamabi/` (avec slash final) |
| Open Graph | `og:type=website`, `og:locale=ar_AR`, `og:title`, `og:description`, `og:url`, `og:image` (**1200×630**, URL absolue), `og:image:alt` en arabe, `og:site_name` |
| X / Twitter | `twitter:card=summary_large_image` (mêmes titre, description et image) |
| Favicon | `favicon.ico` 32 + PNG 192/512 + `apple-touch-icon` 180, dérivés de `assets/icon/app_icon.png` et du SVG. ⚠️ L'icône a un **défaut connu sous 32 px** (pouces hauts, `ETAT_CONSOLIDE` §7) : prévoir une version simplifiée pour 16/32 px (⏳ Claude Design). |
| `theme-color` | `#006A4E` (clair) / `#0C1512` (sombre, `appBar`) |
| Données structurées | JSON-LD `MobileApplication` : `name`, `operatingSystem: ANDROID`, `applicationCategory` (⏳ à choisir, par exemple `LifestyleApplication`), `offers.price: 0`, `url` Play, `publisher: Rahma Applications` (décision 1). **Pas d'`aggregateRating`** sans source vérifiable. |
| `robots.txt` / `sitemap.xml` | ⚠️ Un `robots.txt` placé dans `site/` serait servi sous `/allahomairhamabi/robots.txt`, **ce qui n'est pas lu par les moteurs** : seul `https://rahmaapps.github.io/robots.txt` compte, et il relève du repo `rahmaapps.github.io`. ⏳ Décision : ne rien faire (indexation par défaut), ou ajouter `robots.txt` + sitemap **dans le repo user site** (lot séparé, en préservant strictement `app-ads.txt`). |
| `hreflang` | Uniquement si une version FR ou EN est créée |

**Langues** — ✅ **validé (décision 7)** :
- **B.3** : landing page **arabe uniquement**, RTL, **sans sélecteur FR/EN** ; liens vers les politiques AR **et** FR dans le footer.
- 💡 **Plus tard (hors B.3)** : une éventuelle version FR/EN fera l'objet d'une décision séparée.

---

## 17. CTA Google Play

✅ **URL vérifiée** : `https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi`. C'est celle utilisée par l'app (`settings_screen.dart:68`, texte `مشاركة التطبيق`). Elle correspond à l'`applicationId` Android, et la fiche répond en 200.

💡 **PROPOSITION :**
- **Badge officiel Google Play**, version arabe (« احصل عليه من Google Play »), conforme aux règles de marque Google : taille minimale et zone de protection, sans modification des couleurs ;
- lien direct, `rel="noopener"`, **jamais `#`** ;
- 2 occurrences au plus : hero et fin de page. Un mini-lien dans l'en-tête est facultatif.
- 💡 Paramètre `&hl=ar` : optionnel. Google adapte déjà la langue ; ⏳ à décider.
- ⏳ Suivi de campagne (`&referrer=utm_…`) : **non recommandé** sans décision, par cohérence avec l'absence de tracking.

---

## 18. Privacy

✅ **URL à conserver telles quelles** : `/allahomairhamabi/privacy_ar.html` (**déclarée sur Google Play**) et `/allahomairhamabi/privacy_fr.html`. **Contenu inchangé** dans ce lot.

💡 **PROPOSITION :**
- **Footer** : `سياسة الخصوصية` (AR) · `Politique de confidentialité` (FR, `lang="fr"`) · `تواصل معنا` (`mailto:contact.rahmaapps@gmail.com`, ✅ contact déjà publié dans les politiques et sur la fiche Play) · `Rahma Applications` (décision 1) · `© 2026`.
- **Bloc transparence** (§19) : un lien contextuel vers la politique AR.
- La refonte visuelle des pages de politique est **hors 68-B.1**. ⏳ À décider : les aligner visuellement plus tard (en-tête vert, polices) **sans toucher au texte juridique**, et régler au passage leurs dépendances tierces (Google Fonts, image imgur, `pattern.png` absent).

---

## 19. Monétisation

✅ **Faits verrouillés :**
- publicité **modérée** (D1) ;
- bannières **uniquement** sur HOME, Recherche et Favoris (D8) ;
- interstitiels uniquement au retour de Recherche ou Favoris vers HOME, **1 toutes les 10 minutes au maximum** (D10, D11) ;
- **aucune publicité** sur la lecture (`DuaReadScreen`), la visite au cimetière, l'onboarding ni le démarrage ; **aucune publicité automatique** dans les Paramètres, où l'utilisateur peut seulement lancer un Rewarded volontaire (D6, D9, D12 ; voir §27.3) ;
- annonces avec récompense **volontaires** (D2) : 1 heure sans publicité (D15) ou 1 partage en image ;
- consentement UMP (D13) ;
- aucune analytics (politique) ;
- **aucun achat**, et le soutien (D5) n'est pas implémenté.

❌ **À supprimer** : `تجربة نقية 100% بدون إعلانات` et **toute** formulation équivalente (« بلا إعلانات », « خالٍ من الإعلانات »…) appliquée à l'app entière.

✅ **Bloc `بوضوح` validé (décision 4)** : texte exact dans « DÉCISIONS VALIDÉES — LOT 68-B.1 », en tête de document. C'est **la seule formulation publicitaire** du site ; aucune autre mention d'annonce n'est ajoutée ailleurs. Les faits écran par écran restent consignés au §27.3 (référence interne, non publiée).

---

## 20. Éléments à supprimer

| Élément actuel | Décision | Raisons |
|---|---|---|
| Ancien hero (logo 200 px JPEG + H1 entre guillemets + accroche « لوالدك ») | **Remplacer** 💡 | Accroche limitée au père (l'app couvre 11 proches ✅) ; logo basse résolution ; aucun visuel produit au premier écran (68-A) |
| Titre « المميزات التي تجعل **موقعنا** خيارك الأفضل » | **Supprimer** ✅ | Parle du « site », superlatif (68-A) |
| Liste de 15 fonctionnalités avec emojis | **Remplacer** par les sections 2 à 6 💡 | Liste plate, doublons (favoris ×2), plusieurs items faux (68-A §D.1) |
| « 100% بدون إعلانات » | **Supprimer** ✅ | Contraire à D1, D8 et D10 et à la politique publiée |
| « مشاركة سريعة عبر واتساب » | **Supprimer** ✅ | Intégration WhatsApp supprimée (LOT 3.O) ; partage natif |
| « يعمل **بالكامل** بدون إنترنت » | **Reformuler** 💡 | Le contenu est hors ligne, pas les publicités ni le consentement |
| « محرك بحث **ذكي** » | **Reformuler** 💡 | Recherche plein texte locale ; « ذكي » survend |
| « تذكير **يومي** » | **Préciser** 💡 | 3 rappels (matin, soir, vendredi) |
| « أدعية مميزة لشهر رمضان » (item) | **Supprimer** ✅ | Aucune entrée UI Ramadan (décision V1.2, `ETAT_CONSOLIDE` §7) |
| Mockups `mockup_home/favorites/settings.png` | **Supprimer** ✅ | UI obsolète : chip Ramadan, WhatsApp, toggles violets, `بعد الظهر`, `حفظ`, « SETTING » |
| Doublons `mockup_*.jpeg` (non référencés) | **Supprimer** 💡 | Inutiles. ⏳ Leurs URL deviendront 404 : impact nul attendu, à confirmer. |
| CTA Google Play `href="#"` | **Remplacer** ✅ | URL réelle vérifiée (§17) |
| Police `Noto Kufi Arabic` | **Supprimer** ✅ | Hors Design System ; jamais chargée |
| Couleurs `#063F1D` / `#0B542E` / `#FCEECB` / `#B8F3C2` | **Remplacer** ✅ | Tokens Design System (§14) |
| Emojis décoratifs (✨ 📖 🕊️ …) | **Supprimer** 💡 | Registre sobre ; lecture d'écran polluée |
| `alt` anglais (`Home`, `Favorites`…) | **Remplacer** 💡 | `alt` arabes descriptifs |
| Section H2 « سياسة الخصوصية » (pour un seul lien) | **Déplacer** au footer 💡 | Allègement |
| « SETTING » (dans le mockup) | **Disparaît avec les mockups** ✅ | — |

---

## 21. Éléments à conserver

| Élément | Raison | Statut |
|---|---|---|
| URL `…/allahomairhamabi/`, `privacy_ar.html`, `privacy_fr.html` | App (`عن التطبيق`) et Google Play | ✅ critique |
| Contenu des politiques | Juridique, à jour au 23/09/2026 | ✅ |
| `lang="ar" dir="rtl"`, Arabic-first | App mono-langue arabe | ✅ |
| Identité verte + nom de l'app | Continuité | ✅ (teintes réalignées sur les tokens) |
| Icône (mains + calligraphie) | Figée (`ETAT_CONSOLIDE` §7) ; utiliser le **master HD / SVG**, pas `Logo.jpg` | ✅ |
| Mention de l'éditeur + © | Éditeur : **`Rahma Applications`** (décision 1) | ✅ |
| Messages vrais du site actuel (courts/longs, favoris, vendredi, recherche, thème) | Reformulés dans les nouvelles sections | 💡 |
| Workflow Pages (`site/` uniquement) | Architecture validée 68-B.0.1 | ✅ |

---

## 22. Éléments nécessitant validation

✅ **Clos.** Les 7 arbitrages sont validés (voir « DÉCISIONS VALIDÉES — LOT 68-B.1 »). Les autres points V7–V9 et V11–V15 sont des recommandations techniques ou de design, sans arbitrage produit, consignées au §26.

---

## 23. Architecture finale

✅ **Verrouillée** : voir le §7 (vue d'ensemble) et le §28 (détail par section).

---

## 24. Préparation du LOT 68-B.2 — Captures réelles

**Entrée :** liste verrouillée du §29 (décisions 3, 5 et 6 validées).

Checklist proposée :
1. **Build** : baseline figée (commit à noter), build `github-migration` en `ADS_ENV=test`. Aucune publicité visible dans le cadre (décision 5) — méthode : **mode avion** pendant toute la séance (protocole B.2 §1).
2. **Appareil** : un seul modèle, 1080 × 2400 (ou 1080 × 1920), police système par défaut, `textScaler` 1,0, **thème clair**.
3. **Barre d'état** : *demo mode* Android (heure 09:41 ou neutre, batterie pleine, aucune notification).
4. **Données de démo** :
   - **C1, C3–C6, E1–E3 : أبي seul** (prénom **`محمد`**, décision 6) ; **C2 en dernier** : ajout de أمي et جدي (F2) ;
   - favori : **id 3** ajouté depuis le HOME après saisie de `محمد` (F3, F4) ;
   - rappels : matin **07:30** (décision 6), soir **20:00**, vendredi **09:00**, tous activés (F6) ;
   - aucune donnée réelle.
5. **Exports** : générer les 3 PNG de partage (`Dark Luxe`, `Emerald`, `White`) pour **l'id 3 personnalisé** (même douʿā que C1).
6. **Nommage** : fichiers bruts nommés selon le protocole B.2 (`c1-home.png` … `c6-rappels.png`, `e1-dark-luxe.png`, `e2-emerald.png`, `e3-white.png`) ; emplacement final dans `site/` décidé au LOT 68-B.3.
7. **Revue** : lisibilité, aucune donnée personnelle, aucune publicité, cohérence de la série, validation Hamza avant intégration.

---

## 25. Préparation du LOT 68-B.3 — Implémentation

**Entrée :** ce document validé + captures validées (68-B.2).

1. **Structure** : HTML statique unique (`site/index.html`), CSS unique, **aucun framework ni build** (compatibilité avec le workflow existant). JS minimal, voire aucun.
2. **Tokens** : variables CSS reprenant §14 (clair et, si V7, sombre), espacements §12, typo §13.
3. **Assets** : polices WOFF2 (V8), icône HD et favicons (V13), captures WebP + PNG de repli, image Open Graph 1200×630.
4. **Contenu** : textes arabes des sections 1 à 9, **relus par Hamza** avant publication ; aucune formulation de §20 marquée « Supprimer ».
5. **SEO** : §16 complet.
6. **Liens** : Play (§17), politiques AR et FR, `mailto`. Vérifier : **aucun `href="#"`**, aucun lien absolu `/…` (qui pointerait vers la racine du user site).
7. **Contraintes à préserver** :
   - noms `privacy_ar.html` / `privacy_fr.html` inchangés ;
   - `site/index.html` doit toujours contenir `href="privacy_ar.html"` (assertion du test `privacy_policy_content_test.dart` sur `github-migration`) ;
   - `app-ads.txt` hors périmètre.
8. **QA** :
   - responsive 320 / 375 / 768 / 1366 / 1920 ;
   - RTL, contrastes, focus clavier, `prefers-reduced-motion` ;
   - Lighthouse ;
   - aperçu de partage WhatsApp ;
   - lien `عن التطبيق` depuis l'app.

---

---

# Verrouillage du LOT 68-B.1 (mise à jour du 25/09/2026)

> Sections de verrouillage. Ordre de priorité en cas d'écart : **« DÉCISIONS VALIDÉES — LOT 68-B.1 »** (en tête), puis **§26 à §30**, puis §1 à §25.
> Faits revérifiés dans le code de `github-migration` @ `46fb8ff` (lecture seule).

## 26. Matrice V1–V15

Statuts :
- ✅ **DÉCISION EXISTANTE** : validée dans le projet, y compris par les 7 arbitrages du 25/09/2026 ;
- 💡 **PROPOSITION** : recommandation technique ou de design, sans arbitrage produit ;
- ⏳ **À CONFIRMER** : point ouvert.

| ID | Sujet | Constat factuel | Décision / recommandation | Statut | Impact B.2/B.3 |
|---|---|---|---|---|---|
| **V1** | Nom, éditeur | Play : `اللهم ارحم أبي \| دعاء للميت`, éditeur « Rahma Applications ». App : `اللَّهُمَّ ارْحَمْ أَبِي`. Politiques : « Rahma Apps ». | `<title>` = nom Play ; H1 `اللَّهُمَّ ارْحَمْ أَبِي` ; sous-titre `أدعية مختارة لوالدك ووالدتك ولكل من تحب` ; éditeur **`Rahma Applications`** | ✅ (décisions 1 et 2) | B.3 : H1, `<title>`, OG, JSON-LD, footer |
| **V2** | Section Grave Visit | Fonction disponible : lecture seule, 1 texte par relation, sans action, sans publicité, sans attribution, sans prénom inséré | Section `عند زيارة القبر`, sobre ; interdits : source, prénom, « plusieurs douʿās » | ✅ (décision 3) | B.2 : C5 ; B.3 : section 5 |
| **V3** | Mention Share as Image | 1 Rewarded = 1 partage, confirmation préalable ; gratuit si heure sans publicité ou annonce indisponible ; texte toujours gratuit | Couverte **uniquement** par le bloc `بوضوح` validé | ✅ (décision 4) | B.3 : sections 7 et 8 |
| **V4** | Bloc transparence | Voir le tableau §27.3 | Texte exact validé (« DÉCISIONS VALIDÉES ») | ✅ (décision 4) | B.3 : section 8 |
| **V5** | Publicité dans les captures | Bannière réelle sur HOME, Recherche et Favoris ; contenu Google non maîtrisable | Captures sans publicité visible ; publicité expliquée par le texte ; annonce jamais capturée | ✅ (décision 5) | B.2 : mode avion pendant la séance (protocole B.2 §1) |
| **V6** | Rappels | Les 3 rappels ont une heure configurable (défauts 09:00 / 20:00 / 09:00 ; vendredi désactivé par défaut) | Texte `صباحًا في الوقت الذي تختاره، ومساءً، ويوم الجمعة إن أردت` ; **aucun horaire dans le texte du site** ; capture C6 : **07:30 / 20:00 / 09:00** | ✅ (décision 6 + consigne notifications) | B.2 : C6 ; B.3 : section 6 |
| **V7** | Mode sombre du site | Thème sombre complet dans l'app | Clair seul pour la V1 du site ; tokens sombres prévus en variables CSS | 💡 | B.3 : CSS |
| **V8** | Polices | Lateef + IBM Plex Sans Arabic embarquées ; licence SIL OFL 1.1 (fichier de licence non versionné) | Auto-hébergement WOFF2 + `OFL.txt` | 💡 | B.3 : `site/fonts/` |
| **V9** | `robots.txt` / sitemap | Seul `rahmaapps.github.io/robots.txt` serait lu (repo `app-ads.txt`) | Ne rien faire en B.3 | 💡 | Aucun |
| **V10** | Langue | App 100 % arabe ; politique FR existante | Arabe uniquement, RTL, sans sélecteur ; politique FR dans le footer | ✅ (décision 7) | B.3 : périmètre |
| **V11** | Nombre de douʿās | Compteur Recherche gonflé par les déclinaisons par personne et le Ramadan | Aucun chiffre affiché | 💡 | B.3 : textes |
| **V12** | `mockup_*.jpeg` | Publiés, référencés nulle part | À supprimer avec les mockups PNG | 💡 | B.3 : nettoyage |
| **V13** | Favicon | Défaut de l'icône sous 32 px | Dérivé simplifié par Claude Design | 💡 | B.3 : favicons |
| **V14** | Filigrane rosace | Motifs existants dans l'app | ≤ 5,5 %, hero uniquement, à juger par Claude Design | 💡 | B.3 : hero |
| **V15** | Pages de politique | Dépendances tierces (Google Fonts, imgur, `pattern.png`) ; phrase « réglages » à préciser (Rewarded volontaire) | Lot séparé ; texte juridique inchangé en B.3 | ⏳ | Aucun en B.3 |

---

## 27. Points critiques — version finale

### 27.1 Nom officiel

| Niveau | Valeur | Statut |
|---|---|---|
| Nom officiel Google Play | `اللهم ارحم أبي \| دعاء للميت` | ✅ fait constaté (modifiable seulement dans la Play Console) |
| Nom sur l'appareil | `اللهم ارحم أبي` (`android:label`) | ✅ code |
| Titre in-app | `اللَّهُمَّ ارْحَمْ أَبِي` | ✅ code |
| **H1 du site** | `اللَّهُمَّ ارْحَمْ أَبِي` | ✅ décision 2 |
| **Sous-titre du site** | `أدعية مختارة لوالدك ووالدتك ولكل من تحب` | ✅ décision 2 |
| **`<title>` / `og:title`** | `اللهم ارحم أبي \| دعاء للميت` (identique à Play) | 💡 conséquence directe de V1, sans arbitrage |
| **Éditeur (site, JSON-LD, footer)** | `Rahma Applications` | ✅ décision 1 |

### 27.2 Grave Visit — ce que le site dit

✅ **Faits (code `github-migration`) :**
- fonction **disponible** : bandeau `دعاء زيارة القبر · للقراءة عند الزيارة` toujours visible sur le HOME ;
- choix parmi les personnes déjà cochées (sinon, état vide avec `اختيار شخص`) ;
- écran de **lecture seule** : un seul douʿā propre à la relation, réécrit au LOT 67 ;
- aucune action, aucune publicité, aucune attribution affichée, aucun prénom inséré ;
- wake lock non activé.

✅ **Formulation du site (unique)** : décision 3, sobre et factuelle :

> **عند زيارة القبر**
> دعاءٌ خاص لكل قريب تختاره، تقرؤه في صفحة هادئة بلا إعلانات.

❌ **Interdits validés :**
- source affichée (« رواه … ») ;
- insertion du prénom ;
- « plusieurs douʿās » sur cet écran ;
- toute mention d'écran maintenu allumé.

### 27.3 Publicité — faits de référence (interne) et texte publié

✅ **Faits de référence** (D1–D15 + code 5.G.B), **non publiés tels quels** :

| Écran | Bannière | Interstitiel | Rewarded |
|---|---|---|---|
| HOME (carte du douʿā) | **Oui** | Au retour depuis Recherche/Favoris (1 / 10 min max) | Via la feuille « مشاركة كصورة » uniquement, après confirmation |
| Écran de lecture (`DuaReadScreen`) | Non | Non | Non |
| Recherche | **Oui** | Déclenché en la quittant vers HOME | Non |
| Favoris | **Oui** | Déclenché en les quittant vers HOME | Non |
| دعاء زيارة القبر | Non | Non | Non |
| Paramètres | Non | Non | **Volontaire** : ligne « heure sans publicité », après confirmation |
| Onboarding / démarrage | Non | Non | Non |
| Partage texte | — | — | **Jamais** (toujours gratuit) |
| Partage en image | — | — | 1 annonce = 1 partage ; gratuit si heure sans publicité active ou annonce indisponible |

✅ **Texte publié : uniquement le bloc `بوضوح` validé** (décision 4, reproduit dans « DÉCISIONS VALIDÉES »). Aucune autre formulation publicitaire n'apparaît sur le site. `100% بدون إعلانات` et ses équivalents sont interdits.

ℹ️ Rappel de la note factuelle : « لا إعلانات أثناء قراءة الدعاء » renvoie à l'écran de lecture. Le HOME, qui affiche aussi un douʿā, porte une bannière. Formulation retenue telle que validée.

⏳ **Écart hors site (non corrigé) :** la politique publiée dit « aucune publicité … dans les réglages ». C'est exact pour les annonces **automatiques**, mais un Rewarded **volontaire** peut y être lancé (V15, lot séparé).

### 27.4 Captures — règles

✅ **Décision 5 :**

| Type | Règle |
|---|---|
| Interface | **Toutes les captures** montrent l'interface **sans publicité visible** : mode avion pendant toute la séance (protocole B.2 §1), aucune annonce de test dans le cadre |
| Publicité | **Jamais capturée** ; expliquée par le bloc `بوضوح` |
| Share as Image / Rewarded | Montrer les **3 images réellement générées** (E1–E3), présentables comme **une seule fonctionnalité**. Ne capturer **ni** la confirmation Rewarded, **ni** le chargement, **ni** l'annonce. |

### 27.5 Notifications — les trois rappels réels

✅ **Faits (code) :**

| Rappel | Horaire réel | Par défaut | Titre / texte réels |
|---|---|---|---|
| `تذكير الصباح` | Configurable (défaut 09:00) | Activé | `🌅 صباح الرحمة` / `🤲 لا تنسَ الدعاء لموتانا الأعزاء في بداية يومك` |
| `تذكير المساء` | Configurable (défaut 20:00) | Activé | `🌙 مساء الدعاء` / `🤲 قبل أن ينتهي يومك، ادعُ لموتانا الأعزاء` |
| `تذكير الجمعة` | Vendredi, configurable (défaut 09:00) | Désactivé | `🕌 جمعة مباركة` / `🤲 لا تنسَ الدعاء لموتانا الأعزاء في هذا اليوم المبارك` |

Aucun texte de douʿā dans la notification ; actions `فتح` / `تجاهل`.

✅ **Texte publié (unique)** : `صباحًا في الوقت الذي تختاره، ومساءً، ويوم الجمعة إن أردت`.
- **Aucun horaire n'est cité** dans le texte de la landing page ; la capture C6 montre les trois horaires configurés (07:30 / 20:00 / 09:00).
- Ne pas écrire : « تذكير في أي وقت », « إشعار يحمل دعاءً », « تذكير بعد الظهر ».

### 27.6 Ramadan

✅ **Aucune section Ramadan et aucune mention** tant qu'il n'existe pas d'entrée UI dédiée.
- Sources : décision V1.2 ; `ETAT_CONSOLIDE_UI_UX.md` §7 ; code : `_matchCategory` limité à `normal` / `friday` / `grave_visit` ; les douʿās Ramadan ne sont atteignables que par la Recherche.

---

## 28. Architecture finale — verrouillée

✅ **Structure validée.** Les messages arabes marqués ✅ sont validés. Ceux marqués 💡 sont des propositions de rédaction, à relire en B.3 dans le cadre validé.

| # | Section | Objectif | Message principal | Fonctionnalité illustrée | Screenshot | Priorité |
|---|---|---|---|---|---|---|
| 1 | En-tête | Identité immédiate | `اللَّهُمَّ ارْحَمْ أَبِي` ✅ | — | — (icône HD) | P0 |
| 2 | Hero | Dire ce qu'est l'app + faire télécharger | H1 `اللَّهُمَّ ارْحَمْ أَبِي` + `أدعية مختارة لوالدك ووالدتك ولكل من تحب` ✅ · `مجاني · Android` 💡 | Carte du douʿā (HOME) | **C1** | P0 |
| 3 | لمن تدعو؟ | Montrer que ce n'est pas « que le père » | `اختر من تدعو له، وأضف اسمه إن شئت ليظهر في الدعاء` 💡 | 11 relations, multi-sélection, prénom inséré | **C2** + **C3** | P0 |
| 4 | كل يوم | Usage quotidien | `اقرأ دعاءً، واطلب غيره، واحفظ ما يلامس قلبك` 💡 | `دعاء آخر`, `عام` / `دعاء الجمعة`, ♡, البحث | **C4** (C1 et C3 réutilisées) | P1 |
| 5 | عند زيارة القبر | Accompagner un moment unique | `دعاءٌ خاص لكل قريب تختاره، تقرؤه في صفحة هادئة بلا إعلانات` ✅ (cadre décision 3) | Grave Visit | **C5** | P1 |
| 6 | تذكير | Régularité | `صباحًا في الوقت الذي تختاره، ومساءً، ويوم الجمعة إن أردت` ✅ | 3 rappels | **C6** (recadré) | P2 |
| 7 | شارك الأجر | Transmettre | `شارك الدعاء نصًّا، أو كصورة بأحد ثلاثة تصاميم` 💡 | Partage texte + image (une seule fonctionnalité) | **E1–E3** | P1 |
| 8 | بوضوح | Transparence | Bloc validé ✅ | Publicité, données locales, politique | — | P0 |
| 9 | CTA Google Play | Conversion | `ابدأ الدعاء لمن تحب` 💡 + badge officiel | — | — | P0 |
| 10 | Footer | Légal et contact | سياسة الخصوصية · Politique de confidentialité (FR) · تواصل معنا · `Rahma Applications` · © 2026 ✅ | — | — | P0 |

Priorités :
- **P0** : indispensable ;
- **P1** : fort intérêt ;
- **P2** : condensable (la section 6 peut se réduire à une ligne si la page doit raccourcir).

---

## 29. Captures B.2 — liste verrouillée

✅ **6 captures + 3 exports** (décisions 5 et 6). Aucune n'est créée dans ce lot.

**Préparation commune :**
- baseline figée, `ADS_ENV=test` ;
- **aucune publicité visible** : mode avion pendant toute la séance (protocole B.2 §1) ;
- thème **فاتح** ;
- `textScaler` 1,0 ;
- *demo mode* de la barre d'état ;
- **أبي seul** (prénom **`محمد`**) pour C1, C3–C6 et E1–E3 ; **أمي** et **جدي** ajoutés **en dernier**, pour C2 uniquement (F2) ;
- rappels : matin **07:30**, soir **20:00**, vendredi **09:00**, tous activés (F6) ;
- ordre de séance : protocole B.2 §2 ;
- aucune donnée réelle.

| ID | Écran | État précis à reproduire | Profil | Données affichées | Objectif | Emplacement |
|---|---|---|---|---|---|---|
| **C1** | HOME | **أبي seul** coché ; onglet `عام` actif ; ligne `تدعو لـ أبي · تغيير` ; bandeau `دعاء زيارة القبر` visible ; aucun toast | أبي (`محمد`) | **Id 3** exact : `اللهم اجعل قبر أبي محمد روضةً من رياض الجنة، وانر دربه بنور هدايتك يا كريم يا رحيم.` | Montrer l'app réelle au premier regard | Section 2 (Hero) |
| **C2** | Sélection des personnes (mode Édition, `تدعو لـ`) | **Capturée en dernier** : أبي, أمي, جدي cochés ; prénom `محمد` saisi pour أبي (autres champs vides) ; pas de clavier ni de snackbar | أبي, أمي, جدي | Les 11 relations visibles | Montrer la capacité multi-profils ; montrer le prénom | Section 3 |
| **C3** | `DuaReadScreen` (ouvert depuis Favoris) | Id 3 mis en favori **depuis le HOME** après saisie de `محمد` (F3) ; carte hero, ♥ rempli, `نسخ` / `مشاركة` visibles | أبي | **Même douʿā que C1** (id 3) : `اللهم اجعل قبر أبي محمد روضةً من رياض الجنة، وانر دربه بنور هدايتك يا كريم يا رحيم.` | Lecture + personnalisation | Section 3 |
| **C4** | Recherche | Terme **`الجنة`**, clavier **fermé**, 3 ou 4 premiers résultats surlignés (ids 3, 4, 9, 20). Donnée technique : 292 résultats (F5), **jamais utilisée sur le site** | — | Extraits surlignés `#FDF0C8` | Retrouver un douʿā | Section 4 |
| **C5** | `GraveVisitReadScreen` | Bandeau → أبي ; début du texte ; ✦ en tête | أبي | Texte `grave_visit` de أبي (LOT 67) — sans attribution, sans prénom | Présenter la visite avec respect | Section 5 |
| **C6** | Paramètres › `التذكير` | Les 3 rappels activés : matin **07:30**, soir **20:00**, vendredi **09:00** ; recadrage sur la section `التذكير` complète (**jamais** réduite au seul matin) | — | 3 rappels, chacun avec sa ligne `الوقت` | Montrer les 3 rappels configurables | Section 6 |
| **E1–E3** | Exports « مشاركة كصورة » | Id 3 personnalisé (même douʿā que C1), exporté en **`Dark Luxe`** (E1), **`Emerald`** (E2), **`White`** (E3) | أبي | 3 PNG réels (taille native) | Qualité des images partagées ; **présentées comme une seule fonctionnalité** | Section 7 |

**Exclus :**
- Favoris (couvert par C3) ;
- HOME sombre (V7) ;
- feuille de choix du modèle (facultative) ;
- **toute capture de publicité ou du parcours Rewarded** (décision 5).

L'image Open Graph (1200×630) sera **composée** au LOT 68-B.3 à partir de C1 et de l'icône.

---

## 30. Arbitrages

✅ **Tous les arbitrages du LOT 68-B.1 sont validés** (voir « DÉCISIONS VALIDÉES — LOT 68-B.1 »). Aucun arbitrage produit n'est ouvert pour démarrer le LOT 68-B.2.

Points restant ouverts, **hors LOT 68-B.1** :
- V15 : pages de politique (dépendances tierces, précision « réglages ») → lot séparé ;
- recommandations de design V7, V8, V13, V14 → à confirmer par Claude Design / en B.3.

*Fin du document. Aucune implémentation n'a été réalisée dans ce lot.*
