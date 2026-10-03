# LOT 68-B.2 — Protocole de captures réelles

> **Nature :** protocole uniquement. **Aucune capture n'est créée**, aucun code, asset ni fichier du site n'est modifié.
> **Date :** 25 septembre 2026
> **Source de vérité :** `docs/LOT68_B1_VISUAL_DIRECTION.md` (validé et verrouillé) + **code réel** de l'application sur `github-migration` @ `46fb8ff`, lu en lecture seule via `git show`.
> ⚠️ La copie de travail est sur `lot68-b01-pages` (base `main` = **ancienne** app). **Les captures doivent être faites avec un build de `github-migration`**, jamais depuis la branche courante.

---

## 0. Écarts constatés entre B.1 et le code réel

La vérification ligne à ligne du code a révélé des écarts avec certaines hypothèses de B.1. Elles venaient de la documentation UI/UX, antérieure à certains commits. Le protocole ci-dessous suit **le code**. Les décisions validées de B.1 **ne sont pas remises en cause** ; seuls des faits sont corrigés.

| # | Hypothèse B.1 | Réalité du code | Conséquence pour B.2 |
|---|---|---|---|
| É1 | C1 montre `تدعو لـ أبي` **et** C2 montre 3 proches cochés | Avec plusieurs proches, le HOME affiche `تدعو لـ 3 أشخاص` et tire le douʿā au hasard parmi **tous** les proches cochés (`home_screen.dart` l. 941-946, 179-194) | **Ordre de séance imposé** : C1 (et la préparation de C3 et E1–E3) **avec أبي seul**, **puis** ajout de أمي et جدي pour C2 (§2) |
| É2 | Badge `الحالي` sur أبي dans C2 | **Aucun badge `الحالي`** dans `person_selection_screen.dart` : liste des 11 relations, puce + champ `الاسم (اختياري)` visible seulement si cochée | C2 : pas de « proche courant » visible. Exigence retirée (fait, pas décision). |
| É3 | C3 : `أبي محمد` inséré par l'écran de lecture | `DuaReadScreen` **ne personnalise pas**. Il affiche le texte **sauvegardé au moment de l'ajout en favori depuis le HOME** (`saveFavoriteText`, l. 1056 ; résolution `getFavoriteText`, `dua_read_screen.dart` l. 76-92), sinon le texte brut | C3 réalisable **uniquement** si le douʿā est mis en favori **depuis le HOME après la saisie de `محمد`** |
| É4 | C4 : `الجنة` = 16 résultats | La Recherche fait un `contains` brut sur les **2 215 entrées** (11 proches + `general`, toutes catégories, Ramadan inclus). `الجنة` donne **292 résultats** (26 par proche + 6 `general`). **Aucun compteur n'est affiché** quand un terme est saisi. | C4 : pas de vérification « 16 ». Les premiers résultats sont ceux du père (ids 3, 4, 9, 20), dans l'ordre du JSON. |
| É5 | Rappels : soir **20:00 fixe**, vendredi **09:00 fixe** | **Les 3 rappels ont une heure réglable** (`_pickEveningTime`, `_pickFridayTime` ; `_ReminderRow` affiche une ligne `الوقت` pour chaque rappel activé). Valeurs par défaut : matin 09:00 (activé), soir 20:00 (activé), vendredi 09:00 (**désactivé**). | C6 montre **3 lignes `الوقت`** (07:30 / 20:00 / 09:00). La formulation validée du site reste **vraie** ; le §27.5 de B.1 est factuellement à corriger (non fait ici). |
| É6 | Noms de modèles `داكن فاخر` / `زمردي` / `أبيض أنيق` | La feuille affiche les noms **anglais** `Dark Luxe` / `Emerald` / `White` (`PremiumTemplateX.displayName`) | Le site **ne nomme pas** les modèles (« بأحد ثلاثة تصاميم »), ce qui est cohérent avec B.1 §28 |
| É7 | Visite : attribution `رواه مسلم` (spec) | **Aucune attribution** affichée ; **aucun prénom** inséré (LOT 3.F) | Déjà intégré en B.1 (décision 3). Rappelé pour C5. |

---

## 1. Environnement de capture (commun)

