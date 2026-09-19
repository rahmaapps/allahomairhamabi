# LOT 66 — Revue UX/UI complète (analyse uniquement)

**Application :** اللَّهُمَّ ارْحَمْ أَبِي · Flutter · RTL · arabe
**Dépôt / branche auditée :** `rahmaapps/allahomairhamabi` @ `github-migration` (arbre `c6f9a3cb0d94`)
**Date :** 14 septembre 2026
**Nature :** audit en lecture seule. **Aucune ligne de code, aucun composant, aucun asset n'a été modifié.**
**Références utilisées :** `docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md` (version dépôt, §9 faisant foi), `docs/ui_ux/LOT_3I_DUAREADSCREEN_SPEC.md`, `UI_UX_ARCHITECTURE_REVIEW.md` (historique, non normatif), et le code réellement publié (`lib/**`, `pubspec.yaml`).

> **Note de méthode.** La copie de `ETAT_CONSOLIDE_UI_UX.md` présente dans ce projet de conception était la version du 2 septembre (branche `main`, « aucune ligne de code ») — périmée. Elle a été resynchronisée depuis le dépôt avant l'audit, afin d'auditer contre la vraie source de vérité (§9, resynchronisée au LOT 3.Q). C'est le seul fichier touché, et il s'agit d'une mise à jour de référence documentaire, pas d'une modification de design ou de code.
>
> **Limite assumée :** audit par lecture du code, comme les précédents. Aucune exécution, aucun émulateur, aucune capture. Tout constat de rendu (troncature, contraste perçu, ressenti d'animation) est déduit du code et signalé comme tel.

**Convention de classification**
✅ CONFORME · 🔴 ÉCART / PROBLÈME À CORRIGER · 🟡 POINT À ARBITRER · 💡 AMÉLIORATION OPTIONNELLE · 🔒 DÉCISION VERROUILLÉE — NE PAS ROUVRIR

---

## 1. Résumé exécutif

**État global : solide.** L'architecture UX validée (Option 3 hybride, HOME hub non scrollable, bandeau `bottom:` pour زيارة القبر, onboarding 2 écrans, un point d'entrée par fonction) est **réellement implémentée**, pas seulement spécifiée. Le Design System existe en dur (`lib/theme/*`, `lib/widgets/app_*`), les 20 tokens Light et 16 tokens Dark sont fidèles au §3 au hex près, les 11 rôles typographiques sont exacts, les deux polices sont embarquées, et les écrans consomment les composants communs au lieu de styles locaux. Les bugs historiques (P0-1 blanc-sur-blanc, prénom perdu, `TextDirection.ltr` forcé, double `ThemeData`, troncature de زيارة القبر, stub de vignette) sont **tous corrigés et vérifiables**.

Les écarts restants sont **localisés et peu nombreux**. Ils se répartissent en trois familles :

1. **Le HOME n'a jamais été mis à jour sur trois points de sa propre spécification** : l'animation de renouvellement du douʿā (C1/B2) est restée l'animation d'origine (450 ms, glissement vertical de grande amplitude, carte entière déplacée, texte sacré fondu) alors que la spec la décrit comme la plus importante du produit ; le retour de copie utilise encore un `SnackBar` Material brut alors que `showAppToast` existe depuis le LOT 3.I ; et l'enregistrement du texte personnalisé au moment du favori repose sur une condition inversée, ce qui fait perdre le prénom dans la liste Favoris.
2. **L'enveloppe native n'a pas suivi le Design System** : le splash natif est encore en vert `#0E7A5B` avec une image plein cadre, alors que la décision figée dit fond identique au HOME, icône à 22 %, aucun texte, plus une variante Dark. Et l'application ne déclare **aucune localisation arabe**, donc le sélecteur d'heure — c'est-à-dire l'unique point de configuration des rappels — s'affiche avec les libellés Material anglais.
3. **Une dérive d'espacement et de finition** partagée par les écrans secondaires : marge d'écran à 16 au lieu de 20 sur quatre écrans, trois traitements différents du même chargement local, `الحالي` jamais implémenté, quelques oublis RTL résiduels.

**Le nouveau comportement de notifications validé (matin / soir / vendredi configurables, horaires configurables, contenu générique en arabe, aucune personnalisation par prénom) est conforme sur trois points sur quatre.** Le contenu est bien en arabe, générique, sans aucun prénom interpolé — aucun changement à faire là. En revanche **soir et vendredi sont aujourd'hui à heures codées en dur** (20:00 / 09:00), non exposées en UI et non persistées : c'est l'écart d'implémentation le plus net vis-à-vis de la nouvelle référence.

**Aucune refonte n'est justifiée.** Tous les correctifs recommandés sont ponctuels et tiennent dans les composants existants.

---

## 2. Audit par écran

### 2.1 Design System (fondations)

**État actuel.** `lib/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radii.dart`, `app_shadows.dart`, `app_theme.dart` + 8 composants dans `lib/widgets/`.

**Conformité**
- ✅ **Tokens couleur** — les 20 Light et 16 Dark sont au hex exact du §3. `#FFD700` et `#25C4A5` absents du Light comme spécifié. Ombres teintées `rgba(0,58,42,α)` aux 3 niveaux + `e0` en trait 1 px.
- ✅ **Typographie** — 11 rôles exacts (tailles, graisses, interlignes), `letterSpacing: 0` partout, interligne douʿā ≥ 2.0 (`duaBody` 2.05, `duaLong` 2.15), `Lateef` réservé au sacré + titre + heures, `IBMPlexSansArabic` sur 100 % du reste et posé comme police de base du `TextTheme`. Les 4 `.ttf` sont réellement déclarés dans `pubspec.yaml`.
- ✅ **Espacements / rayons** — échelle base 4 sans valeur hors-échelle dans les tokens ; 5 rayons exacts.
- ✅ **Cartes** — N1 (`hero` : `surface` + r24 + `e2` + filet or 2 px + rosace 5,5 % + padding 24) porte bien les trois signes et elle seule ; N2 padding 20 sans aucun des trois ; N3 `surfaceAlt` + `e0` sans padding propre (choix assumé pour que les séparateurs touchent les bords).
- ✅ **Boutons** — h 48, r 12, Plex 16/600, `scale .98` au pressé, `NoSplash`, jamais d'`opacity: .38`. Les rôles `text`/`destructive` restent non implémentés faute d'usage : conforme à la discipline « pas de composant inventé ».
- ✅ **Chips** — 2 variantes / 2 intensités, h 44 et 40, zone tactile 48 garantie par un `minHeight`, aucun des 4 interdits (croix, icône, compteur, bordure épaissie).
- ✅ **État vide** — gabarit 4 couches exact (filigrane 92 px à 15 %, Lateef 24, Plex 12,5, 0-1 bouton, décalage −24).
- ✅ **Toast / snackbar تراجع** — 2,5 s une ligne sans bouton / 6 s avec `تراجع`, `clearSnackBars()` pour ne jamais empiler.
- ✅ **Surlignage de recherche** — fond `#FDF0C8` avec couleur de texte forcée en `textPrimary`, donc lisible aussi en Dark : bonne décision, à conserver.

**Écarts réels**
- 🔴 **Aucune localisation arabe déclarée.** `MaterialApp` (`lib/main.dart`) ne définit ni `locale`, ni `supportedLocales`, ni `localizationsDelegates`, et `flutter_localizations` est absent de `pubspec.yaml`. Conséquence directe : tout widget Material localisé retombe en anglais — au premier chef `showTimePicker` (« Select time », AM/PM, libellés de bascule), qui est **le seul point de configuration des rappels**. La `Directionality(rtl)` est reposée à la main sur chaque écran, ce qui masque le problème de sens mais pas celui des libellés.
- 🔴 **`appBarForeground` recalculé localement dans 5 écrans** (HOME, Favoris, Recherche… en réalité Paramètres, Favoris, Lecture, Visite, HOME) avec le même commentaire dupliqué. Le raisonnement est juste (ne jamais utiliser `cs.onPrimary`, illisible en Dark) mais il n'appartient pas aux écrans : c'est une règle de la zone A/B de l'AppBar, donc de `AppTopBar`. Risque d'oubli sur tout nouvel écran.
- 🔴 **`EdgeInsets.only(left:/right:)` résiduels**, contre la règle RTL explicite du §3 : `widgets/app_snackbar.dart` (marge du snackbar) et `_ProgressIndicator` de l'onboarding. Impact visuel nul aujourd'hui (valeurs symétriques ou segments pleine largeur), mais la règle est formulée comme absolue et ces deux points sont les seuls survivants.