| Élément | Consigne |
|---|---|
| **Code** | `github-migration` @ `46fb8ff` (ou la baseline figée qui la remplace, **à noter dans le rapport B.2**) |
| **Build** | `flutter run --debug` ou APK release **sans** `ADS_ENV=production` (défaut `test`). `debugShowCheckedModeBanner` est déjà à `false` : aucun bandeau DEBUG. |
| **Appareil** | Un seul modèle pour toute la série. Recommandé : **émulateur Pixel 7** (1080 × 2400 px, 420 dpi, soit ≈ 411 × 914 dp), API 34+, ou un appareil réel équivalent |
| **Orientation** | **Portrait** pour toutes les captures |
| **Réglages système** | Langue système quelconque (l'app force `ar`) ; **taille de police 100 %** ; **taille d'affichage par défaut** ; mode clair système |
| **Thème de l'app** | Paramètres → `المظهر` → **`فاتح`** (ne pas laisser `تلقائي`) |
| **Aucune publicité visible** | **Mode avion activé avant la première ouverture de l'app**, et pendant toute la séance. Aucune annonce ne se charge, la bannière a une **hauteur nulle** (LOT 5.B), aucun interstitiel, pas de formulaire UMP, et le partage en image est **gratuit sans annonce** (règle B2 de `ShareAsImageFlow` : Rewarded indisponible ⇒ partage immédiat). Aucune dépendance réseau pour le contenu (données et polices embarquées). |
| **Barre d'état** | *Demo mode* Android, par exemple : `adb shell settings put global sysui_demo_allowed 1` · `adb shell am broadcast -a com.android.systemui.demo -e command enter` · `… -e command clock -e hhmm 0941` · `… -e command battery -e level 100 -e plugged false` · `… -e command network -e wifi show -e level 4 -e mobile hide -e airplane hide` · `… -e command notifications -e visible false`. ⏳ Vérifier que l'icône avion est bien masquée sur l'image de l'appareil utilisé. |
| **Données** | **Installation vierge** (désinstaller, ou `adb shell pm clear com.joumane.allahomairhamabi`). Seule donnée saisie : le prénom fictif **`محمد`**. Aucun compte, aucune donnée réelle. |
| **Capture** | `adb exec-out screencap -p > <fichier>.png` : PNG natif **1080 × 2400**, **sans recadrage à la prise**. Le recadrage indiqué dans chaque fiche est appliqué en B.3, sur une copie. |
| **Stockage des bruts** | ⏳ Hors du site publié (par exemple un dossier de travail local ou `docs/lot68_captures/raw/`, à décider). Seules les versions optimisées iront dans `site/` en B.3. |

---

## 2. Ordre de séance obligatoire

L'ordre découle de l'écart É1 (un seul proche pour C1) et de l'écart É3 (favori à créer depuis le HOME, après le prénom).

```
A. Installation vierge + mode avion + demo mode
B. Onboarding : لمن تدعو؟ → cocher أبي seul, prénom محمد ; تذكير يومي؟ → activé, 07:30
C. Paramètres → المظهر = فاتح
D. HOME (عام) : « دعاء آخر » jusqu'à l'id 3 personnalisé      → C1
E. Sur l'id 3 : ♡ (favori), puis ⤴ × 3 modèles                  → E1, E2, E3
F. Favoris → ouvrir l'id 3                                     → C3
G. ⌕ Recherche « الجنة », clavier fermé                          → C4
H. Bandeau دعاء زيارة القبر → أبي                                → C5
I. Paramètres : soir activé, vendredi activé                   → C6
J. HOME → ligne « pour qui » → cocher أمي puis جدي             → C2
```

---

## 3. Fiches de capture

### C1

- **ID :** C1
- **Écran :** HOME
- **Préconditions :** étapes A à C terminées ; **un seul proche coché : أبي**, prénom `محمد` ; catégorie `عام` active (état par défaut) ; mode avion.
- **Étapes exactes :**
  1. Ouvrir l'app, qui arrive sur le HOME après l'onboarding.
  2. Vérifier la ligne `تدعو لـ أبي · تغيير` et que la puce `عام` est active.
  3. Toucher `دعاء آخر` jusqu'à afficher l'**id 3**. Le paquet de 140 douʿās `normal` du père est mélangé sans répétition, donc l'id 3 apparaît en **140 touches au plus**. Ne jamais toucher les puces pendant la recherche (cela reconstitue le paquet).
  4. Attendre la fin de l'animation (≤ 280 ms), puis capturer.
- **Données :** proche أبي (`محمد`).
- **État attendu :** la carte affiche exactement
  `اللهم اجعل قبر أبي محمد روضةً من رياض الجنة، وانر دربه بنور هدايتك يا كريم يا رحيم.`
  Texte source id 3 : `…قبر والدي…`, personnalisé par `DuaPersonalizer`, où `والدي` devient `أبي محمد`.
- **Éléments visibles :**
  - AppBar `اللَّهُمَّ ارْحَمْ أَبِي` + icônes ⌕ ♡ ⤴ ⋮ ;
  - bandeau `دعاء زيارة القبر · للقراءة عند الزيارة` ;
  - puces `عام` (active) et `دعاء الجمعة` ;
  - ligne `تدعو لـ أبي · تغيير` ;
  - carte du douʿā (♡ vide, `دعاء آخر`) ;
  - boutons `نسخ` / `مشاركة`.
- **Éléments non visibles :** bannière publicitaire, toast, snackbar, clavier, notification, indicateur de débogage, icône avion.
- **Recadrage recommandé :** plein écran sous la barre d'état (retirer les 24 dp du haut **ou** garder la barre en demo mode, choix de B.3). Aucune coupe latérale.
- **Résolution :** 1080 × 2400 PNG (brut).
- **Nom de fichier :** `c1-home.png`

### C2

- **ID :** C2
- **Écran :** Sélection des personnes (mode Édition, titre `تدعو لـ`)
- **Préconditions :** **toutes les autres captures déjà faites** (étape J, en dernier) ; أبي coché avec `محمد`.
- **Étapes exactes :**
  1. HOME → toucher `تغيير` sur la ligne « pour qui ». L'écran `تدعو لـ` s'ouvre.
  2. Toucher la puce `أمي`, puis la puce `جدي` (elles se cochent ; un champ `الاسم (اختياري)` apparaît à côté de chacune, **laissé vide**).
  3. Vérifier que le champ de `أبي` affiche `محمد`.
  4. Toucher une zone vide pour **fermer le clavier** ; attendre la disparition de tout snackbar, puis capturer.
- **Données :** أبي = `محمد` ; أمي et جدي sans prénom.
- **État attendu :** sous-titre `يُحفظ اختيارك تلقائيًا` ; 11 lignes dans l'ordre `أبي، أمي، والديّ، جدي، جدتي، أخي، أختي، ابني، ابنتي، زوجي، زوجتي` ; 3 puces cochées (أبي, أمي, جدي) avec leur champ ; les 8 autres non cochées, sans champ.
- **Éléments visibles :** AppBar `تدعو لـ` + flèche retour ; sous-titre ; les 11 relations ; le champ `محمد`.
- **Éléments non visibles :**
  - clavier ;
  - curseur de saisie (retirer le focus) ;
  - snackbar `تراجع` ;
  - tout prénom réel ;
  - ~~badge `الحالي`~~ : n'existe pas (É2).
- **Recadrage recommandé :** de l'AppBar à la dernière ligne `زوجتي`. ⏳ Si les 11 lignes ne tiennent pas sur l'écran de l'appareil, capturer en haut de liste (أبي → au moins جدي visibles) et le signaler.
- **Résolution :** 1080 × 2400 PNG.
- **Nom de fichier :** `c2-proches.png`

### C3

- **ID :** C3
- **Écran :** Lecture d'un douʿā (`DuaReadScreen`), ouvert depuis Favoris
- **Préconditions :** étape E faite : l'**id 3** a été mis en favori **depuis le HOME alors qu'il affichait `أبي محمد`**. Le texte personnalisé est alors sauvegardé (`saveFavoriteText`).
- **Étapes exactes :**
  1. HOME → icône ♡ de l'AppBar → écran `المفضلة`.
  2. Toucher le **texte** de la carte (pas le ♥) pour ouvrir l'écran de lecture.
  3. Attendre la fin de la transition (300 ms), puis capturer.
- **Données :** favori id 3 (texte personnalisé sauvegardé).
- **État attendu :** carte de lecture (Lateef 31), texte exact
  `اللهم اجعل قبر أبي محمد روضةً من رياض الجنة، وانر دربه بنور هدايتك يا كريم يا رحيم.`, ♥ **rempli**, boutons `نسخ` / `مشاركة`, AppBar sans titre (retour seul).
- **Éléments visibles :** retour `→`, carte de lecture complète (rosace, filet d'or), ♥, `نسخ` / `مشاركة`.
- **Éléments non visibles :** toast `تم النسخ ✓`, snackbar, publicité (écran sans bannière par construction, D9).
- **Recadrage recommandé :** plein écran ; en B.3, recadrage possible **sur la carte** seule.
- **Résolution :** 1080 × 2400 PNG.
- **Nom de fichier :** `c3-lecture.png`
- ⏳ **Variante possible :** C1 et C3 affichent **le même texte** (id 3). Si un texte différent est voulu en C3, mettre en favori, pendant l'étape D, un **autre** douʿā contenant `والدي` ou `أبي` (il sera aussi personnalisé), et l'ouvrir ici. Dans ce cas, noter son id et son texte exact dans le rapport B.2.

### C4

- **ID :** C4
- **Écran :** Recherche
- **Préconditions :** HOME, أبي seul coché (sans effet sur la recherche, qui couvre tout le corpus).
- **Étapes exactes :**
  1. HOME → icône ⌕. Le champ s'ouvre avec le clavier.
  2. Saisir **`الجنة`** (sans tashkīl) et attendre 250 ms (debounce).
  3. Fermer le clavier avec **une seule pression sur Retour système**, sans défiler, pour garder le haut de liste. ⏳ Vérifier que Retour ferme le clavier sans quitter l'écran ; sinon toucher une zone neutre.
  4. Capturer.
- **Données :** terme `الجنة`.
- **État attendu :** champ contenant `الجنة` + ✕ ; liste de résultats commençant par les douʿās du père dans l'ordre du corpus : **ids 3, 4, 9, 20** en tête ; terme surligné (fond `#FDF0C8`) ; extraits Lateef sur 2 lignes. **292 résultats au total, sans compteur affiché** (É4). Les extraits sont les **textes bruts** (`والدي`, non personnalisés).
- **Éléments visibles :** champ, 3 ou 4 cartes de résultat avec surlignage.
- **Éléments non visibles :** clavier, bannière (hauteur nulle hors ligne), état `لا توجد نتائج`.
- **Recadrage recommandé :** du champ jusqu'à la 3e ou 4e carte complète ; couper sous une carte entière, jamais au milieu.
- **Résolution :** 1080 × 2400 PNG.
- **Nom de fichier :** `c4-recherche.png`

### C5

- **ID :** C5
- **Écran :** دعاء زيارة القبر (`GraveVisitReadScreen`)
- **Préconditions :** أبي coché.
- **Étapes exactes :**
  1. HOME → toucher le bandeau `دعاء زيارة القبر`. Une feuille s'ouvre avec la puce `أبي`.
  2. Toucher `أبي`. L'écran de lecture s'ouvre.
  3. Rester en **haut** du texte (ne pas défiler), puis capturer.
- **Données :** texte `grave_visit` du père (**id 200**, validé au LOT 67), affiché **tel quel**, sans prénom.
- **État attendu :** carte avec ✦ en tête, texte Lateef qui commence exactement par :
  `السَّلَامُ عَلَيْكُمْ أَهْلَ الدِّيَارِ مِنَ الْمُؤْمِنِينَ وَالْمُسْلِمِينَ،`
  `وَإِنَّا إِنْ شَاءَ اللَّهُ لَلَاحِقُونَ،`
  `أَسْأَلُ اللَّهَ لَنَا وَلَكُمُ الْعَافِيَةَ.`
  `اللَّهُمَّ إِنَّ أَبِي قَدْ نَزَلَ بِكَ وَأَنْتَ خَيْرُ مَنْزُولٍ بِهِ، …`
  Le reste du texte (long) défile dans la carte.
- **Éléments visibles :** AppBar (retour), carte, début du texte.
- **Éléments non visibles :**
  - toute action : il n'en existe aucune ;
  - toute source ou attribution : aucune n'est affichée ;
  - le prénom `محمد` : non inséré par conception ;
  - toute publicité.
- **Recadrage recommandé :** plein écran ; en B.3, éventuellement la moitié haute de la carte.
- **Résolution :** 1080 × 2400 PNG.
- **Nom de fichier :** `c5-visite.png`

### C6

- **ID :** C6
- **Écran :** Paramètres, section `التذكير`
- **Préconditions :** matin déjà activé à **07:30** (onboarding, étape B) ; thème `فاتح`.
- **Étapes exactes :**
  1. HOME → ⋮ → `الإعدادات`.
  2. Vérifier `تذكير الصباح` activé avec `الوقت 07:30`. Sinon, toucher l'heure et choisir 07:30.
  3. Vérifier `تذكير المساء` activé (défaut) avec `الوقت 20:00` (défaut, non modifié).
  4. Activer `تذكير الجمعة`. Sa ligne `الوقت 09:00` (défaut) apparaît.
  5. Capturer.
- **Données :** 07:30 / 20:00 / 09:00.
- **État attendu :** titre de section `التذكير` ; groupe de 3 rappels, **chacun** avec interrupteur activé et une ligne `الوقت` (É5).
- **Éléments visibles :** titre `التذكير` et le groupe complet des 3 rappels.
- **Éléments non visibles :** section `التطبيق` (dont la ligne heure sans publicité), sélecteur d'heure ouvert, dialogue de permission, toast `تعذّرت برمجة أحد التذكيرات…`.
- **Recadrage recommandé :** **uniquement** le titre `التذكير` et sa carte (retirer l'AppBar et la section `التطبيق`).
- **Résolution :** 1080 × 2400 PNG (brut), recadré en B.3.
- **Nom de fichier :** `c6-rappels.png`
- ⏳ **Point à confirmer :** les heures 20:00 et 09:00 **seront visibles** dans l'image, puisque c'est l'UI réelle. Le texte du site ne les cite pas (décision B.1). Autre option : recadrer sur la seule ligne du matin.

---

## 4. E1–E3 — Share as Image (images réellement exportées)

### 4.1 Faits (code `github-migration`)

| | E1 | E2 | E3 |
|---|---|---|---|
| Identifiant code | `PremiumTemplate.darkLuxe` | `PremiumTemplate.emerald` | `PremiumTemplate.whiteElegant` |
| Nom affiché dans la feuille | `Dark Luxe` | `Emerald` | `White` |
| Fond fixe | `assets/premium/templates/dark_luxe.png` | `…/emerald.png` | `…/white_elegant.png` |
| Taille logique du rendu | 1086 × 1448 | 1183 × 1330 | 1086 × 1448 |
| **PNG exporté** (`toImage(pixelRatio: 3.0)`) | **3258 × 4344 px** | **3549 × 3990 px** | **3258 × 4344 px** |
| Zone de texte (fractions) | 0.16–0.84 × 0.39–0.74 | 0.15–0.85 × 0.33–0.87 | 0.16–0.84 × 0.31–0.84 |
| Couleur du texte | Blanc | `#163B2C` | `#2A2118` |
| Ambiance | Fond noir, ornements or | Fond vert, cadre ivoire, ornements or | Fond ivoire, ornements or |
| Défaut dans la feuille | Sélectionné par défaut | — | — |

**Éléments graphiques fixes (identiques dans les trois, intégrés à l'image de fond) :**
- mains en prière dorées ;
- titre `اللهم ارحم أبي` ;
- sous-titre **`أدعية لوالدي الميت`** ;
- cadres, rosaces, filets or ;
- pied de page `من تطبيق « اللهم ارحم أبي »`.

**Seul élément dynamique :** le texte du douʿā (**personnalisé**, identique à celui du HOME), en **Lateef**, taille ajustée automatiquement pour tenir en **une seule image** (`PremiumDuaPaginator.fitSinglePage`, jamais tronqué, jamais multi-pages).

**Absent :** aucun nom de proche séparé, aucune date, aucune signature autre que celle du fond.

**Format :** PNG, remis au partage natif sous le nom `dua_premium.png` (`image/png`). Le nom est **identique pour les 3 exports** : il faut renommer chaque fichier à la récupération.

**Coût :** hors ligne, le Rewarded est indisponible, donc le partage est **gratuit et immédiat, sans confirmation ni annonce** (règle B2). Aucune annonce à contourner ni à capturer.

### 4.2 Fiche E1–E3

- **ID :** E1, E2, E3
- **Écran source :** HOME → ⤴ (feuille de choix du modèle) → bouton `مشاركة كصورة` → partage natif
- **Préconditions :** HOME affiche l'id 3 personnalisé (étape E, juste après C1) ; mode avion actif.
- **Étapes exactes :**
  1. Toucher ⤴. La feuille s'ouvre avec 3 vignettes, `Dark Luxe` sélectionné.
  2. **E1** : garder `Dark Luxe`, toucher `مشاركة كصورة`, puis choisir dans la feuille système une cible **locale** qui enregistre le fichier (voir ⏳ ci-dessous). Renommer en `e1-dark-luxe.png`.
  3. **E2** : rouvrir ⤴, sélectionner `Emerald`, et procéder de même. Renommer en `e2-emerald.png`.
  4. **E3** : rouvrir ⤴, sélectionner `White`, et procéder de même. Renommer en `e3-white.png`.
- **Données :** texte `اللهم اجعل قبر أبي محمد روضةً من رياض الجنة، وانر دربه بنور هدايتك يا كريم يا رحيم.` (id 3 personnalisé, le même pour les 3).
- **État attendu :** 3 PNG aux dimensions exactes du §4.1, texte entièrement dans la zone, sans débordement.
- **Éléments visibles (dans l'image) :** fond du modèle complet + texte du douʿā.
- **Éléments non visibles :** aucune UI de l'app ni du système. Ce sont des **fichiers exportés**, pas des captures d'écran de la feuille.
- **Recadrage recommandé :** **aucun**. Les images sont utilisées telles quelles, seulement redimensionnées en B.3, et présentées **comme une seule fonctionnalité** (décision B.1).
- **Résolution :** native (3258 × 4344 / 3549 × 3990).
- **Noms de fichier :** `e1-dark-luxe.png`, `e2-emerald.png`, `e3-white.png`
- ⏳ **Récupération du fichier, à valider sur l'appareil de capture** (hors ligne) :
  - (a) cible de partage locale qui enregistre (« Fichiers » / « Enregistrer sur l'appareil », selon l'appareil) ;
  - (b) en build **debug**, récupérer le fichier temporaire créé par `share_plus` via `adb shell run-as com.joumane.allahomairhamabi` (emplacement à identifier lors de la séance).
  - **Contrôle obligatoire** : vérifier les dimensions exactes du §4.1. Une dimension différente signifie un fichier recompressé ou redimensionné par l'application cible : il faut le refaire.

---

## 5. Contrôle qualité de la séance (avant de livrer B.2)

| Contrôle | C1 | C2 | C3 | C4 | C5 | C6 | E1–E3 |
|---|---|---|---|---|---|---|---|
| Thème clair, police 100 % | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Aucune publicité, aucun toast ni snackbar | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Aucune donnée réelle (seul `محمد`) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Texte exact conforme à la fiche | id 3 perso. | 11 relations | id 3 perso. | `الجنة`, ids 3/4/9/20 | id 200 | 07:30 / 20:00 / 09:00 | id 3 perso. |
| Dimensions | 1080 × 2400 | 1080 × 2400 | 1080 × 2400 | 1080 × 2400 | 1080 × 2400 | 1080 × 2400 | §4.1 |
| Barre d'état propre (demo mode, pas d'icône avion) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — |

Le rapport B.2 devra indiquer :
- le commit exact utilisé ;
- l'appareil ou l'émulateur ;
- la version Android ;
- l'id du douʿā de C3 s'il diffère de l'id 3 ;
- les sommes SHA-256 des fichiers livrés.

---

## 6. Points à confirmer avant la séance

1. **C6** : accepter que 20:00 et 09:00 soient visibles dans l'image (UI réelle), ou recadrer sur la seule ligne du matin.
2. **C3** : même texte que C1 (id 3, recommandé pour la simplicité), ou un second douʿā personnalisé.
3. **E1–E3** : méthode de récupération des PNG exportés (a ou b du §4.2), validée sur l'appareil choisi.
4. **Stockage** des captures brutes : hors dépôt, ou dossier `docs/…` (les versions optimisées iront dans `site/` en B.3).
5. **Correction documentaire B.1** (faits É2, É4, É5, É6) : à reporter dans `LOT68_B1_VISUAL_DIRECTION.md` lors d'un prochain lot documentaire. Aucune décision validée n'est modifiée.

*Fin du protocole. Aucune capture n'a été réalisée.*