**Points à arbitrer**
- 🟡 **Gap des chips : 10 (document) vs 8 (code).** Le §3 écrit « gap de chips 10 » au paragraphe même qui interdit les valeurs hors base 4 (« pas de 6, 10, 14, 18 »). Le code a retenu 8 et l'a documenté. **Le code a raison** : la contradiction est dans le document. Arbitrage demandé : corriger le **document** à 8, pas le code.
- 🟡 **Extrait de résultat centré** (`TextAlign.center` dans `AppDuaResultCard`). Cohérent avec la carte sacrée, mais inhabituel pour une ligne de liste avec un ♥ en tête. Non spécifié : à trancher, pas un défaut.
- 🟡 **`in_app_review` toujours en dépendance** et `_rateApp()` présent dans `home_screen.dart` sans aucun appelant, alors que §6.12 interdit tout dialogue de notation. Même cas de figure que `_shareAppOnWhatsApp` (tranché au LOT 3.O) : à décider explicitement, supprimer ou rebrancher, pas à laisser en suspens.

**Améliorations optionnelles**
- 💡 Sous-titre du bandeau visite peint en ivoire à 85 % d'alpha (`AppTypography.label` 12 px sur `primaryPressed`). Le contraste reste largement suffisant ; un passage à l'opacité 1 serait plus aligné sur la discipline « pas de texte alpha-atténué ».
- 💡 Le nom de package est encore `test_1` et la version `1.1.0+4` — sans effet UX, mais visible à la publication.

---

### 2.2 HOME

**État actuel.** `lib/home_screen.dart` — AppBar h 56 (Lateef 25) + 4 actions + bandeau `bottom:` h 44 ; body à 4 strates ; rail latéral 108 dp en paysage.

**Conformité**
- ✅ **Structure et composition** conformes aux 6 strates du §2 : bandeau hors du `body`, ligne « pour qui » sans bouton, `دعاء آخر` dans le **pied** de la carte, `Expanded` réservé à la carte.
- ✅ **Padding d'écran 20 / 16 / 20 / 16** — le seul écran strictement conforme à « marge horizontale 20 · sous l'AppBar 16 · 16 au-dessus du bord bas ». Gaps inter-blocs à 12 partout.
- ✅ **2 chips à 50 %**, `عام` / `دعاء الجمعة`, plus aucune 3ᵉ chip.
- ✅ **Ordre des actions RTL** `⌕ ♡ ⤴ ⋮` exact ; `⋮` ouvre `الإعدادات` directement, sans menu intermédiaire (🔒) ; `⤴` **non rendue** — et non grisée — quand aucun douʿā n'est affiché.
- ✅ **Aucun `TextDirection.ltr` forcé**, aucun doublon de point d'entrée, promo WhatsApp absente du HOME.
- ✅ **`نسخ` / `مشاركة`** en paire tonale (`action`) à largeurs égales, avec **bascule verticale réellement mesurée** (`TextPainter` + `textScaler` ≥ 1,3 + seuil 132 dp) : c'est l'implémentation la plus rigoureuse du fichier.
- ✅ **Texte sacré jamais réduit, aucun fondu de bord** (LOT 3.I.B) ; zone de texte structurellement bornée par `_cardFooterReservedHeight` (56) pour qu'un douʿā long ne passe jamais derrière le pied.
- ✅ **Rosace jamais animée.**
- 🔒 **Rail paysage 108 dp** — validé sur appareil réel (LOT HOME LANDSCAPE, `ad14399`). Le `applyHeightToFirstAscent: false` limité au paysage est un correctif documenté et ciblé. **Ne pas rouvrir.**

**Écarts réels**
- 🔴 **Le texte personnalisé n'est jamais enregistré à l'ajout d'un favori.** Dans `_buildFavoriteButton`, l'ordre est : `toggleFavorite()` → `if (_isFavorite) saveFavoriteText(...)` → puis relecture de `_isFavorite`. La condition est donc évaluée sur l'**ancienne** valeur : le texte n'est sauvegardé que si le douʿā **était déjà** favori (donc au moment du **retrait**), et jamais à l'ajout. Conséquence visible : un douʿā ajouté en favori depuis le HOME apparaît dans la liste Favoris et dans l'écran de lecture avec le texte **brut du JSON**, sans le prénom saisi par l'utilisateur — exactement la « perte silencieuse » que le principe 4 interdit. Correction = deux lignes (relire l'état puis sauvegarder).
- 🔴 **Animations C1 et B2 non conformes aux règles verrouillées.** `_anim` dure **450 ms** (la spec plafonne toute animation à 320 ms, et fixe C1 à 280 ms), déplace la carte de **0,15 de sa hauteur** (≈ 60-90 dp, contre 10 dp spécifiés, et « la carte ne bouge pas d'un pixel »), enveloppe la carte **entière** dans un `FadeTransition` — donc fond le texte religieux, contre la règle A4 « peint à l'opacité 1 dès la frame 0 » — et utilise `Curves.easeInOut` / `easeOut` au lieu de la courbe unique `easeOutCubic` / `easeInOutCubic`. Enfin, le **même** mouvement vertical sert au changement de catégorie (B2), qui doit être un glissement **horizontal** de 16 dp en 240 ms : la grammaire du mouvement (horizontal = changement de contexte, vertical = renouvellement de contenu) n'est pas appliquée. C'est l'écart le plus important du HOME : il porte sur l'animation que la spec elle-même désigne comme « la plus importante du produit ».
- 🔴 **Retour de copie en `SnackBar` Material brut** (`'تم النسخ ✓'`, 1 s, style Material par défaut) alors que `showAppToast` existe depuis le LOT 3.I et est déjà utilisé par `DuaReadScreen` pour la même action. Deux retours visuels différents pour un geste identique, et une durée de 1 s contre 2,5 s spécifiées.
- 🔴 **États vide et erreur rendus dans la carte sacrée.** `_loadRandomDua` écrit `"لا يوجد دعاء حالياً"` ou `"حدث خطأ أثناء تحميل الدعاء"` dans `_currentDuaText`, donc affichés en **Lateef 29 au centre de la carte N1**, avec filet d'or et rosace — un message d'erreur habillé en contenu sacré. Idem pour le `'...'` initial, visible une frame. Le §3 prévoit un gabarit d'état vide (`AppEmptyState`, déjà utilisé par le HOME lui-même dans la feuille زيارة القبر).
- 🔴 **♥ du HOME hors gabarit.** Taille 26 (spec : icônes 24), enveloppé dans une pastille `surface` à 92 % d'alpha qui n'est spécifiée nulle part, zone tactile réelle ≈ 42 px (padding 8 + 26) donc **sous le minimum 48 × 48 « partout »**, et `_heartCtrl` anime `0.7 → 1.2` en 250 ms symétriquement à l'ajout **et** au retrait, contre `1 → 1.12 → 1` en 200 ms **sans animation au retrait** (asymétrie explicitement volontaire). Le ♥ de `DuaReadScreen` est, lui, exact : les deux ♥ du produit ne se comportent pas pareil.
- 🔴 **Sélecteur de personne de زيارة القبر : `Wrap` sans `textDirection`.** Les chips de personnes s'ordonnent donc de gauche à droite dans une feuille par ailleurs RTL. (Les `Row` voisines portent bien `textDirection: rtl` — c'est un oubli isolé, pas une tendance.)
- 🔴 **Fond des bottom sheets = `cs.surface`** (`#FFFFFF` / `#18241F`) alors que le §3 spécifie `bg` pour les bottom sheets. Deux feuilles concernées (Partage Premium, sélection de personne). Le rayon `r-hero` en haut et la poignée sont, eux, conformes.

**Points à arbitrer**
- 🟡 **Un tap de plus vers زيارة القبر.** Le bandeau ouvre une feuille de sélection de personne avant l'écran de lecture (🔒 LOT 3.F, non rouvert ici). Mais quand **une seule** personne est configurée — le cas dominant pour une app nommée « ارحم أبي » — la feuille ne propose qu'un seul choix et ne fait qu'ajouter un geste, dans le contexte précis où le principe 2 exige la fiabilité maximale (debout, au cimetière). Arbitrage proposé : **sauter la feuille quand `personsData.length == 1`**, la conserver à l'identique au-delà. Cela ne rouvre pas la décision, il l'optimise à la marge.
- 🟡 **Chips `person` utilisées comme boutons d'action** dans cette feuille (`selected: false` en permanence, le tap navigue). Le §3 dit que les chips ne doivent jamais évoquer un panneau de filtres ; ici elles n'évoquent pas un filtre mais elles n'expriment pas non plus un état. À trancher : chips acceptées dans ce rôle, ou lignes tappables.
- 🟡 **Transitions hétérogènes.** HOME → Recherche / Favoris / Paramètres / Personnes utilisent `MaterialPageRoute` (transition Material par défaut), alors que Recherche/Favoris → Lecture utilisent un glissement RTL 300 ms `easeInOutCubic` dupliqué localement. À harmoniser ou à assumer explicitement.

**Améliorations optionnelles**
- 💡 Le glissement RTL 300 ms est dupliqué à l'identique dans `search_screen.dart` et `favorites_screen.dart`, avec un commentaire reconnaissant la duplication. Une fonction `appPageRoute()` partagée supprimerait la troisième copie avant qu'elle n'apparaisse.

---

### 2.3 Onboarding

**État actuel.** `lib/screens/onboarding_screen.dart` — 2 étapes, `لمن تدعو؟` puis `تذكير يومي؟`.

**Conformité**
- 🔒 **Ordre verrouillé respecté** (LOT 3.H) — `_step == 0` = personnes, `_step == 1` = rappel. Ne pas rouvrir.
- ✅ **Sous-titre dynamique** `تدعو لـ <personne>` à l'étape rappel, repris de la première personne cochée via l'ordre d'itération du `LinkedHashSet` (LOT 3.K).
- ✅ **Rien n'est bloquant** : `التالي` jamais désactivé, `تخطّي` visible aux deux étapes, persistance au fil de l'eau (`_persistPersons` à chaque toggle, debounce 400 ms sur le prénom, purge des timers avant sortie).
- ✅ **Titres en Plex 22/600** (et non Lateef) ; **seule** exception Lateef = l'heure en 26. Exactement la spec.
- ✅ **`e0` uniquement, aucun or** : `AppCard(level: content)`, aucun emprunt aux privilèges du sacré.
- ✅ **Ligne `الوقت` qui se retire** quand le rappel est désactivé — jamais grisée.
- ✅ **Permission** : aucune demande à l'ouverture, une seule tentative pour toute la vie de l'écran (`_permissionRequestAttempted`), déclenchée uniquement par `التالي` sur l'étape rappel, jamais par `تخطّي` ; refus → **une ligne** d'information, aucun dialogue, aucune relance. Conforme à §6.12 et au LOT 3.E.1.
- ✅ **Indicateur de progression qui se remplit, ne glisse pas** ; transition 1↔2 en 280 ms `easeInOutCubic` ; sortie en fondu 300 ms sans glissement + `pushAndRemoveUntil` (onboarding inatteignable).
- ✅ **Prénom conservé après décochage** (contrôleur non vidé, réapparaît tel quel au recochage) — et la limite du modèle de persistance est documentée dans le code.
- ✅ Marge horizontale 20.

**Écarts réels**
- 🔴 **Heure du rappel réglée via `showTimePicker` non localisé** — voir §2.1 : libellés anglais dans un onboarding arabe. C'est le même défaut qu'aux Paramètres, avec un impact plus fort ici (premier lancement, première impression).

**Points à arbitrer**
- 🟡 **`تخطّي` en bouton `secondary` de largeur égale à `التالي`.** La spec dit « toujours visible », ce qui est respecté, mais un `secondary` à 50 % donne à l'action d'évitement le même poids visuel que l'action de progression. Le rôle `text` du §3 (non implémenté) serait la lecture la plus fidèle. À trancher.

**Améliorations optionnelles**
- 💡 `_possessiveLabel` est dupliqué à l'identique dans trois fichiers (onboarding, sélection de personnes, HOME sous une autre signature). Une seule source éviterait qu'un libellé diverge un jour.

---

### 2.4 Sélection des personnes

**État actuel.** `lib/screens/person_selection_screen.dart` — un écran, mode Édition, `ScaffoldMessenger` local.

**Conformité**
- ✅ **AppBar h 56, titre `تدعو لـ`, retour `→`, aucune action, aucun CTA en bas.**
- ✅ **Enregistrement immédiat** à chaque coche/décoche, debounce 400 ms sur la frappe, écriture au `focus lost` **et** dans `dispose()`.
- ✅ **Prénom écrit même vide** — le bug historique `data[person.name] = name` conditionnel est réellement corrigé.
- ✅ **Aucun `Colors.white*`** : P0-1 résolu par construction.
- ✅ **Aucun toast à la sélection** ; le contrat est porté une fois par `يُحفظ اختيارك تلقائيًا`.
- ✅ **Décochage silencieux, jamais bloquant**, y compris pour la dernière personne, avec snackbar 6 s `تراجع`.
- ✅ **`ScaffoldMessenger` local** pour que le snackbar ne survive pas à la sortie de l'écran — correctif propre, à conserver.

**Écarts réels**
- 🔴 **Le badge `الحالي` n'existe pas.** Aucune trace dans le fichier, ni de la règle de résolution par horodatage de sélection (dernière cochée = active ; si décochée, la plus récente parmi les restantes ; plus aucune = mode `عام` ; modifier un prénom sans effet). C'est un élément **entier** de la spécification close, jamais implémenté. Conséquence UX : avec plusieurs personnes cochées, rien à l'écran ne dit laquelle détermine le douʿā affiché au HOME, et l'utilisateur n'a aucun moyen de comprendre ni d'influencer ce choix.
- 🔴 **Le prénom est effacé au décochage** (`controllers[person]!.clear()`), alors que l'onboarding — le même geste, sur le même modèle de données — le **conserve** volontairement et documente ce choix. Le `تراجع` restaure le prénom, mais passé les 6 secondes la saisie est définitivement perdue. Deux écrans, deux comportements pour une action identique.
- 🔴 **Marge d'écran 16 au lieu de 20** (`EdgeInsets.all(AppSpacing.lg)`), contre « marge horizontale d'écran 20, unique et sans exception ».
- 🔴 **Champ prénom non stylé** : seul `border` est fourni à `InputDecoration`, donc `enabledBorder` et `focusedBorder` retombent sur le Material par défaut (trait gris, focus 2 px). Le champ de recherche, lui, applique bien 1,5 px → `primary` au focus. Les deux seuls champs de texte de l'app ne se ressemblent pas.

**Points à arbitrer**
- 🟡 Séparateur de liste à 8 alors que « entre composants d'un bloc 12 ». Sur 11 lignes, l'écart cumulé est visible. Choix de densité : à confirmer.

---

### 2.5 Cartes / affichage des douʿās

**État actuel.** `widgets/app_dua_result_card.dart` (Recherche + Favoris), `widgets/app_card.dart` (N1 partagée HOME / Lecture).

**Conformité**
- ✅ **Une seule carte de résultat** pour Recherche et Favoris, le ♥ en tête étant la seule différence (`showFavoriteHeart`) : les deux listes se ressemblent, comme exigé.
- ✅ Coquille N2 `e0`, extrait Lateef 22/1,75 **2 lignes max**, carte entière tappable, aucune icône, aucun chevron, aucune action copier/partager intégrée.
- ✅ **♥ cible strictement indépendante** du reste de la carte (`onFavoriteTap` distinct) — « deux cibles distinctes » respecté.
- ✅ La carte N1 est **réellement partagée** entre HOME et `DuaReadScreen` : aucune variante, aucune duplication.
- ✅ `e2` reste exclusive au contenu sacré (HOME, `DuaReadScreen`, carte visite, feuille de partage) ; aucun autre écran ne l'emprunte.

**Écarts réels** — aucun propre au composant.

**Améliorations optionnelles**
- 💡 Le ♥ de la carte de résultat n'a qu'un padding 4 autour d'une icône 20 (≈ 28 px de cible). Utilisable, mais loin des 48 exigés « partout ». Même famille de constat que le ♥ du HOME.

---

### 2.6 Lecture d'un douʿā (`DuaReadScreen`)

**État actuel.** `lib/screens/dua_read_screen.dart` — LOT 3.I, ouvert depuis Recherche et Favoris.

**Conformité** — **c'est l'écran le plus conforme du produit.**
- 🔒 Concept verrouillé respecté : carte de lecture agrandie, pas un écran de texte nu.
- ✅ AppBar h 52 sans titre, zone B vide, retour seul.
- ✅ `AppCard(level: hero)` réutilisée telle quelle, rosace incluse.
- ✅ ♥ **dans le pied de la carte**, jamais dans l'AppBar ; `UserPrefs` seule source de vérité ; retrait ne ferme jamais l'écran ; animation `1 → 1.12` en 200 ms **à l'ajout seulement** — l'asymétrie volontaire est ici correctement implémentée.
- ✅ Texte en `duaLong` (Lateef 31/2.15), RTL, centré, largeur plafonnée 340, opacité 1 en permanence, **aucun fade/blur/gradient**, scroll interne seul élément défilant, centré si le texte tient.
- ✅ Douʿā introuvable → `AppEmptyState`, jamais d'écran blanc. Lecture locale → **aucun** indicateur de chargement.
- ✅ Copie → `showAppToast` ; partage → texte simple natif ; aucun partage image ici.
- ✅ Marge horizontale 20.

**Points à arbitrer**
- 🟡 **Paire `نسخ` / `مشاركة` en `secondary` + `primary`**, alors que le HOME utilise deux `action` tonaux pour la même paire. Le §3 dit « les boutons d'action vont par paire à largeurs égales » — les largeurs le sont, les rôles non. Deux lectures possibles du même couple d'actions, à unifier dans un sens ou dans l'autre.

**Améliorations optionnelles**
- 💡 Cette paire n'a pas la bascule verticale que le HOME applique à `textScaler` ≥ 1,3. À 1,6× (plafond du §3), les libellés `نسخ` / `مشاركة` peuvent tronquer sur un écran 320 dp. Réutiliser `_buildCopyShareActions` réglerait les deux écrans d'un coup.

---

### 2.7 Recherche

**État actuel.** `lib/search_screen.dart` — champ à la place de l'AppBar.

**Conformité**
- ✅ **Le champ remplace l'AppBar** (aucun `Scaffold.appBar`, aucun titre `البحث`).
- ✅ Champ : `minHeight 44`, `r-button 12`, trait **1,5 px** → `primary` au focus, `autofocus` (clavier ouvert à l'arrivée).
- ✅ **Debounce 250 ms**, aucun bouton « rechercher », **aucun indicateur de chargement**.
- ✅ **Clavier fermé au premier défilement** (`NotificationListener<ScrollStartNotification>`).
- ✅ Résultats en `AppDuaResultCard` **sans ♥**, terme surligné par fond `#FDF0C8` uniquement — jamais par du gras ni une couleur de texte.
- ✅ **Aucun historique, aucune suggestion.**
- ✅ Aucun résultat → **deux lignes**, aucune illustration, le terme reste dans le champ (et le refus explicite d'utiliser `AppEmptyState` ici — qui imposerait un filigrane — est le bon raisonnement, documenté dans le code).
- ✅ Retour depuis un résultat → état intégralement restauré (le `State` survit au `push`), clavier fermé avant transition.
- ✅ Aucune animation de mise à jour de liste (S2).
- ✅ Chiffres occidentaux dans le compteur (🔒 décision verrouillée).

**Écarts réels**
- 🔴 **La croix ✕ apparaît avec 250 ms de retard.** Sa visibilité dépend de `_controller.text.isEmpty`, mais le seul `setState` du fichier est **à l'intérieur** du timer de debounce. Tant que le debounce n'a pas expiré, le champ contient du texte sans que la croix soit rendue — et inversement, elle reste visible 250 ms après un effacement. Correctif minimal : un `setState` immédiat sur la visibilité, sans toucher au debounce de la recherche elle-même.
- 🔴 **Glyphe ⌕ absent de l'état initial.** La spec demande « glyphe ⌕ + une ligne `ابحث في N دعاءً` » ; le code ne rend que la ligne de texte. L'écran initial est donc plus nu que spécifié. (Un `prefixIcon` existe bien dans le champ, mais ce n'est pas le glyphe de l'état initial.)
- 🔴 **Marge de liste 16 au lieu de 20** (`EdgeInsets.all(AppSpacing.lg)`), et padding du champ en 16 également.

**Améliorations optionnelles**
- 💡 Le compteur affiche `ابحث في 0 دعاء` pendant le chargement du JSON (`_all` vide avant `_initData`). Invisible si le chargement est rapide, faux sinon.
- 💡 `onPressed: _controller.clear()` sur un `IconButton` : selon la plateforme, le bouton peut prendre le focus, ce qui contredit « vide le champ **en conservant le focus** ». À vérifier sur appareil ; un `_focusNode.requestFocus()` explicite le garantirait.

---

### 2.8 Favoris

**État actuel.** `lib/favorites_screen.dart`.

**Conformité**
- ✅ AppBar h 52, `المفضلة`, **aucune icône d'action** — ni tri, ni filtre, ni « tout supprimer », ni l'ancien `تحديث`.
- ✅ Carte identique à la recherche + ♥ en tête, toujours plein.
- ✅ Ordre plus récent d'abord (`getFavoriteIds().reversed`), non modifiable.
- ✅ Retrait **immédiat sans dialogue** + snackbar 6 s `تراجع` restaurant la carte **à sa position d'origine** (`insert(index, dua)`), avec `ScaffoldMessenger` local.
- ✅ Tap sur le contenu → `DuaReadScreen`, ♥ cible indépendante, **resynchronisation au retour** (`_refresh()` après le `push`).
- ✅ État vide : `AppEmptyState` avec glyphe ♡ et **une seule ligne** expliquant le geste, aucun CTA, aucune illustration.

**Écarts réels**
- 🔴 **`RefreshIndicator` (pull-to-refresh) non spécifié.** La liste est locale et déjà resynchronisée au retour de la lecture ; ce geste n'a rien à rafraîchir. Il introduit de surcroît un spinner Material circulaire dans un écran dont l'AppBar a été délibérément vidée de toute action de rafraîchissement.
- 🔴 **`CircularProgressIndicator` au chargement**, alors que Recherche et `DuaReadScreen` refusent explicitement tout indicateur pour la même lecture locale. Trois écrans, trois traitements du même cas (spinner / rien / cadre vide).
- 🔴 **Marge de liste 16 au lieu de 20.**
- 🔴 **Conséquence du bug du HOME** (§2.2) : les favoris ajoutés depuis le HOME s'affichent ici avec le texte brut, sans le prénom. L'écran n'est pas en cause, mais c'est ici que le défaut se voit.

---

### 2.9 Paramètres

**État actuel.** `lib/settings_screen.dart` — 2 sections, 6 lignes.

**Conformité**
- 🔒 **2 sections / 6 lignes** (`تدعو لـ` retiré au LOT 3.G, `بعد الظهر` supprimé partout) — verrouillé, non rouvert.
- ✅ Titres de section **hors carte** ; groupes en N3 (`settingsGroup`) ; séparateurs 1 px pleine largeur, absents après la dernière ligne.
- ✅ **Enregistrement immédiat**, aucun bouton `حفظ`, aucun message de confirmation, aucune navigation forcée.
- ✅ Ligne `الوقت` visible **uniquement** si `تذكير الصباح` est actif — elle se retire, jamais grisée.
- ✅ Aucun Premium, aucune promo, aucune notation, aucune langue, aucun compte, aucune statistique.
- ✅ `المظهر` branché sur `ThemeNotifier`, `عن التطبيق` et `مشاركة التطبيق` en lignes tappables pleine largeur avec chevron RTL `‹`.
- ✅ **Un rappel qui échoue à se planifier est explicitement repassé à « désactivé »** (état + persistance) plutôt que laissé faussement actif : excellent traitement d'erreur, à conserver.
- ✅ Vendredi replanifié sur la **prochaine occurrence calendaire réelle**, jamais `+7 jours` ; `enableFriday` par défaut `false`.

**Écarts réels**
- 🔴 **Soir et vendredi ne sont pas configurables** — voir §2.10, c'est l'écart principal de cette revue.
- 🔴 **`showTimePicker` non localisé** (§2.1).
- 🔴 **Marge d'écran 16 au lieu de 20.**
- 🔴 **L'interrupteur n'est actionnable que sur lui-même**, pas sur toute la largeur de sa ligne comme le spécifie le §4. Les lignes `تذكير المساء` / `تذكير الجمعة` sont de simples `Row` sans `InkWell` — contrairement aux lignes de liens, qui sont bien tappables en entier. Cible utile ≈ 60 × 48 sur une ligne de 320 dp.
- 🔴 **`SnackBar` Material brut** pour l'erreur de planification et les deux erreurs d'ouverture de `عن التطبيق` (3 occurrences), alors que le DS fournit toast et snackbar. Les messages dépassent aussi la « une seule ligne » du toast.
- 🔴 **`_ThemeRow` utilise un `DropdownButton` Material** (le code le reconnaît : « aucun composant de sélection à 3 options n'existe dans le Design System »). Le menu déroulant ouvre une surface Material non thémée, dans un écran par ailleurs entièrement aux tokens. Constat honnête, mais c'est le seul endroit où le DS est mis en défaut par manque de composant.

**Points à arbitrer**
- 🟡 **Absence de test de rendu de l'écran** (`_bootstrap()` bloque sur `NotificationService.ensureInitialized()`, non mockable simplement). Déjà documenté ; devient plus sensible si les horaires soir/vendredi deviennent configurables.

---

### 2.10 Notifications et réglages associés

**Référence à appliquer (validée, non rediscutée ici) :** matin, soir et vendredi **configurables** · **horaires configurables** · notifications **génériques** · contenu **en arabe** · **aucune personnalisation par prénom**.

**État actuel.** `lib/notification_service.dart` (3 canaux, `zonedSchedule` + `matchDateTimeComponents`, fuseau IANA réel, repli exact → inexact), `settings_screen.dart`, `user_prefs.dart`.

**Conformité à la référence validée**
- ✅ **Contenu en arabe** — les 3 rappels ont titre et corps en arabe, dont deux versets.
- ✅ **Notifications génériques, aucune personnalisation par prénom.** `_reminderContentFor` retourne des chaînes **constantes** ; aucune interpolation, aucune lecture de `personsData`, aucun appel à `DuaPersonalizer` dans tout le service. Il n'y a **rien à retirer** : la décision est déjà respectée par construction.
- ✅ **Matin entièrement configurable** (activation + heure persistée `morningHour`/`morningMinute`, défaut 09:00).
- ✅ **Soir et vendredi activables/désactivables** indépendamment, avec persistance (`enableEvening`, `enableFriday`).
- ✅ Fiabilité de planification exemplaire : fuseau réel résolu via `flutter_timezone` (DST correct, y compris le motif inversé `Africa/Casablanca`), récurrence déléguée nativement, annulation avant replanification, repli inexact, `false` remonté à l'UI en cas d'échec réel.
- ✅ `بعد الظهر` totalement supprimé (UI, persistance, canal, planification) — à ne pas réintroduire.

**Écarts réels**
- 🔴 **Les horaires du soir et du vendredi ne sont pas configurables.** `settings_screen.dart` les fixe en `static const` (`_eveningTime = 20:00`, `_fridayTime = 09:00`), ne les expose dans aucune UI et ne les persiste nulle part ; `user_prefs.dart` documente explicitement « heure fixe non persistée ». C'est l'écart direct avec la référence validée (« matin, soir et vendredi configurables ; horaires configurables »). Correction : deux lignes `الوقت` supplémentaires reprenant **strictement** le pattern déjà validé du matin (Switch + ligne d'heure qui se retire), plus deux paires de clés dans `UserPrefs`, plus le passage de ces valeurs à `scheduleDailyReminder` / `scheduleWeeklyReminder` — qui acceptent déjà `hour`/`minute` en paramètres. Aucun composant nouveau.
- 🔴 **`showTimePicker` non localisé** (§2.1) : conséquence directe, la configuration d'horaires se fait dans un sélecteur anglais. Ce point est **bloquant fonctionnellement** si l'on rend trois horaires configurables au lieu d'un.
- 🔴 **Duplication du contenu des rappels.** `_reminderContentFor` (rappels planifiés) et `showPeriodReminder` (affichage immédiat) portent les **mêmes** titres/corps en deux copies, avec un commentaire assumant la duplication. Risque réel de divergence à la prochaine retouche de texte. `showPeriodReminder` n'a par ailleurs plus d'appelant identifié dans `lib/`.
- 🔴 **`main.dart` : retours de notification en `SnackBar` Material brut**, longs, hors DS (`'تم تجاهل التذكير — نسأل الله أن يرحم والدك.'`, `'نسأل الله أن يرحم والدك… سنذكّرك لاحقًا إن شاء الله.'`), et le message de migration des favoris fait trois lignes. Le toast du DS est prévu pour une ligne.
- 🔴 **Action `open` d'une notification : `pushNamed('/home')`** sans purger la pile. Répété, cela empile des HOME (le retour ramène sur un HOME précédent). `pushNamedAndRemoveUntil` serait le comportement attendu.

**Points à arbitrer**
- 🟡 **« Génériques » : `لوالدك` (« pour ton père »).** Les trois contenus s'adressent au père, alors que l'app gère 11 relations (mère, grands-parents, enfants, conjoint…). Ce n'est **pas** une personnalisation par prénom — la décision validée est respectée — mais un utilisateur ayant coché uniquement `أمي` recevra un rappel formulé au masculin paternel. **Je ne rouvre pas la décision** ; je signale que « générique » peut se lire de deux façons (générique = non nominatif, ou générique = non relationnel). Si la seconde lecture est voulue, la correction est purement rédactionnelle, sur trois chaînes constantes. Même remarque pour les deux snackbars de `main.dart`.
- 🟡 **Emojis dans les titres et corps** (🌅 🤲 🕌 💛 ✨). Aucun autre point du produit n'en utilise, et le DS n'en prévoit pas. Le contenu étant validé, je ne le remets pas en cause — simple signalement de cohérence.
- 🟡 **Demande d'alarme exacte à chaque activation.** `_requestExactAlarmIfNeeded()` ouvre l'écran système « Alarmes et rappels » lors de l'activation d'un rappel si la permission manque — donc potentiellement **trois fois** (matin, soir, vendredi). Non bloquant et documenté, mais c'est une sortie hors app, dans un écran dont la spec proscrit tout dialogue. À arbitrer : une seule sollicitation par session.

---

### 2.11 دعاء زيارة القبر (Grave Visit)

**État actuel.** `lib/screens/grave_visit_read_screen.dart` + feuille de sélection dans `home_screen.dart`.

**Conformité**
- 🔒 **Pas une catégorie** : bandeau nommé + écran plein. Aucune chip, aucun onglet, retiré de la rangée de filtres.
- 🔒 **Aucune action** — ni copie, ni partage, ni favori, ni `دعاء آخر`. Vérifié dans le code et couvert par test.
- 🔒 **Wake lock non activé** — décision verrouillée, aucun package, aucune référence. Conforme.
- 🔒 **Aucune attribution ni source affichée** (décision LOT 3.F remplaçant le `رواه مسلم` du document). Conforme.
- ✅ AppBar h 52 sans titre, retour seul ; **N2 délibérément vide** ; carte dédiée `surface` + r24 + `e2` + filet or 2 px + ✦ fixe, **sans rosace** (l'usage d'une carte locale plutôt que `AppCard(hero)` est ici **justifié** : la rosace est interdite sur cet écran).
- ✅ Texte Lateef 27/2.0 centré, seul élément défilant, **pleinement opaque** (LOT 3.J), largeur plafonnée 340, jamais réduit.
- ✅ `SafeArea(top: false)` pour que la dernière ligne remonte au-dessus de la barre de navigation — correctif ciblé, à conserver.

**Écarts réels**
- 🔴 **Douʿā introuvable → écran blanc.** `snap.data == null` retourne `SizedBox.shrink()`, c'est-à-dire un écran vide sous une AppBar — contre « jamais d'écran vide ». Le cas est **atteignable** : l'audit d'architecture note que le bloc `general` n'a pas de douʿā `grave_visit`, et `.first` sur une liste vide est déjà protégé mais sans repli visible. `AppEmptyState` est le gabarit prévu, et il est déjà utilisé par la feuille amont.
- 🔴 **`CircularProgressIndicator`** pour la même lecture locale que `DuaReadScreen`, qui le refuse explicitement. Même incohérence qu'aux Favoris.
- 🔴 **Marge d'écran 16 autour de la carte** au lieu de 20.
- 🔴 **`Wrap` sans `textDirection`** dans la feuille de sélection (§2.2).

**Points à arbitrer**
- 🟡 Le tap supplémentaire quand une seule personne est configurée (§2.2).

---

### 2.12 Partage / Premium Share

**État actuel.** Bottom sheet dans `home_screen.dart` + `premium_templates.dart` + `widgets/premium_export_card.dart`.

**Conformité** — **très proche de la spec, littéralement.**
- ✅ **Un bottom sheet, jamais un écran** ; le douʿā reste visible derrière le voile.
- ✅ **Une seule icône `⤴`**, non rendue s'il n'y a pas de douʿā.
- ✅ **Aucun écran de présentation, aucun badge « PREMIUM », aucun prix, aucun verrou décoratif.**
- ✅ **3 vignettes 74 × 104 à poids strictement égal**, `spaceEvenly`, ordre RTL, pas de carrousel.
- ✅ **Sélection = 3 signaux simultanés** — anneau 2 px, pastille `✓`, libellé en 600 ; un seul à la fois, aucune désélection ; persistée (`share_template`) et relue au démarrage avec repli Dark Luxe.
- ✅ **Feedback à deux états seulement** : `جارٍ التحضير…` **uniquement au-delà de 400 ms**, bouton de taille strictement constante (`double.infinity` × 48), succès = la feuille système elle-même, échec = **une ligne d'erreur au-dessus du bouton**, aucun dialogue, aucun snackbar, feuille laissée ouverte pour réessayer.
- ✅ **Mécanisme natif uniquement** ; annulation = retour à l'écran précédent sans perte d'état ; exactement une image.
- ✅ Pipeline d'export correct (LOT 3.L) : `OverflowBox` + `IgnorePointer`/`Opacity` (et non `Offstage`), `RepaintBoundary` layouté à `fixedTemplateSize`, retry borné sur `debugNeedsPaint`, inset de navigation système pris en compte.
- ✅ **Aucun template redessiné** ; vignettes = vraies réductions des PNG complets.
- 🔒 Architecture de rendu Phase 11 (`duaTextZone`, `duaTextColor`, `fitSinglePage()`, `ClipRect`) conservée.

**Écarts réels**
- 🔴 **Fond de la feuille en `cs.surface` au lieu de `bg`** (§2.2) — seul écart de cette section.

**Améliorations optionnelles**
- 💡 La feuille n'a ni titre ni libellé d'intention : conforme à « les templates sont montrés, pas vendus », mais à l'ouverture trois vignettes nues sans un mot demandent un instant de décodage. À laisser tel quel si l'intention est la sobriété maximale.

---

### 2.13 RTL et typographie arabe

**Conformité**
- ✅ **Aucun `TextDirection.ltr` forcé** dans tout `lib/` — le bug historique est réellement éliminé.
- ✅ `Directionality(rtl)` sur tous les écrans ; `textDirection: rtl` explicite sur les `Row` et les `Text` porteurs de contenu.
- ✅ Retour `→` (`Icons.arrow_forward`) et chevron de progression `‹` (`Icons.chevron_left`) partout — sens RTL correct.
- ✅ Icônes non directionnelles (♡, ⌕, ⤴, ⋮) jamais retournées.
- ✅ Heures en lecture LTR (`HH:mm`) dans un flux RTL, chiffres occidentaux (🔒).
- ✅ `letterSpacing: 0` sur **tous** les rôles, aucun italique, aucun all-caps.
- ✅ Interligne du douʿā ≥ 2.0 sans exception ; aucune hauteur figée sur les blocs de texte arabe (la `SizedBox(height: 20)` de la ligne « pour qui » a été retirée précisément parce qu'elle rognait les glyphes — bon réflexe, à conserver).
- ✅ Largeur de lecture arabe plafonnée à 340 dp sur les deux écrans de lecture longue.
- ✅ `textScaler` suivi : mesure réelle par `TextPainter` sur la paire d'actions du HOME.

**Écarts réels**
- 🔴 **Aucune localisation arabe** (§2.1) — c'est le vrai trou RTL/i18n du produit : les surfaces Material non écrites à la main (sélecteur d'heure, libellés d'accessibilité, menu déroulant du thème) restent en anglais et en géométrie LTR interne.
- 🔴 **`Wrap` sans `textDirection`** (feuille زيارة القبر) — ordre des chips inversé.
- 🔴 **`EdgeInsets.only(left:)` résiduels** (§2.1).

**Améliorations optionnelles**
- 💡 Les bottom sheets sont des routes distinctes : elles n'héritent pas de la `Directionality` de l'écran appelant. Le code compense en posant `textDirection` sur chaque descendant — ça fonctionne, mais un seul `Directionality(rtl)` en tête de `builder` serait plus robuste pour les futurs ajouts. Une localisation globale `ar` rendrait le point sans objet.

---

### 2.14 États vides, chargement, erreur, succès

**Conformité**
- ✅ Gabarit unique `AppEmptyState` conforme au §3 et **réellement partagé** (Favoris, lecture introuvable, feuille visite sans personne).
- ✅ Favoris vide : une ligne expliquant le geste, aucun CTA, aucune illustration.
- ✅ Recherche sans résultat : deux lignes, aucun filigrane, terme conservé — et le refus argumenté du gabarit générique est le bon arbitrage.
- ✅ Recherche / `DuaReadScreen` : **aucun** indicateur de chargement pour une lecture locale.
- ✅ Échec de partage Premium : ligne inline au-dessus du bouton, feuille utilisable, réessai possible.
- ✅ Échec de planification de rappel : rappel repassé à désactivé **et** utilisateur informé — jamais un état faussement actif.
- ✅ Succès de copie : toast 2,5 s une ligne sans bouton (`DuaReadScreen`).
- ✅ Succès de partage : la feuille système **est** la confirmation, aucun message ajouté.

**Écarts réels**
- 🔴 **Chargement local traité de trois façons différentes** : spinner (Favoris, Visite, Paramètres), rien (Recherche), cadre vide une frame (`DuaReadScreen`). Un seul comportement doit être retenu — la spec penche clairement pour « rien ».
- 🔴 **Deux états sans gabarit** : HOME vide/erreur rendu **dans la carte sacrée** (§2.2), Visite introuvable rendu en **écran blanc** (§2.11).
- 🔴 **Succès de copie à deux visages** : toast DS sur `DuaReadScreen`, `SnackBar` Material 1 s sur le HOME.

---

### 2.15 Cohérence avec le parcours utilisateur global

- ✅ Premier lancement → `/onboarding` → `pushAndRemoveUntil('/home')` : onboarding inatteignable ensuite, aucun résidu au HOME.
- ✅ Aucun dialogue au premier lancement ; permission notifications demandée **une seule fois**, sur action explicite, jamais via `تخطّي`.
- ✅ HOME avec zéro personne : **même ligne, même place, même géométrie** (`ادعُ لمن تحب · اختيار`), jamais promue en bouton.
- ✅ Un point d'entrée par fonction : plus aucun doublon Favoris ni export image.
- ✅ Retours d'écran cohérents : retour de Personnes reconstruit le deck et renouvelle la carte ; retour de Favoris relit l'état ♥ du douʿā courant ; retour de lecture resynchronise la liste de favoris.
- ✅ `مشاركة التطبيق` rebranché en partage natif depuis Paramètres (LOT 3.O), ancien code mort WhatsApp supprimé.
- 🟡 `تدعو لـ` n'existe plus dans Paramètres (🔒 LOT 3.G) : la sélection des personnes n'a donc **qu'un** point d'entrée, la ligne du HOME. Cohérent avec « un point d'entrée par fonction », mais le §1 de la roadmap décrit encore « deux entrées ». **Écart documentaire**, pas applicatif : c'est le §1 qu'il faut aligner sur le LOT 3.G.
- 🟡 `الحالي` manquant (§2.4) : dans un parcours multi-personnes, l'utilisateur ne peut relier le douʿā affiché à la personne qui le détermine.

---

## 3. Décisions déjà respectées — à ne pas modifier

1. 🔒 Navigation Option 3 hybride, HOME hub non scrollable, `⌕ ♡ ⤴ ⋮`, `⋮` → `الإعدادات` direct sans menu.
2. 🔒 `دعاء زيارة القبر` = bandeau `bottom:` + écran plein, jamais une chip ni un onglet ; **aucune action** sur cet écran ; aucune attribution ; **wake lock non activé**.
3. 🔒 Ordre de l'onboarding `لمن تدعو؟` → `تذكير يومي؟`, avec sous-titre dynamique.
4. 🔒 Chiffres occidentaux 0-9 dans toute l'interface fonctionnelle, contenu religieux jamais altéré.
5. 🔒 Paramètres à 2 sections / 6 lignes ; `بعد الظهر` supprimé ; `تدعو لـ` retiré de cet écran ; aucun bouton `حفظ`.
6. 🔒 `e2` exclusive au contenu sacré ; `Lateef` réservé au sacré + titre + heures ; aucune troisième police.
7. 🔒 Texte du douʿā jamais réduit ; **aucun fade/blur/gradient** sur le texte religieux (HOME, `DuaReadScreen`, Visite — règle uniforme).
8. 🔒 `DuaReadScreen` = carte de lecture agrandie ; ♥ dans le pied, jamais dans l'AppBar ; `duaLong` ; pas de partage image.
9. 🔒 3 templates Premium non redessinés ; une seule image ; mécanisme natif ; architecture de rendu Phase 11 conservée ; feedback à deux états.
10. 🔒 Aucun dialogue au premier lancement, aucune notation, aucune promotion Premium interruptive.
11. 🔒 Rosace jamais animée.
12. 🔒 Rail paysage 108 dp du HOME, validé sur appareil réel ; portrait inchangé.
13. 🔒 Notifications : contenu arabe générique, **aucune personnalisation par prénom** — déjà conforme, rien à faire.
14. ✅ Tous les bugs du §6 du document sont réellement corrigés (P0-1, prénom conditionnel, troncature, titres de section, `TextDirection.ltr`, stub de vignette, double `ThemeData`).

**Ne rien toucher non plus** à ces implémentations de qualité : la bascule mesurée `نسخ`/`مشاركة`, les `ScaffoldMessenger` locaux, le `viewPaddingOf` des feuilles, le repli exact→inexact et le fuseau IANA réel, le rappel repassé à désactivé en cas d'échec, le surlignage à couleur de texte forcée, le `SafeArea(top: false)` de la Visite, le refus du gabarit générique pour « aucun résultat ».

---

## 4. Corrections prioritaires

### P0 — critique

| # | Écran | Problème |
|---|---|---|
| **P0-A** | HOME | Texte personnalisé **non enregistré** à l'ajout en favori (condition évaluée sur l'ancienne valeur de `_isFavorite`) → prénom perdu dans Favoris et en lecture. Perte silencieuse. |
| **P0-B** | HOME | Animations **C1 et B2** non conformes aux règles verrouillées : 450 ms (> 320 max), glissement vertical ≈ 0,15× la hauteur de carte (spec 10 dp), carte entière déplacée, texte sacré fondu (règle A4), courbes hors palette, et B2 vertical au lieu d'horizontal 16 dp / 240 ms. |
| **P0-C** | Enveloppe native | **Splash** encore en `#0E7A5B` + image plein cadre, contre la décision figée (fond identique au HOME `#FFFBF1` / `#16211C`, icône centrée à 22 % de la plus petite dimension, aucun texte) ; **aucune variante Dark**. Première impression du produit, et couleur hors palette. |

### P1 — importante

| # | Écran | Problème |
|---|---|---|
| **P1-A** | Paramètres / Notifications | Horaires **soir et vendredi non configurables** (codés en dur, non persistés) — écart direct avec la référence validée. |
| **P1-B** | Global | **Aucune localisation arabe** (`flutter_localizations`, `locale`, `supportedLocales`, `localizationsDelegates` absents) → `showTimePicker` et les surfaces Material localisées en anglais. Bloquant fonctionnel pour P1-A. |
| **P1-C** | Personnes | **Badge `الحالي` et règle de personne active par horodatage entièrement absents.** |
| **P1-D** | Personnes | Prénom **effacé au décochage**, alors que l'onboarding le conserve. |
| **P1-E** | Favoris · Recherche · Paramètres · Personnes · Visite | Marge d'écran **16 au lieu de 20** (« unique et sans exception »). |
| **P1-F** | HOME · Paramètres · `main.dart` | **`SnackBar` Material bruts** (6 occurrences) au lieu du toast / snackbar du DS ; copie à 1 s contre 2,5 s. |
| **P1-G** | Visite · HOME | États **vide/erreur hors gabarit** : écran blanc (Visite), message d'erreur dans la carte sacrée (HOME). |
| **P1-H** | HOME | ♥ hors gabarit : cible ≈ 42 px (< 48), taille 26, animation `0.7→1.2` **symétrique** au lieu de `1→1.12` **asymétrique**. Le ♥ de `DuaReadScreen` est la référence correcte. |
| **P1-I** | HOME (feuille visite) | `Wrap` sans `textDirection` → chips de personnes en ordre LTR. |
| **P1-J** | Paramètres | Interrupteurs non actionnables sur toute la largeur de la ligne. |

### P2 — amélioration

| # | Écran | Problème |
|---|---|---|
| **P2-A** | Recherche | Croix ✕ affichée/masquée avec 250 ms de retard (visibilité liée au debounce) ; glyphe ⌕ absent de l'état initial. |
| **P2-B** | Favoris · Visite · Paramètres | `CircularProgressIndicator` sur lecture locale, et `RefreshIndicator` non spécifié aux Favoris → uniformiser sur « aucun indicateur ». |
| **P2-C** | Global | Fond des bottom sheets en `surface` au lieu de `bg`. |
| **P2-D** | Personnes · Onboarding | Champ prénom aux bordures Material par défaut (incohérent avec le champ de recherche 1,5 px). |
| **P2-E** | Notifications | Contenu des rappels **dupliqué** (`_reminderContentFor` / `showPeriodReminder`, ce dernier sans appelant) ; action `open` en `pushNamed` sans purge de pile. |
| **P2-F** | Global | `appBarForeground` recalculé dans 5 écrans → à centraliser dans `AppTopBar`. |
| **P2-G** | Global | `EdgeInsets.only(left:)` résiduels (`app_snackbar.dart`, `_ProgressIndicator`). |
| **P2-H** | Enveloppe native | `adaptive_icon_background: #0E7A5B` hors palette (attendu `#006A4E`) ; variante Dark de l'icône toujours non produite. |
| **P2-I** | Global | Transitions de navigation hétérogènes (`MaterialPageRoute` vs glissement RTL 300 ms dupliqué deux fois). |
| **P2-J** | HOME | `in_app_review` + `_rateApp()` en code mort, contre §6.12 → décider : supprimer ou rebrancher. |

---

## 5. Recommandations finales

1. **Traiter P0-A avant tout.** C'est le seul défaut qui fait perdre une donnée saisie par l'utilisateur, dans une app dont la promesse est de nommer le défunt. Correction : deux lignes.
2. **Aligner C1/B2 sur leur propre spécification (P0-B), puis les regarder.** Le document signale depuis le début que C1 doit être jugée à l'œil. Le corriger d'abord (280 ms, 10 dp, entrée par le bas, carte immobile, texte à l'opacité 1, `easeOutCubic`), puis valider sur appareil ; B2 en horizontal 16 dp / 240 ms rétablit la grammaire du mouvement, qui est aujourd'hui muette parce que les deux gestes se ressemblent.
3. **Faire la localisation arabe (P1-B) avant de rendre les horaires configurables (P1-A).** L'ordre inverse livrerait trois sélecteurs d'heure anglais au lieu d'un. Les deux pris ensemble forment un lot cohérent « réglages de rappels » qui répond exactement à la référence validée.
4. **Reprendre le splash (P0-C) et la couleur d'icône adaptative (P2-H) dans le même geste** : ce sont les deux seuls endroits où le produit affiche une couleur absente du Design System.
5. **Passer une fois sur les finitions transversales (P1-E, P1-F, P1-G, P2-B, P2-C).** Prises isolément ce sont des broutilles ; ensemble elles constituent le ressenti « pas tout à fait fini » sur les écrans secondaires, et elles se corrigent mécaniquement, sans décision de design.
6. **Trancher `الحالي` (P1-C) explicitement.** Soit on l'implémente comme spécifié (badge informatif + horodatage), soit on le retire de la spec parce que l'app est en pratique mono-personne. Le laisser spécifié-non-implémenté est le seul mauvais choix.
7. **Ne pas élargir le périmètre.** رمضان, `عن التطبيق` interne, variante Dark de l'icône restent hors sujet et ne bloquent rien.

**Ce que je recommande de ne PAS faire** : toucher à la structure du HOME, aux templates Premium, au mode de lecture de زيارة القبر, à l'ordre de l'onboarding, à la règle des chiffres, au périmètre des Paramètres, au contenu des notifications, ou introduire un composant de plus dans le DS (sauf éventuellement le sélecteur à 3 options réclamé par `المظهر`, et uniquement si `DropdownButton` est jugé gênant en usage réel).

---

## 6. Périmètre d'implémentation recommandé

*(à ne pas implémenter dans ce lot — cadrage pour la décision)*

| # | Écran / composant | Problème | Correction recommandée | Impact | Fichiers probablement concernés |
|---|---|---|---|---|---|
| P0-A | HOME — ♥ | Texte personnalisé non sauvegardé à l'ajout | Relire l'état persisté **avant** de décider, puis `saveFavoriteText` si le douʿā est **devenu** favori | Favoris et lecture affichent enfin le texte personnalisé | `lib/home_screen.dart` (`_buildFavoriteButton`) |
| P0-B | HOME — C1/B2 | Animations hors règles verrouillées | C1 : 280 ms, translation 10 dp vers le haut, `easeOutCubic`, **carte immobile**, `FadeTransition` porté par le **support** et non par le texte. B2 : glissement **horizontal** 16 dp RTL, 240 ms, `easeInOutCubic`. Deux contrôleurs distincts | Conformité + la carte cesse de sauter à chaque `دعاء آخر` | `lib/home_screen.dart` (`_anim`, `_fade`, `_slide`, `duaCard`, `_setCategory`) |
| P0-C | Splash natif | Fond vert hors palette + image plein cadre, pas de Dark | Fond `#FFFBF1` / `#16211C`, icône centrée à 22 % de la plus petite dimension (borné 72-160 dp), aucun texte, bloc `android_12` inclus, puis régénération | Première impression alignée sur le HOME | `pubspec.yaml` (`flutter_native_splash`), assets de splash, `android/app/src/main/res/**` |
| P1-A | Paramètres / Notifications | Horaires soir + vendredi non configurables | Deux lignes `الوقت` supplémentaires **strictement calquées** sur le pattern matin (Switch + ligne qui se retire) ; clés `eveningHour/Minute`, `fridayHour/Minute` avec défauts 20:00 / 09:00 ; passer ces valeurs aux méthodes existantes | Répond à la référence validée ; aucun composant nouveau | `lib/settings_screen.dart`, `lib/user_prefs.dart` |
| P1-B | Global | Aucune localisation arabe | Ajouter `flutter_localizations`, `locale: Locale('ar')`, `supportedLocales`, `localizationsDelegates` ; envisager de retirer les `Directionality(rtl)` devenus redondants | Sélecteur d'heure et surfaces Material en arabe, RTL par défaut | `pubspec.yaml`, `lib/main.dart` |
| P1-C | Personnes | `الحالي` et personne active absents | Horodatage de sélection persisté ; badge informatif non tapable, un seul à l'écran ; règles de bascule et de repli `عام` ; `تراجع` restaurant aussi l'active antérieure | Le parcours multi-personnes devient lisible | `lib/screens/person_selection_screen.dart`, `lib/user_prefs.dart`, lecture au HOME |
| P1-D | Personnes | Prénom effacé au décochage | Ne pas vider le contrôleur (comportement de l'onboarding) | Cohérence entre deux écrans jumeaux ; plus de perte de saisie | `lib/screens/person_selection_screen.dart` (`_uncheck`) |
| P1-E | 5 écrans | Marge 16 au lieu de 20 | `AppSpacing.lg` → `AppSpacing.xl` sur les paddings d'écran | Rythme horizontal unifié | `favorites_screen.dart`, `search_screen.dart`, `settings_screen.dart`, `person_selection_screen.dart`, `grave_visit_read_screen.dart` |
| P1-F | HOME, Paramètres, `main.dart` | `SnackBar` Material bruts | `showAppToast` pour la copie ; messages réduits à une ligne ; snackbar DS pour l'erreur de planification | Un seul langage de retour dans tout le produit | `home_screen.dart`, `settings_screen.dart`, `main.dart` |
| P1-G | Visite, HOME | États vide/erreur hors gabarit | `AppEmptyState` pour « douʿā introuvable » (Visite) et pour les états vide/erreur du HOME, hors de la carte sacrée | Plus jamais d'écran blanc ni d'erreur en Lateef 29 | `grave_visit_read_screen.dart`, `home_screen.dart` |
| P1-H | HOME — ♥ | Hors gabarit | Icône 24 dans une cible 48 × 48, retirer la pastille non spécifiée, `1 → 1.12 → 1` en 200 ms **à l'ajout seulement** (recopier `dua_read_screen.dart`) | Les deux ♥ du produit se comportent enfin pareil | `lib/home_screen.dart` (`_buildFavoriteButton`, `_heartCtrl`) |
| P1-I | Feuille visite | `Wrap` LTR | `textDirection: TextDirection.rtl` (ou `Directionality` en tête de `builder`) | Ordre de lecture correct | `lib/home_screen.dart` (`_openGraveVisitPersonPicker`) |
| P1-J | Paramètres | Interrupteur non plein-largeur | Envelopper la ligne dans un `InkWell` qui bascule la valeur (motif déjà en place sur `_SettingsLinkRow`) | Cible conforme, geste plus simple | `lib/settings_screen.dart` (`_SettingsSwitchRow`, `_MorningReminderRows`) |
| P2-A | Recherche | ✕ en retard, ⌕ absent | `setState` immédiat sur la visibilité de ✕ (hors debounce) ; ajouter le glyphe ⌕ à l'état initial | Champ réactif, état initial conforme | `lib/search_screen.dart` |
| P2-B | Favoris, Visite, Paramètres | Chargement incohérent | Supprimer `RefreshIndicator` et les `CircularProgressIndicator` sur lecture locale | Un seul comportement de chargement | `favorites_screen.dart`, `grave_visit_read_screen.dart`, `settings_screen.dart` |
| P2-C | Bottom sheets | Fond `surface` | `backgroundColor` → token `bg` | Conformité §3 | `lib/home_screen.dart` (2 feuilles) |
| P2-D | Personnes, Onboarding | Champ non stylé | `enabledBorder`/`focusedBorder` alignés sur le champ de recherche | Les deux champs de l'app se ressemblent | `person_selection_screen.dart`, `onboarding_screen.dart` |
| P2-E | Notifications | Contenu dupliqué, `open` empile | Une seule source de contenu ; supprimer `showPeriodReminder` si confirmé sans appelant ; `pushNamedAndRemoveUntil` | Moins de dérive possible, pile propre | `notification_service.dart`, `main.dart` |
| P2-F | AppBar | Couleur recalculée 5× | Déplacer la règle dans `AppTopBar` | Plus d'oubli possible | `widgets/app_bar.dart` + 5 écrans |
| P2-G | DS | `EdgeInsets.only(left:)` | `EdgeInsetsDirectional` | Règle RTL enfin sans exception | `app_snackbar.dart`, `onboarding_screen.dart` |
| P2-H | Icône | Fond adaptatif hors palette | `#006A4E` ; produire la variante Dark et le jeu de tailles | Cohérence de marque | `pubspec.yaml`, assets d'icône |
| P2-I | Navigation | Transitions hétérogènes | Un helper de route partagé, appliqué partout ou nulle part | Sensation de navigation homogène | `home_screen.dart`, `search_screen.dart`, `favorites_screen.dart` |
| P2-J | HOME | Code mort de notation | Décider : supprimer `_rateApp` + la dépendance, ou rebrancher | Conformité §6.12 tranchée | `home_screen.dart`, `pubspec.yaml` |

**Corrections documentaires** (aucun code) : aligner le §1 sur la suppression de `تدعو لـ` des Paramètres (une seule entrée, pas deux) ; corriger le gap de chips à 8 dans le §3 ; mettre à jour `DESIGN_SYSTEM_IDENTITE_LANCEMENT.md` §1, toujours consacré à l'ancienne icône géométrique.

---

## 7. Verdict LOT 66

# LOT 66 — READY FOR IMPLEMENTATION

**Justification.** L'audit ne révèle aucun problème structurel : l'architecture UX validée, le Design System et les décisions verrouillées sont réellement implémentés et cohérents entre les écrans. Les écarts constatés sont **tous localisés, tous traçables à une ligne de spécification existante, et tous corrigeables dans les composants déjà en place** — aucun ne demande de nouveau composant, aucun ne rouvre une décision verrouillée, aucun ne justifie une refonte. Trois d'entre eux méritent un traitement immédiat parce qu'ils font perdre une donnée utilisateur (P0-A), contredisent la règle d'animation que la spec désigne elle-même comme la plus importante du produit (P0-B), ou exposent une couleur hors palette dès le premier écran affiché (P0-C). Le seul écart vis-à-vis de la référence notifications nouvellement validée est parfaitement circonscrit (horaires soir et vendredi non configurables) et sa correction est mécanique, à condition de livrer la localisation arabe d'abord.

Le périmètre du §6 est prêt à être découpé en lots. **Recommandation de séquencement :** P0-A + P0-B + P1-H (un lot HOME) → P1-B + P1-A (un lot réglages de rappels) → P0-C + P2-H (un lot enveloppe native) → P1-C + P1-D (un lot personnes) → P1-E/F/G/I/J + P2 (un lot finitions).
