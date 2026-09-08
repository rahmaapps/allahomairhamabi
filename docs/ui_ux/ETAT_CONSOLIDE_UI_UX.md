# État consolidé du travail UI/UX — document de continuité

**Application :** اللَّهُمَّ ارْحَمْ أَبِي (Flutter, RTL, arabe)
**Dépôt :** rahmaapps/allahomairhamabi — branche `github-migration` (remote `github-app`)
**Date de consolidation initiale :** 2 septembre 2026
**Dernière synchronisation avec le code réel :** 8 septembre 2026
**Commit de référence pour l'état d'implémentation :** `3cee368` (`fix(grave-visit): remove fade from dua text`, LOT 3.J), publié sur `github-app/github-migration`. Commits précédents de référence : `7d6e015` (`fix(home): remove fade from dua text`, LOT 3.I.B), `1329865` (`feat(dua-read): implement consolidated reading experience`, LOT 3.I).
**Objet :** source de vérité UI/UX. Ce document combine désormais deux natures de contenu, distinguées par leurs marqueurs : la spécification de conception d'origine (ce qui a été décidé) et l'état réel d'implémentation vérifié dans le code et l'historique Git jusqu'au commit de référence (ce qui est réellement construit et publié). En cas de contradiction entre une ancienne partie de ce document et le code réellement publié, **le code fait foi** ; la partie contredite est corrigée ou explicitement marquée obsolète, jamais laissée telle quelle en silence.

**Convention de lecture :**
✅ = terminé / implémenté / publié (vérifié dans le code et Git) · 🔒 = décision verrouillée (à ne pas rouvrir, implémentée ou non) · ⏳ = ouvert / à traiter · ❌ = supprimé / abandonné · 💡 = proposition non validée (historique, non normative)

**Règle générale :** ce document ne doit jamais avancer une affirmation sur l'état du code qui n'a pas été vérifiée par lecture du code ou de l'historique Git. Une information non confirmable est signalée comme telle, jamais devinée.

---

## 0. Cartographie des documents sources

Tous dans `docs/ui_ux/`. En cas de contradiction, **le document de phase le plus récent prime** sur `UI_UX_ARCHITECTURE_REVIEW.md`.

| Document | Contenu | Statut réel |
|---|---|---|
| `UI_UX_ARCHITECTURE_REVIEW.md` | Analyse d'architecture, options de navigation, wireframes ASCII | 💡 **Document d'analyse.** Ses recommandations ont depuis été tranchées par les phases 3x. Ne pas l'utiliser comme spec. |
| `DESIGN_SYSTEM_PHASE1_AUDIT.md` | Audit du matériau visuel existant | 💡 Historique, non normatif |
| `DESIGN_SYSTEM_PHASE2_SPEC.md` | **Design System officiel** (tokens, typo, spacing, rayons, composants) | ✅ **Référence normative unique.** Son en-tête dit encore « à valider » mais toutes les phases 3x l'appliquent comme figé. |
| `DESIGN_SYSTEM_PHASE3_HOME.md` | HOME | ✅ **Validé** — écran de référence. 1 point provisoire (paysage) |
| `DESIGN_SYSTEM_PHASE3A_ONBOARDING.md` | Onboarding 2 écrans | ✅ Spécification close |
| `DESIGN_SYSTEM_PHASE3B_PERSONNES.md` | Sélection/gestion des personnes | ✅ Spécification close |
| `DESIGN_SYSTEM_PHASE3C_VISITE_CIMETIERE.md` | دعاء زيارة القبر | ✅ Close **sauf 1 arbitrage bloquant** (wake lock) |
| `DESIGN_SYSTEM_PHASE3D_RECHERCHE.md` | Recherche | ✅ Close — aucun arbitrage en attente |
| `DESIGN_SYSTEM_PHASE3E_FAVORIS.md` | Favoris | ✅ Close — aucun arbitrage en attente |
| `DESIGN_SYSTEM_PHASE3F_PARAMETRES.md` | Paramètres | ✅ Close — aucun arbitrage en attente |
| `DESIGN_SYSTEM_PHASE3G_PARTAGE_PREMIUM.md` | Partage Premium | ✅ Close — aucun arbitrage en attente |
| `DESIGN_SYSTEM_IDENTITE_LANCEMENT.md` | App Icon + splash natif | ✅ Close — mais le §1 décrit l'ancienne icône géométrique (voir §7) |
| `APP_ICON_BRIEF_GRAPHIQUE.md` | Brief pour illustrateur | ✅ Validé, figé |

⚠️ **Constat vérifié au 6 septembre 2026 :** seul `ETAT_CONSOLIDE_UI_UX.md` existe physiquement dans `docs/ui_ux/` du dépôt. Tous les autres documents listés ci-dessus (`DESIGN_SYSTEM_PHASE2_SPEC.md`, les `PHASE3x`, les `.dc.html`, etc.) sont des références historiques à des documents de conception externes au dépôt Flutter — ils ne sont pas retrouvables par lecture de fichier dans ce repository. Ce tableau reste une carte de provenance des décisions, pas un inventaire de fichiers présents.

---

## 1. Nouvelle architecture UX

### ✅ Navigation retenue — **Option 3 (hybride)**

Pas de barre de navigation persistante. Le HOME reste le hub ; les destinations sont atteintes par des icônes permanentes de son AppBar.

**AppBar du HOME, ordre définitif (flux RTL) :**

```
اللهم ارحم أبي        ⌕    ♡    ⤴    ⋮
                   بحث  مفضلة  partage  menu
```

| Fonction | Accès validé |
|---|---|
| **HOME** | Hub. Écran d'accueil, non scrollable. Seul écran à porter un bandeau. |
| **Recherche** | Icône `⌕` de l'AppBar |
| **Favoris** | Icône `♡` de l'AppBar |
| **Partage Premium** | Icône `⤴` de l'AppBar → bottom sheet (jamais un écran) |
| **Paramètres** | Menu `⋮` → `الإعدادات` |
| **Sélection des personnes** | Ligne « pour qui » du HOME (`تغيير` / `اختيار`) **et** Paramètres → `تدعو لـ`. Deux entrées, un seul écran, mode Édition. |
| **دعاء زيارة القبر** | **Bandeau dans le `bottom:` de l'AppBar du HOME**, h 44, hors du `body` → écran plein empilé |

**Menu `⋮` :** ~~`الإعدادات` · `مشاركة التطبيق` · `عن التطبيق`~~ ❌ **obsolète, contredit par le code publié (`e63f4c8`).**
✅ **État réel implémenté et verrouillé :** `⋮` ouvre `الإعدادات` **directement**, sans menu intermédiaire (`home_screen.dart`, commentaire du code : « ⋮ → الإعدادات directement… Aucun menu intermédiaire : pas de destination inventée ici »). `عن التطبيق` est une ligne à l'intérieur de Paramètres (voir §4 Paramètres, LOT 3.G), pas une entrée du menu `⋮`. `مشاركة التطبيق` (partage de l'app elle-même, différent du Partage Premium `⤴`) n'est **actuellement accessible depuis aucune UI** : la méthode `_shareAppOnWhatsApp()` existe encore dans `home_screen.dart` mais n'est appelée nulle part (confirmé par `flutter analyze` : `unused_element`) — code mort, ni supprimé ni rebranché. Point à trancher dans un futur lot (voir « Éléments ouverts »), pas un oubli de cet audit.

### ✅ Structure générale

```
[1er lancement] Onboarding étape 1 → étape 2 → pushNamedAndRemoveUntil('/home')
                                                (pile vidée, onboarding inatteignable)

HOME (hub, non scrollable)
 ├─ bottom: bandeau → دعاء زيارة القبر  (écran plein, aucune action)
 ├─ ⌕ → Recherche → lecture d'un douʿā
 ├─ ♡ → Favoris → lecture d'un douʿā
 ├─ ⤴ → bottom sheet Partage Premium → mécanisme natif
 ├─ ligne « pour qui » → Personnes (mode Édition)
 └─ ⋮ → الإعدادات → Personnes / heure / thème / عن التطبيق
```

### ✅ Traitement de « دعاء زيارة القبر »

- **Ce n'est pas une catégorie.** Retiré de la rangée de filtres — qui ne compte plus que deux entrées, `عام` et `دعاء الجمعة`, à 50 % de largeur chacune (règle le risque de troncature historique).
- Accès par un **bandeau nommé** dans le `bottom:` de l'AppBar (solution F2), fixe, jamais dans le `body` : la carte du douʿā ne perd aucun pixel.
- Libellé : nom complet + phrase de contexte `للقراءة عند الزيارة`. **Le losange ◈ est retiré** (décision appliquée dans toutes les maquettes).
- L'écran est un **écran plein de lecture seule** : aucune action (ni copie, ni partage, ni favori, ni « دعاء آخر »). L'absence d'actions est la spécification, pas un oubli.

---

## 2. Nouveau design du HOME — ✅ validé, écran de référence

### Structure verticale — 6 strates, dont 4 seulement dans le `body`

```
AppBar 56 dp        اللهم ارحم أبي   ⌕ ♡ ⤴ ⋮        hors body
bottom: 44 dp       دعاء زيارة القبر · للقراءة عند الزيارة  ‹   hors body
────────────────────── padding 16 ──────────────────────
Chips catégories    44 dp                              N2
────────────────────── gap 12 ─────────────────────────
Ligne « pour qui »  20 dp   تدعو لـ أبي · تغيير        N4
────────────────────── gap 12 ─────────────────────────
⭐ CARTE DU DOUʿĀ    Expanded — seul élément élastique   N1
   (♡ + « دعاء آخر » DANS son pied)
────────────────────── gap 12 ─────────────────────────
نسخ · مشاركة        48 dp, paire à largeurs égales      N3
────────────────────── 16 au-dessus du bord sûr ───────
```

### ✅ Les trois décisions de composition

1. Le bandeau visite est **hors du `body`** (`bottom:` de l'AppBar).
2. La sélection des personnes est une **ligne de 20 dp, pas un bouton** → rend 48 dp à la carte.
3. **« دعاء آخر » vit dans le pied de la carte**, pas sous elle.

### ✅ Hiérarchie visuelle — les 6 privilèges exclusifs de la carte

Rayon 24 · élévation `e2` · filet d'or 2 px en tête · rosace 16 pointes à 5,5 % · police Lateef · seul `Expanded`.
**Aucun autre élément du HOME n'en porte plus d'un.** Test de validation : en floutant l'écran on doit voir une grande forme blanche, une pastille verte au-dessus, une pastille verte dedans, une bande verte en haut. Rien d'autre.

| Niveau | Éléments |
|---|---|
| N1 | Le douʿā |
| N2 | Chips catégories · `دعاء آخر` |
| N3 | ♡ · نسخ · مشاركة |
| N4 | AppBar · bandeau · `تغيير` · icône de partage |

### ✅ Éléments supprimés / déplacés / ajoutés

| Action | Élément |
|---|---|
| **Supprimé** | 3ᵉ chip `دعاء زيارة القبر` · doublon Favoris (icône + menu) · doublon export image (icône + bouton bas) · bouton pleine largeur de sélection des personnes · `TextDirection.ltr` forcé · promo WhatsApp du HOME |
| **Déplacé** | زيارة القبر → bandeau `bottom:` · Recherche → icône d'AppBar · rappels → Paramètres · promo WhatsApp → hors HOME |
| **Ajouté** | bandeau `bottom:` · ligne « pour qui » · icône `⤴` de partage |

### ✅ Comportement des catégories et des actions

- **2 chips** (`عام`, `دعاء الجمعة`), deux intensités : active = aplat `primary` + 600 ; inactive = `surface` + trait + 500. h 44, zone 48.
- **Changement de catégorie (B2)** : cross-fade + glissement horizontal 16 dp dans le sens RTL, 240 ms. Seul le contenu de la carte change.
- **« دعاء آخر » (C1)** : cross-fade vertical 10 dp, **entrée par le bas**, 280 ms. **La carte ne bouge pas d'un pixel** — c'est l'animation la plus importante du produit.
- **Douʿā long** : défile **à l'intérieur** de la carte. ✅ **Aucun dégradé de bord** (LOT 3.I.B, `7d6e015` — le `ShaderMask` de fondu 44 px a été supprimé : coupure nette et naturelle aux limites du scroll, texte pleinement opaque en permanence). Le HOME ne défile jamais (seul le texte de la carte défile).
- **نسخ / مشاركة** : paire horizontale par défaut ; **bascule verticale** si largeur/action < 132 dp, ou `textScaler` ≥ 1,3, ou libellé tronqué.
- **Favori** : ♡ → ♥ rempli, `scale 1 → 1.12 → 1`, 200 ms. Le retrait ne fait aucun scale (asymétrie volontaire).
- **A4 — le texte du douʿā est peint à l'opacité 1 dès la frame 0.** Ce qui s'anime est son support, jamais son contenu.
- **Courbe unique du produit :** `easeOutCubic` en entrée, `easeInOutCubic` en transition. Aucune animation > 320 ms. Aucun rebond.
- **Grammaire du mouvement :** horizontal = changement de contexte de même niveau · vertical = renouvellement de contenu dans un cadre fixe.
- **Rosace : jamais animée.** Aucune exception.

---

## 3. Design System — ✅ référence normative (Phase 2)

### ✅ Palette Light Mode

| Token | Valeur | Usage |
|---|---|---|
| `bg` | `#FFFBF1` | Fond de tous les Scaffold |
| `surface` | `#FFFFFF` | Cartes de contenu, carte du douʿā |
| `surfaceAlt` | `#FFF6E7` | Groupes de réglages, boutons tonaux |
| `surfaceMuted` | `#F4F7F4` | Cartes discrètes |
| `primary` | `#006A4E` | AppBar, CTA, chip active — 8,4:1 |
| `primaryPressed` | `#00563F` | Pressé, bandeau visite |
| `primaryContainer` | `#E4F0EA` | Sélection légère |
| `onPrimary` | `#FFFBF1` | Texte sur vert — **ivoire, jamais blanc pur** |
| `secondary` | `#009F6B` | Accents ponctuels |
| `goldText` | `#8A6508` | Titres or, `تغيير` — 5,1:1 |
| `goldLine` | `#D4AF37` | Filets 1–2 px |
| `textPrimary` | `#1E2A24` | 13,9:1 |
| `textSecondary` | `#5C6B63` | 5,8:1 |
| `textDisabled` | `#A79F8E` | Texte d'aide non essentiel |
| `border` | `#EADFC8` | Contours |
| `borderStrong` | `#C9C2B2` | Cases vides, champs |
| `disabledBg` | `#EFEADF` | Fond désactivé |
| `success` | `#2E7D5B` | · `error` `#A63A2E` (terre cuite) |
| `scrim` | `rgba(30,42,36,.45)` | Voiles |

✅ **`#FFD700` retiré** de tout rôle de texte et de bordure. ✅ **`#25C4A5` sort du Light Mode.**

### ✅ Palette Dark Mode — 16 tokens définis à la main, aucune inversion algorithmique

| Token | Valeur |
|---|---|
| `bg` | `#101A16` — vert-charbon, **jamais `#000000`** |
| `surface` | `#18241F` — plus clair que le fond : l'élévation se lit sans ombre |
| `surfaceAlt` | `#20302A` |
| `appBar` | `#0C1512` — plus sombre que le fond : l'en-tête s'enfonce |
| `bandVisite` | `#132019` |
| `primary` / CTA | `#009F6B` · `onPrimary` `#062018` (texte sombre sur vert clair) |
| `accent` | `#25C4A5` |
| `gold` | `#E3C570` — 8,1:1 |
| `textPrimary` | `#F3EEE1` — ivoire, **jamais `#FFFFFF`** |
| `textSecondary` | `#A6B2AA` · `textDisabled` `#6B7872` |
| `border` | `#2C3C35` |
| `success` | `#4EBF92` · `error` `#E08472` |
| `scrim` | `rgba(6,14,11,.62)` |

**Règles de transposition :** les ombres disparaissent, l'élévation devient une marche de surface (`bg` → `surface` → `surfaceAlt`) · rosace en `accent` à 7 % · l'or monte en luminosité, jamais en saturation.

### ✅ Typographie arabe — 2 polices, jamais 3

- **`Lateef`** — **uniquement** le texte du douʿā, le titre de l'app, la phrase d'accroche des états vides, et les heures. Rien d'autre.
- **`IBM Plex Sans Arabic`** — 100 % du reste de l'interface. (Almarai retenu comme repli non activé.)

✅ **Implémentation vérifiée (`dea47c1`)** : `lib/theme/app_typography.dart` (`plexFamily = 'IBMPlexSansArabic'`) l'utilise pour tous les rôles non-Lateef, et `lib/theme/app_theme.dart` l'applique comme police de base de tout le `TextTheme` (Light et Dark). Les 3 fichiers `.ttf` (Regular 400, Medium 500, SemiBold 600) sont **désormais réellement embarqués localement et déclarés dans `pubspec.yaml`** — jusqu'au commit `dea47c1`, le code utilisait déjà cette police par nom sans qu'elle soit enregistrée dans `pubspec.yaml`, ce qui provoquait un repli silencieux (sans erreur ni avertissement d'outillage) vers la police système sur toutes les surfaces déjà publiées (HOME, Recherche, Favoris, Onboarding, Personnes, Paramètres). C'est corrigé.

| Rôle | Police | Taille | Graisse | Interligne |
|---|---|---|---|---|
| `display` | Lateef | 34 | 400 | 1.35 |
| `screenTitle` | Plex | 20 | 600 | 1.50 |
| `sectionTitle` | Plex | 16 | 600 | 1.50 |
| **`duaBody`** | **Lateef** | **29** | **400** | **2.05** |
| **`duaLong`** | **Lateef** | **31** | **400** | **2.15** |
| `duaCompact` | Lateef | 22 | 400 | 1.85 |
| `body` | Plex | 15 | 400 | 1.75 |
| `bodyStrong` | Plex | 15 | 600 | 1.50 |
| `button` | Plex | 16 | 600 | 1.20 |
| `chip` | Plex | 14 | 500 | 1.20 |
| `label` | Plex | 12 | 500 | 1.40 |

**Règles :** interligne du douʿā **≥ 2.0 non négociable** · `letter-spacing: 0` toujours en arabe · aucun italique, aucun all-caps · `textScaler` suivi jusqu'à **1,6×**, aucune hauteur figée.

🔒 **Règle des chiffres — décision verrouillée (remplace la mention « chiffres arabes-indiens dans… les heures » ci-dessus, devenue ❌ obsolète) :** les chiffres **occidentaux 0-9** sont utilisés dans toute l'interface fonctionnelle (heures — `09:00`, `20:00` — valeurs de paramètres, compteurs, nombres fonctionnels, dates). **Exception :** le contenu religieux original est conservé fidèlement tel qu'il existe dans sa source ; cette règle typographique ne s'applique jamais en modifiant artificiellement un texte religieux.
✅ **Déjà conforme dans le code publié** : recherche exhaustive dans `lib/` — aucun chiffre arabe-indien (٠-٩) trouvé nulle part. Les heures de Paramètres/Onboarding (`_pickMorningTime`, etc.) et le compteur de Recherche (`ابحث في ${_all.length} دعاء`) utilisent tous l'interpolation Dart standard, donc des chiffres occidentaux. Le code d'Onboarding documente lui-même explicitement ce choix (« Heure en chiffres occidentaux (décision UX) — remplace les chiffres arabes-indiens initialement prévus par §3 pour ce cas précis »), aujourd'hui confirmé comme la règle générale, pas une exception locale.

### ✅ Espacements — base 4

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40` — **aucune autre valeur** (pas de 6, 10, 14, 18).

Marge horizontale d'écran **20**, unique et sans exception · padding de carte **20**, carte du douʿā **24** · entre composants d'un bloc **12** · entre blocs **20** · sous l'AppBar **16** · au-dessus du bord bas sûr **16** · padding vertical de bouton **14** (→ h 48) · gap de chips **10** · **zone tactile minimale 48 × 48 partout**.

### ✅ Rayons

`r-field` 8 (cases 6) · `r-button` 12 · `r-card` 16 · **`r-hero` 24** (carte du douʿā, haut des bottom sheets) · `r-pill` 999.

### ✅ Hiérarchie des cartes — 4 niveaux

- **N1 — carte du douʿā** : `surface` · `r-hero` · `e2` · padding 24 · filet d'or · rosace. **Seule surface à porter les trois signes.**
- **N2 — carte de contenu** : `surface` · `r-card` · `e1` · trait. (Favoris, résultats — en pratique spécifiées à `e0`.)
- **N3 — groupe de réglages** : `surfaceAlt` · `r-card` · `e0` · séparateurs 1 px indentés de 16.
- **N4 — carte discrète** : `surfaceMuted` · `r-card` · trait tireté · aucune ombre.

### ✅ Ombres — teintées vert, jamais grises : `rgba(0,58,42,α)`

`e0` trait 1 px · `e1` `0 1px 3px /.07` · `e2` `0 6px 20px /.10` · `e3` `0 12px 34px /.16`.
**`e2` est le privilège exclusif du contenu sacré** (carte du HOME, carte de lecture 3C, carte de lecture `DuaReadScreen` — LOT 3.I, `AppCard(level: hero)` —, sheet de partage).

### ✅ Boutons

Hauteur 48 · rayon 12 · Plex 16/600 · pressé = couleur pressée **+ `scale .98`**, aucune ondulation Material.

| Rôle | Repos | Pressé | Désactivé |
|---|---|---|---|
| Primary | `primary` / `onPrimary` | `primaryPressed` | `disabledBg` / `textDisabled` |
| Secondary | `surface`, trait 1,5 `primary` | `primaryContainer` | trait `border` |
| Text | transparent, texte `primary` | `primaryContainer` | `textDisabled` |
| Action (tonal) | `surfaceAlt` / `textPrimary` | `#F5E8CE` | `disabledBg` |
| Destructif | transparent, texte `error` | `#F7E9E6` | `textDisabled` |

**Jamais `opacity: .38`** pour désactiver · un seul Primary visible par écran · les boutons d'action vont par paire à largeurs égales.

### ✅ Chips — un composant, deux intensités

| Variante | Non sélectionnée | Sélectionnée | Métrique |
|---|---|---|---|
| **Catégorie** | `surface` + trait `border` + `textSecondary` 500 | **aplat `primary`** + `onPrimary` 600 | h 44, zone 48 |
| **Personne** | transparent + trait `border` | `primaryContainer` + trait `#C3DED2` + `primary` 600 | h 40, zone 48 |

**Interdits :** croix de suppression, icône dans la chip, compteur, bordure épaissie. Les chips ne doivent jamais évoquer un panneau de filtres.

### ✅ AppBars — 3 zones

| Zone | Contenu |
|---|---|
| **A — Identité** | HOME : `اللهم ارحم أبي` Lateef 25 `onPrimary`. Écrans secondaires : `→` + titre Plex 16/600, h 52. |
| **B — Actions** | `⌕` · `♡` · `⤴` · `⋮`. Icônes 24 px, zone 48. |
| **C — `bottom:`** | Bandeau visite — **HOME uniquement**, h 44. |

Style : fond `primary` (Light) / `appBar` (Dark) · **aucune ombre, aucun filet d'or** · `SystemUiOverlayStyle.light`.
Les écrans secondaires (Favoris, Recherche, Paramètres, Visite, `DuaReadScreen` — LOT 3.I) n'ont **aucune icône d'action** dans leur AppBar.

### ✅ Composants communs — état réel d'implémentation (vérifié dans `lib/widgets/`)

| Composant | Fichier | État |
|---|---|---|
| `AppTopBar` | `widgets/app_bar.dart` | ✅ Implémenté — zones A/B/C, utilisé par HOME, Recherche, Favoris, Personnes, Paramètres, Lecture, Visite |
| `AppVisitBandeau` | `widgets/app_bar.dart` | ✅ Implémenté — bandeau `bottom:` du HOME |
| `AppCard` | `widgets/app_card.dart` | ✅ Implémenté — niveaux réellement existants : `hero` (N1), `content` (N2), `settingsGroup` (N3, ajouté avec Paramètres/LOT 3.G). **N4 (carte discrète) n'existe pas encore** — aucun écran ne l'a encore consommé |
| `AppDuaResultCard` | `widgets/app_dua_result_card.dart` | ✅ Implémenté — carte de résultat, partagée par Recherche et Favoris (`showFavoriteHeart` optionnel) |
| `AppEmptyState` | `widgets/app_empty_state.dart` | ✅ Implémenté — gabarit à 4 couches, `watermarkIcon` optionnel (utilisé par Favoris) |
| `AppButton` | `widgets/app_button.dart` | ✅ Implémenté — rôles `primary`/`secondary`/`action` seulement. `text` et `destructive` **non implémentés**, aucun écran ne leur a encore assigné d'usage |
| `AppChip` | `widgets/app_chip.dart` | ✅ Implémenté — variantes `category` (HOME) et `person` (Personnes) seulement, aucune troisième variante |
| `showAppUndoSnackBar` | `widgets/app_snackbar.dart` | ✅ Implémenté — utilisé par Personnes et Favoris |
| `showAppToast` | `widgets/app_snackbar.dart` | ✅ Implémenté (LOT 3.I, `1329865`) — fond `textPrimary`/texte `onPrimary`, 2,5 s, une ligne, aucun bouton ; utilisé par `DuaReadScreen` pour le retour de copie |
| `AppTheme` (Light/Dark) | `theme/app_theme.dart` | ✅ Implémenté, unique, branché sur `MaterialApp` dans `main.dart` |

### ✅ Composants communs (spécification d'origine)

- **États vides — gabarit unique à 4 couches** : rosace filigrane 88–96 px à 15 % · une phrase en Lateef 24–25 · une phrase d'aide en Plex 12,5 · zéro ou un bouton Primary. Centrage vertical décalé de **−24**. Jamais d'écran vide, jamais d'illustration.
- **Dialogue** : `surface` · r 24 · padding 24 · max 320 · `e3` · **actions empilées verticalement** (les libellés arabes débordent à fort `textScaler`). Pour une décision, jamais pour une information.
- **Bottom sheet** : `bg` · r 24 en haut · poignée 36 × 4 · max 85 % de hauteur · fermeture par glissement toujours active.
- **Toast** : fond `textPrimary`, texte `onPrimary` 13,5, r 12, 2,5 s, **une seule ligne**, aucun bouton. ✅ **Implémenté** (`showAppToast`, LOT 3.I, `1329865`) — voir tableau ci-dessus.
- **Snackbar avec annulation** : `surfaceAlt` inversé, r 12, **6 s**, action `تراجع`, ancré à 16 dp du bas. Une seule annulation à la fois, jamais empilée.
- **Interdits absolus :** aucun dialogue au premier lancement, aucun dialogue de notation, aucun dialogue promotionnel Premium.

### ✅ Règles RTL

- **Aucun `EdgeInsets.only(left:/right:)`** — uniquement `start`/`end`. Aucun `Row` dépendant du LTR. Aucun `TextDirection.ltr` forcé.
- Chevron de navigation `‹` (progression en RTL) · flèche retour `→`.
- Les icônes non directionnelles (♡, ⌕, ⤴) ne sont **jamais** retournées.
- Nombres et heures restent en lecture LTR dans le flux RTL.
- Vigilance sur toute `PageRouteBuilder` custom : piège du sens de glissement figé en LTR.

### ✅ Responsive et accessibilité

- Cible basse **320 × 568 dp**, tout doit y tenir sans troncature.
- **Le texte sacré n'est jamais réduit** pour gagner de la place : on accepte plus de défilement.
- Paysage : HOME et onboarding passent les contrôles en colonne latérale (HOME ⏳ provisoire) · Recherche/Favoris en grille 2 colonnes · Visite pleine largeur.
- Tablette : largeur de contenu plafonnée — **480 dp** au HOME, **420 dp** onboarding et sheet de partage, **340 dp** listes et lecture. On n'étire jamais la ligne arabe.
- Contraste **4,5:1** texte / **3:1** élément actif — tous les tokens vérifiés.
- **La couleur ne porte jamais seule l'information** : toujours un second signal (glyphe, graisse, position, forme).
- `MediaQuery.disableAnimations` respecté partout ; aucun objectif UX ne dépend d'une animation.

---

## 4. Autres écrans — dernière direction par écran

### ✅ Onboarding — Structure 2 (2 écrans), spécification close

`لمن تدعو؟` (intention + personnes fusionnés) → `تذكير يومي؟` (1 rappel) → HOME.

🔒 **Décision verrouillée (ordre définitif) :** `لمن تدعو؟` → `تذكير يومي؟`. Toute référence proposant l'ordre inverse est obsolète.

⚠️ **Écart vérifié avec le code publié (`222ea12`) — non corrigé par ce lot documentaire (documentaire uniquement, aucun code modifié) :** `lib/screens/onboarding_screen.dart` implémente actuellement l'ordre **inverse** — `تذكير يومي؟` puis `لمن تدعو؟` — par une décision produit explicite antérieure (LOT 3.E.1), documentée dans le code lui-même : *« Ordre retenu pour ce lot (LOT 3.E.1, décision produit explicite) : تذكير يومي؟ puis لمن تدعو؟ — inverse de l'exemple du document… Conséquence assumée : le sous-titre dynamique de l'étape rappel "reprenant la première personne cochée" […] ne s'applique plus ici. »* Confirmé par `test/onboarding_screen_test.dart` (l'étape 1 affiche `تذكير يومي؟`). **La décision ci-dessus rouvre donc explicitement ce point** : un lot de code dédié doit inverser l'ordre des deux écrans et réévaluer la conséquence documentée (sous-titre de l'étape rappel). ⏳ Tant que ce lot de code n'est pas fait, l'ordre réellement publié reste l'ancien (`تذكير يومي؟` → `لمن تدعو؟`).

- Squelette commun à 5 strates ; **la liste est le seul élément flexible**, le bloc d'actions est **ancré en bas**.
- Titres en **Plex 22/600, pas en Lateef** (corrige la maquette historique `2i`). Seule exception : l'heure `٠٧:٣٠` en **Lateef 26**.
- **Rien n'est bloquant** : `التالي` n'est jamais désactivé, `تخطّي` est **toujours visible**, la sélection est **toujours enregistrée avant toute sortie**.
- Prénom **jamais obligatoire** ; conservé même après décochage.
- L'onboarding n'utilise **que `e0`** et **aucun or** : il n'emprunte rien aux privilèges du sacré.
- Étape 2 : sous-titre dynamique reprenant la première personne cochée ; rappel activé par défaut ; si désactivé, la ligne `الوقت` **se retire** (jamais de champ grisé). Permission refusée → une seule ligne d'information, aucun dialogue, aucune relance.
- Transition 1↔2 : glissement horizontal RTL 280 ms ; **l'indicateur de progression ne glisse pas**, il se remplit. Retour arrière : sélection intacte.
- Sortie : `settings_completed = true` + `pushNamedAndRemoveUntil('/home')`, fondu 300 ms **sans glissement**. Aucun élément d'onboarding ne subsiste au HOME.
- HOME avec zéro personne : **même ligne, même place, même géométrie** — `ادعُ لمن تحب · اختيار`. Reste N4, jamais promue.

### ✅ Person Selection — un écran, deux modes, spécification close

Mode **Édition** = AppBar h 56, titre **`تدعو لـ`**, retour `→`, **aucun CTA en bas** (le bas vide signale que l'écran n'attend rien).

- **Enregistrement immédiat** de chaque coche/décoche/frappe. Le prénom est écrit **même vide** — correction du bug `data[person.name] = name` conditionnel. Debounce 400 ms + écriture au `focus lost` et à la sortie.
- Aucun toast à la sélection ; le contrat est porté une fois par le sous-titre `يُحفظ اختيارك تلقائيًا`.
- **Badge `الحالي`** : un seul à l'écran, informatif, non tapable. Résolution par **horodatage de sélection** (dernière cochée devient active ; si l'active est décochée → la plus récente parmi les restantes ; plus aucune → mode `عام` ; modifier un prénom n'a aucun effet).
- Décochage **silencieux, jamais bloquant**, y compris pour la dernière personne → snackbar 6 s avec `تراجع` (restaure la coche **et** l'active antérieure).
- Sortie sans dialogue. Retour au HOME → renouvellement de la carte selon **C1**. Depuis les Paramètres, le retour ramène aux Paramètres.
- **P0-1 résolu par construction** : plus aucun `Colors.white*`.

✅ **Implémentation vérifiée (`222ea12`)** : `lib/screens/person_selection_screen.dart` — recherche exhaustive de `Colors.white` : aucune occurrence. P0-1 est réellement corrigé, pas seulement couvert par la spec.

### ✅ Recherche — spécification close

- **Le champ remplace l'AppBar** — pas de titre `البحث` (économie de 52 dp).
- Champ : trait 1,5 px → `primary` au focus · `r-button 12` · `minHeight 44` · ✕ visible seulement si non vide, **vide le champ en conservant le focus**.
- Clavier ouvert à l'ouverture, **recherche à la frappe, debounce 250 ms**, aucun bouton « rechercher », **aucun indicateur de chargement** (recherche locale). Le clavier se ferme au premier défilement.
- Résultat : carte `e0`, extrait **Lateef 22/1.75, 2 lignes max** — arbitrage assumé (la typo dit « sacré », la taille dit « pas encore la lecture »). Terme surligné par un **fond `#FDF0C8`**, jamais par du gras ou une couleur de texte. Aucune icône, aucun chevron : la carte entière est la cible.
- État initial : glyphe ⌕ + une ligne `ابحث في ٢٢١٥ دعاءً`. **Aucun historique, aucune suggestion.**
- Aucun résultat : deux lignes, aucune illustration, le terme reste dans le champ.
- Retour depuis un résultat : recherche **intégralement restaurée** (terme, résultats, défilement), clavier **fermé**. Le terme n'est pas conservé entre sessions.
- **S2 = aucune animation** de mise à jour de liste (elle serait illisible pendant la frappe).

✅ **Implémentation vérifiée (`902c397`)** : `lib/search_screen.dart`, en-tête du fichier : « spécification close ». Debounce 250 ms, champ remplace l'AppBar, résultats en `AppDuaResultCard` (sans ♥), compteur `ابحث في N دعاء` en chiffres occidentaux — tout confirmé par lecture directe. La lecture d'un résultat ouvre `DuaReadScreen` (voir sa propre entrée ci-après) via une transition RTL dédiée (glissement 300 ms `easeInOutCubic`, réduite à un fondu 150 ms si `disableAnimations`).

### ✅ Favoris — spécification close

- **La carte de favori EST la carte de résultat de recherche, inchangée.** Seul ajout : un ♥ en tête de ligne. Deux listes de douʿās doivent se ressembler.
- AppBar h 52, `المفضلة`, **aucune icône d'action** — pas de tri, pas de filtre, pas de « tout supprimer ».
- Ordre : **plus récemment ajouté en premier**, non modifiable.
- ♥ toujours plein (tout est déjà favori) · appui = **retrait immédiat sans dialogue** → snackbar 6 s `تراجع` restaurant la carte **à sa position d'origine**. Le reste de la carte ouvre la lecture (`DuaReadScreen`, LOT 3.I) : deux cibles distinctes.
- État vide : glyphe ♡ + **une seule ligne** `اضغط ♡ على أي دعاء لحفظه هنا.` — explique le geste, ne vante pas la fonction. Aucun CTA, aucune illustration.

✅ **Implémentation vérifiée et publiée (`b0953b7`)** : `lib/favorites_screen.dart` migré intégralement — `AppTopBar` h52 sans icône d'action, `AppDuaResultCard` (identique à Recherche, `showFavoriteHeart: true`), tri par ajout le plus récent (`getFavoriteIds().reversed`), retrait immédiat + `showAppUndoSnackBar` restaurant la carte à sa position d'origine (`ScaffoldMessenger` local à l'écran pour que le snackbar ne survive pas à la sortie), `AppEmptyState` avec glyphe `Icons.favorite_border`. ❌ **Supprimé** de l'ancienne implémentation : actions individuelles copier/partager sur chaque carte, icône `تحديث` de l'AppBar, ancien état vide avec bouton « العودة », styles codés en dur (`Colors.black26`, `theme.cardColor`).
✅ **Navigation vers la lecture, ajoutée et publiée (LOT 3.I, `1329865`)** : le tap sur le contenu de la carte ouvre désormais `DuaReadScreen` (même transition RTL que Recherche, dupliquée localement) ; le ♥ reste une cible strictement indépendante (`onFavoriteTap` séparé, inchangé). Historique : entre `b0953b7` et `1329865`, cette navigation était volontairement absente (« l'écran de lecture n'est pas spécifié ») — voir la section « DuaReadScreen » ci-dessous, désormais entièrement résolue.

---

### ✅ DuaReadScreen — LOT 3.I, spécification close **et implémentée**, publiée (`1329865`)

🟢 **IMPLÉMENTÉ ET VALIDÉ.** Référence de spécification : `docs/ui_ux/LOT_3I_DUAREADSCREEN_SPEC.md`. Cet écran, initialement construit au LOT 3.D.0/3.D.1 (`902c397`) pour Recherche seule, a été reconsolidé par le LOT 3.I pour se conformer à la spécification dédiée et ouvert également depuis Favoris.

🔒 **Concept verrouillé :** `DuaReadScreen` est **une carte de lecture agrandie**, pas un écran de texte nu — tout ce qui appartient à la carte (texte, ♥) reste dans la carte ; l'AppBar ne reçoit que le retour.

✅ **Implémentation vérifiée** (`lib/screens/dua_read_screen.dart`) :
- **AppBar minimaliste** : `AppTopBar` h 52, **sans titre** (le modèle `Dua` n'a pas de champ titre — rien à inventer), zone B vide, retour (`→`) uniquement.
- **Carte de lecture** : `AppCard(level: AppCardLevel.hero)` — carte N1 identique à celle du HOME, rosace incluse, aucune duplication locale, aucune variante créée.
- **♥ dans le pied de la carte**, jamais dans l'AppBar. `UserPrefs` reste l'unique source de vérité ; retirer le ♥ ne ferme jamais l'écran. Animation à l'ajout `scale 1 → 1.12 → 1` (200 ms), aucune animation au retrait (même asymétrie que le ♥ du HOME).
- **Texte religieux en `AppTypography.duaLong`** (Lateef 31/2.15) — remplace `duaBody`, qui reste réservé à la carte du HOME. RTL, centré, largeur plafonnée à 340 dp, opacité 1 en permanence.
- **Scroll interne à la carte, seul élément défilant** : centré si le texte tient, défile sinon. **Aucun fade, aucun blur, aucun gradient, aucun `ShaderMask`** sur ce texte — coupure nette et naturelle au bord de la carte (recherche exhaustive dans le fichier : zéro occurrence de ces effets). Cette règle est scopée à `DuaReadScreen` par la spécification du LOT 3.I ; elle ne rouvre ni ne modifie les dégradés déjà documentés ailleurs dans ce document (HOME §2, دعاء زيارة القبر §4 — voir remarque ci-dessous).
- **`نسخ`/`مشاركة`** conservés : partage **texte simple uniquement** via `Share.share` (mécanisme déjà existant, inchangé) ; copie avec retour via `showAppToast` (§3) — remplace l'ancien `SnackBar` Material brut. **Aucun partage image** dans cette interface (n'en a jamais eu ; le partage image reste propre au HOME, `⤴`, hors périmètre).
- **États** : douʿā introuvable → `AppEmptyState` (jamais un écran blanc) ; lecture locale → **aucun `CircularProgressIndicator`** (contenu résolu en quelques millisecondes, un seul `FutureBuilder` pour tout l'écran).
- ❌ **`DuaReadOrigin` supprimé** : confirmé réellement mort par recherche exhaustive avant suppression (paramètre jamais lu) — enum, champ et arguments d'appel retirés.

✅ **Navigation — Recherche** : tap sur le contenu de `AppDuaResultCard` → `DuaReadScreen`. Transition RTL existante **strictement conservée** (glissement 300 ms `easeInOutCubic`, 150 ms fondu si `disableAnimations`) — non modifiée par ce lot, seul l'argument `origin` retiré de l'appel.

✅ **Navigation — Favoris** : tap sur le contenu de la carte → `DuaReadScreen` (même transition, dupliquée localement) ; le ♥ reste une cible strictement indépendante. **Resynchronisation au retour** : si le favori est retiré depuis l'écran de lecture, la liste des favoris le reflète immédiatement au retour (`_refresh()` après le `push`).

🔒 **HOME — inchangé, non concerné par ce lot :** le douʿā du HOME reste directement lisible sur place ; aucune ouverture de `DuaReadScreen` n'y est obligatoire ni n'a été ajoutée.

✅ **Mise à jour (LOT 3.I.B, `7d6e015`)** : la règle « aucun fade sur le texte religieux » est désormais appliquée **au HOME également** — le `ShaderMask` de fondu 44 px (§2) a été supprimé, le texte du douʿā du HOME est pleinement opaque en permanence, coupure nette aux limites du scroll.

✅ **Mise à jour (LOT 3.J, `3cee368`)** : la même règle est désormais appliquée à **دعاء زيارة القبر** — le `ShaderMask`/`shaderCallback`/`LinearGradient`/`BlendMode.dstIn`/`_fadeHeight` (fondu de 34 px, §4) ont été supprimés, le texte religieux de `GraveVisitReadScreen` est pleinement opaque en permanence, coupure nette aux limites du scroll. Les trois écrans qui affichent un texte religieux long (HOME, `DuaReadScreen`, دعاء زيارة القبر) appliquent désormais uniformément la règle « aucun fade sur le texte religieux ».

Tests dédiés (`test/dua_read_screen_test.dart`, `test/dua_read_screen_not_found_test.dart`, `test/search_to_dua_read_navigation_test.dart`, `test/favorites_to_dua_read_navigation_test.dart`).

---

### ✅ Paramètres — LOT 3.G, spécification close **et implémentée**, publiée (`b44f700`)

⚠️ **Le tableau ci-dessous remplace l'ancienne table à 3 sections/7 lignes** (conservée en historique juste en dessous) : une décision explicite prise pendant le LOT 3.G a retiré l'entrée `تدعو لـ` de cet écran — un écart assumé par rapport à la version originale de cette spécification, verrouillé depuis et non renégociable ici.

**2 sections, 6 lignes. Rien d'ajouté pour remplir.**

| Section | Lignes |
|---|---|
| `التذكير` | `تذكير الصباح` (activation + heure configurable) · `الوقت` (visible seulement si الصباح actif) · `تذكير المساء` (activation seule, heure fixe **20:00**) · `تذكير الجمعة` (activation seule, heure fixe **09:00**) |
| `التطبيق` | `المظهر` (تلقائي/فاتح/داكن) · `عن التطبيق` |

✅ **Implémentation vérifiée** (`lib/settings_screen.dart`, `lib/user_prefs.dart`, `lib/notification_service.dart`, `lib/main.dart`) :
- `بعد الظهر` **supprimé complètement** : UI, persistance (`UserPrefs`), canal de notification, planification WorkManager. L'ancienne tâche WorkManager `period_afternoon` est annulée **au démarrage réel de l'app** (`main()`, indépendamment de l'ouverture de l'écran) — corrige un risque de notification fantôme pour les utilisateurs déjà migrés.
- `تذكير الصباح` / `الوقت` : reprend strictement le pattern déjà validé de l'Onboarding (Switch + ligne d'heure qui disparaît, jamais grisée).
- `تذكير المساء` : heure fixe `20:00` codée en dur, non exposée en UI, non persistée.
- `تذكير الجمعة` : heure fixe `09:00` codée en dur. La planification recalcule systématiquement **la prochaine occurrence calendaire réelle** du vendredi (jamais un delta fixe `+7 jours` depuis l'heure d'exécution) — élimine tout risque de dérive en cas de retard d'exécution WorkManager (Android Doze, etc.). `enableFriday` par défaut à `false` (nouveau rappel, jamais activé silencieusement pour un utilisateur existant).
- **Enregistrement immédiat**, aucun bouton `حفظ`, aucun message de confirmation, aucune navigation forcée vers HOME après modification.
- ❌ **`تدعو لـ` supprimé de cet écran** (section `الدعاء` retirée entièrement) — la sélection des personnes reste accessible uniquement depuis HOME (ligne « pour qui »).
- Titres de section **hors carte**. Groupe de réglages = niveau **N3** de `AppCard` (`AppCardLevel.settingsGroup`, ajouté par ce lot — `surfaceAlt`/`r-card`/`e0`), séparateurs 1 px pleine largeur, absents sur la dernière ligne.
- Tests dédiés (`test/settings_screen_lot3g_test.dart`) : logique de replanification du vendredi (occurrences calendaires, non-dérive après retard d'exécution simulé), persistance `enableFriday`. ⏳ **Non couvert par un test automatisé** : le rendu de l'écran lui-même (structure des lignes, affichage conditionnel de `الوقت`) — `SettingsScreen._bootstrap()` bloque sur `NotificationService.ensureInitialized()` avant `_loadPrefs()`, non mockable en `flutter_test` simple sans nouvelle infrastructure de test (limitation déjà documentée pour cet écran avant ce lot, dans `test/onboarding_screen_test.dart` et `test/phase7_onboarding_and_person_selection_test.dart`).
- Permission refusée : comportement hérité inchangé (interrupteurs manipulables, pas de dialogue) — non re-vérifié spécifiquement pour ce lot.

<details>
<summary>Ancienne table (3 sections / 7 lignes) — historique, remplacée ci-dessus</summary>

| Section | Lignes |
|---|---|
| ~~`الدعاء`~~ | ~~`تدعو لـ` → écran Personnes (mode Édition)~~ ❌ supprimé (LOT 3.G) |
| `التذكير` | `تذكير الصباح` · `الوقت` · `تذكير المساء` · `تذكير الجمعة` (structure conservée, heures fixes ajoutées — voir ci-dessus) |
| `التطبيق` | `المظهر` (تلقائي/فاتح/داكن) · `عن التطبيق` (inchangé) |

- **Explicitement absents :** Premium, promo WhatsApp, notation, langue, compte, statistiques. `settings_completed` n'apparaît pas — c'est un drapeau technique.
- **N1 et N2 sont vides** : aucun contenu spirituel, aucune action principale.
- L'interrupteur est actionnable **sur toute la largeur de sa ligne** — ⚠️ non strictement re-vérifié pour ce lot (le `Switch` répond au tap ; l'enrobage plein-largeur de la ligne n'a pas été testé).

</details>

### ✅ دعاء زيارة القبر — close sauf 1 arbitrage

- Écran plein, AppBar h 52, `→`, **aucune icône d'action**. Un seul objet : la carte de lecture.
- Carte `Expanded` · `surface` · `r-hero 24` · `e2` · filet or + ✦ **fixe en tête** (seul ornement, aucune rosace) · attribution `رواه مسلم` fixe en pied.
- Texte **Lateef 27/2.0** centré, **seul élément défilant**. ~~dégradé de fondu 34 px~~ ❌ **obsolète, contredit par le code publié (LOT 3.J, `3cee368`)** — voir la mise à jour ci-dessous : le texte est désormais pleinement opaque en permanence, coupure nette aux limites du scroll. **Jamais réduit à 320 dp.**
- **N2 délibérément vide** — le seul écran de l'application dans ce cas.
- Tablette : largeur de lecture plafonnée à **340 dp**. Paysage : pleine largeur, aucune colonne latérale.
- ⏳ **Wake lock : non appliqué** (proposition), voir §6.

✅ **Implémentation vérifiée et publiée (`e63f4c8`)** : `lib/screens/grave_visit_read_screen.dart` — écran dédié, atteint depuis le bandeau du HOME via une sélection de personne (bottom sheet, voir `home_screen.dart` — `_openGraveVisitPersonPicker`), lecture intégrale scrollable, aucune action (confirmé par `test/grave_visit_read_screen_direct_test.dart` : « aucune action interdite (copie/partage/favori/دعاء آخر), aucune attribution, retour présent »). Traité comme un flux **distinct**, jamais comme une catégorie de douʿās partageable — pas de chip, pas d'onglet, retiré de la rangée de filtres du HOME. ⏳ **Wake lock toujours non implémenté** (aucun package de ce type dans `pubspec.yaml`, aucune référence dans le code) — l'arbitrage reste ouvert, le comportement actuel de facto correspond à la proposition « ne pas l'activer », sans que ce soit une décision formellement tranchée.

✅ **Mise à jour (LOT 3.J, `3cee368`)** : le dégradé de fondu de 34 px (`ShaderMask`/`shaderCallback`/`LinearGradient`/`BlendMode.dstIn`/`_fadeHeight`) a été supprimé de `_FadingDuaText` dans `grave_visit_read_screen.dart`. Le texte religieux est désormais pleinement opaque en permanence, peint avec `cs.onSurface`, coupure nette et naturelle aux limites du scroll — même règle que HOME (LOT 3.I.B, `7d6e015`) et `DuaReadScreen` (LOT 3.I, `1329865`). Conservés à l'identique : `LayoutBuilder`, `SingleChildScrollView`, centrage vertical du texte court, largeur de lecture plafonnée à 340 dp, `TextAlign.center`, `TextDirection.rtl`, `AppTypography.duaBody` (fontSize 27, height 2.0), carte `_GraveVisitCard`, navigation existante. **Seul le wake lock reste un arbitrage ouvert** pour cet écran (voir ⏳ ci-dessus et §9).

### ✅ Partage Premium — spécification close

- **Un bottom sheet, pas un écran** : le partage reste subordonné à la lecture, le douʿā reste visible derrière le voile. Réutilise le conteneur de sheet de la Phase 3F et **O10** (280 ms).
- Accès : **une seule icône `⤴`** dans l'AppBar, à gauche de `⋮`. Reste **N4**. Si aucun douʿā n'est affiché, l'icône **n'est pas rendue** — jamais grisée.
- **Aucun écran de présentation Premium**, aucun badge « PREMIUM », aucun prix, aucune comparaison, aucun verrou décoratif. Les templates sont montrés, pas vendus.
- 3 vignettes 74 × 104 à **poids strictement égal**, reproduisant le template réel à l'échelle. Ordre RTL : **داكن فاخر** (défaut) → زمردي → أبيض أنيق. Pas de carrousel, trois de front même à 320 dp.
- **Aucun template n'est redessiné.** Dark Luxe est *sélectionné par défaut* : c'est un état, pas une recommandation.
- Sélection = **3 signaux simultanés** : anneau 2 px, pastille `✓`, libellé en 600. Un seul à la fois, aucune désélection possible. Persistée (`share_template`).
- **Feedback à deux états seulement.** Préparation : le bouton garde sa taille, son contenu devient `جارٍ التحضير…` (affiché **seulement au-delà de 400 ms**). Succès : la feuille système **est** la confirmation, aucun message. Échec : une ligne d'erreur au-dessus du bouton, aucun dialogue, aucun snackbar.
- **✅ Règle de comportement figée :** le partage utilise le **mécanisme natif de la plateforme**. Aucun nouvel écran, dialogue, composant intermédiaire ni animation spécifique. L'annulation ramène exactement à l'écran précédent, **sans perte d'état**.
- Dark Mode : **les vignettes ne changent pas** — un template clair reste clair.

---

## 5. Wireframes, maquettes et prototypes produits

Tous hors dépôt Flutter, dans ce projet de conception.

| Fichier | Rôle | Statut |
|---|---|---|
| `Wireframes UX - Architecture.dc.html` | 8 wireframes basse fidélité (repères `1a`–`1h`) : variantes de HOME, 3 architectures de nav, 5 placements de زيارة القبر, écran de lecture, 3 onboardings, 5 réponses multi-personnes | 💡 **Intermédiaire, historique.** A servi à trancher ; dépassé par les phases 3x. Gris + un bleu de balisage, aucune couleur finale. |
| `Design System - Direction visuelle.dc.html` | **Maquettes vivantes de référence.** Repères : `2a`–`2j` fondations · `3a`–`3c` arbitrages · `4a`–`4e` HOME · `5a`–`5d` onboarding · `6a`–`6b` personnes · `7a`–`7b` visite · `8a`–`8b` recherche · `9a`–`9b` favoris · `10a`–`10b` paramètres · `11a`–`11b` partage · `14a` splash | ✅ **Version de référence** pour l'implémentation visuelle |
| `App Icon - Variante A finale.dc.html` | Ancienne icône géométrique explorée en interne | ❌ **Abandonnée** — remplacée par l'icône figée (§7) |
| `App Icon - Variante A corrigée.dc.html` | Correction de la même exploration | ❌ **Abandonnée** |
| `uploads/OK.png` | **Master visuel de l'App Icon, figé** | ✅ Définitif |
| `assets/app-icon-hands-light.svg` | Reconstruction vectorielle native du master (1 `<path>`, Bézier, `viewBox 0 0 1024 1024`, `#006A4E`, fond transparent) | ✅ Livrable Light produit |

Aucun prototype interactif n'a été produit. Les trois animations signalées « à juger à l'œil » (C1, O2, O4) n'ont pas été prototypées en mouvement réel.

---

## 6. Décisions à préserver absolument

Ne pas rouvrir lors de l'implémentation :

1. **L'application reste « اللَّهُمَّ ارْحَمْ أَبِي ».** Elle permet néanmoins plusieurs proches décédés et 11 `PersonType` — décision produit non remise en cause.
2. **Aucune refonte générique.** Toutes les phases appliquent les tokens de la Phase 2 sans en inventer. Plusieurs phases sont explicitement « aucun composant nouveau ».
3. **Fonctionnalités Flutter existantes préservées.** L'architecture de données, les 48 tests et l'architecture de rendu Premium de la Phase 11 (`duaTextZone`, `duaTextColor`, `fitSinglePage()`, `ClipRect`) sont **conservés**.
4. **« دعاء زيارة القبر » n'est pas une catégorie ordinaire** : bandeau nommé + écran plein, jamais une chip, jamais un onglet.
5. **Son mode de lecture spécifique est préservé** : lecture intégrale, scroll vertical interne, **aucune action** (ni copie, ni partage, ni favori, ni « دعاء آخر »). Ne pas les réintroduire au motif que les autres écrans les ont.
6. **Les 3 templates Premium ne sont pas redessinés.** Dark Luxe en particulier. Seule leur intégration UX est spécifiée ; les vignettes sont des aperçus du rendu existant.
7. **Une seule image générée lors du partage**, via le mécanisme natif de la plateforme. Aucun écran, dialogue ou animation ajouté ; retour sans perte d'état.
8. **`e2` reste le privilège du contenu sacré.** Aucun autre écran ne l'emprunte.
9. **Lateef est réservé au sacré** (+ titre de l'app + heures). Aucune troisième police.
10. **Le texte du douʿā n'est jamais réduit** pour gagner de la place, et **jamais animé à l'apparition** (règle A4).
11. **Un point d'entrée par fonction.** Aucun doublon ne doit réapparaître.
12. **Aucun dialogue au premier lancement**, aucune notation, aucune promotion Premium interruptive.
13. **La rosace n'est jamais animée.**
14. **Splash : aucune animation, aucun délai artificiel, aucun texte, aucun indicateur.**

### Bugs identifiés — état réel vérifié dans le code publié (`dea47c1`)

| Bug | Correction spécifiée | État réel |
|---|---|---|
| **P0-1** — `person_selection_screen` illisible en mode clair (`Colors.white70/white/white24` sur `Scaffold` sans `backgroundColor`) | Phase 3B §7 — résolu par construction, plus aucun `Colors.white*` | ✅ **Corrigé, vérifié** — aucune occurrence de `Colors.white` dans `person_selection_screen.dart` |
| Perte silencieuse du prénom (`data[person.name] = name` conditionnel) | Phase 3B §2 — le prénom est écrit même vide | ✅ **Corrigé, vérifié** — `_persist()` écrit chaque prénom sans condition |
| Troncature de `دعاء زيارة القبر` dans un tiers de rangée | Résolu : le libellé sort de la rangée de chips | ✅ **Corrigé, vérifié** — bandeau `AppVisitBandeau` dans `bottom:`, seuls `عام`/`دعاء الجمعة` restent en chips (`home_screen.dart`) |
| Titre de section `الفترات (إشعارات)` commenté dans `settings_screen` | Phase 3F — les 3 sections sont titrées | ✅ **Corrigé, vérifié** — `settings_screen.dart` (LOT 3.G) titre `التذكير`/`التطبيق` (2 sections désormais, voir §4 Paramètres) |
| `TextDirection.ltr` forcé sur la barre d'actions du HOME | Supprimé, layout RTL assumé | ✅ **Corrigé, vérifié** — aucune occurrence de `TextDirection.ltr` dans `lib/` (seul un commentaire en atteste l'absence) |
| `assets/premium/previews/dark_luxe_thumb.png` = stub de 68 octets (1×1 px) | À régénérer **depuis le template déjà validé** — ce n'est pas un redesign | ⏳ **Non résolu, vérifié** — le fichier fait toujours exactement 68 octets au 6 septembre 2026 |
| `main.dart` : `ThemeData.light()`/`dark()` sans personnalisation → deux identités visuelles | Le `ThemeData` unique issu de la Phase 2 est le prérequis de tout le travail visuel | ✅ **Corrigé, vérifié** — `AppTheme.light`/`AppTheme.dark` (`theme/app_theme.dart`) unique, branché dans `main.dart` |

---

## 7. Éléments encore non finalisés

### ⏳ Arbitrages à trancher avant de coder l'écran concerné

| # | Point | Écran | Proposition en attente |
|---|---|---|---|
| 1 | **Maintien de l'écran allumé pendant la lecture** (wake lock) | Phase 3C | Proposition : **ne pas l'activer**. Signalé comme « réellement bloquant » — arbitrage d'usage, pas de design. |
| 2 | **Paysage du HOME — colonne latérale de 108 dp** | Phase 3_HOME point 9 | **Retenu à titre provisoire**, à confirmer par vérification visuelle sur téléphone réel. Critère : la largeur de lecture du texte arabe prime. |

### ⏳ Non bloquant — à juger à l'œil, pas à décider sur le papier

- **C1** (durée 280 ms, amplitude 10 dp) — l'animation la plus importante du produit, jamais vue en mouvement.
- **O2** (apparition du sous-champ prénom) et **O4** (transition onboarding 1→2).
- **E3** (déplacement du badge `الحالي`) et durée du snackbar (6 s).

### ⏳ Hors périmètre, non tranché

- **رمضان — 374 douʿās aujourd'hui inaccessibles.** La question « dans le périmètre ou plus tard ? » n'a jamais été tranchée. Une réponse « maintenant » relancerait un HOME à sections.
- **Écran `عن التطبيق`** — ⚠️ partiellement caduc : implémenté comme un simple lien externe (`launchUrl` vers la page GitHub Pages du projet, `settings_screen.dart`), pas comme un écran interne. Le contenu affiché derrière ce lien reste hors périmètre de ce dépôt.
- ~~**Écran de lecture d'un douʿā ouvert depuis la Recherche ou les Favoris** — cité comme destination, jamais spécifié comme écran.~~ ✅ **Entièrement résolu (LOT 3.I, `1329865`)** — voir la section « DuaReadScreen » (§4) : spécifié, implémenté et branché depuis Recherche **et** Favoris. `DuaReadOrigin` supprimé (devenu inutile).
- **Multi-personnes en mode visite** (variantes C/E de l'analyse d'architecture) — la Phase 3C spécifie un écran de lecture unique **sans** chips de personnes ni sélecteur. La question est de fait close par la spec, et confirmée par le code publié (`grave_visit_read_screen.dart`, `e63f4c8`) — mais n'a jamais été formellement arbitrée en tant que telle.
- **`مشاركة التطبيق`** (partage de l'app elle-même) — ⏳ **nouvellement identifié** : code mort dans `home_screen.dart` (`_shareAppOnWhatsApp`, jamais appelé), retiré du menu `⋮` (voir §1) sans qu'une décision explicite de suppression ou de re-rattachement ait été prise.
- **Ordre Onboarding** — 🔒 décision verrouillée (`لمن تدعو؟` → `تذكير يومي؟`, voir §4 Onboarding) **non encore répercutée dans le code**, qui implémente toujours l'ordre inverse (LOT 3.E.1). Lot de code à prévoir.

### 🟡 État de l'App Icon — à connaître

- **L'icône est figée** : master `uploads/OK.png`, reconstruite en `assets/app-icon-hands-light.svg` (Light `#006A4E`, fond transparent).
- **Déclinaison Dark non produite** (`#3E9E7E` sur `#16211C`), ni le jeu de tailles exporté.
- **Défaut connu et assumé :** pouces légèrement hauts, ce qui affecte la lecture **en dessous de 32 px**. Explicitement non prioritaire. Utilisable sans réserve à **48 px et au-dessus** — donc pour tous les usages prévus (App Icon, splash, HOME, en-têtes).
- **Le test 5 personnes à 32 px** prévu au brief n'a pas été réalisé.
- ⚠️ **`DESIGN_SYSTEM_IDENTITE_LANCEMENT.md` §1 est périmé** : il décrit encore l'ancienne icône géométrique (« Variante A finale », tracés `fill-rule: evenodd`). Le reste du document (splash) reste valide. À mettre à jour avec le signe figé.

### ✅ Splash natif — figé, à ne pas rouvrir

Pas d'écran de bienvenue (déjà écarté en Phase 3A), pas d'ouverture immersive. Uniquement le fond natif de démarrage (`launch_background` / `LaunchScreen`) :
fond **identique au HOME** (`#FFFBF1` Light / `#16211C` Dark) · icône centrée, **aucun texte** · **taille = 22 % de la plus petite dimension de l'écran, borné 72–160 dp** · centrage **optique** · aucune animation, aucun délai minimal, aucun indicateur de chargement. Maquette : repère `14a`.

---

## 8. Prêt pour l'implémentation

⚠️ **Cette section 8 est le plan de lot d'origine (2 septembre 2026), conservée telle quelle à titre historique.** Elle décrivait ce qui restait *à faire* à cette date. Au 6 septembre 2026, la quasi-totalité de cette liste est **réellement implémentée et publiée** — voir le détail par écran au §4 (marqueurs ✅ avec référence de commit) et la synthèse au §9 ci-dessous, qui fait foi pour l'état réel.

### A. ✅ Définitivement prêt à implémenter

1. **`ThemeData` unique Light + Dark** depuis la Phase 2 : les 20 tokens Light, les 16 tokens Dark, les 11 rôles typographiques, l'échelle de spacing base 4, les 5 rayons, les 4 niveaux d'ombre teintés vert. **C'est le prérequis technique de tout le reste.**
2. **Composants communs** : boutons (5 rôles), chips (2 intensités), cartes (4 niveaux), AppBar (3 zones), bottom sheet, dialogue, toast, snackbar avec `تراجع`, gabarit d'état vide.
3. **HOME** — spécifié au pixel, y compris budget vertical à 568 dp, 8 états, 16 animations. Seul le paysage est provisoire.
4. **Onboarding** — 2 écrans, spécification close, 12 animations.
5. **Person Selection (mode Édition)** — spécification close, y compris la règle déterministe de personne active par horodatage.
6. **Recherche** — spécification close.
7. **Favoris** — spécification close, aucun composant nouveau.
8. **Paramètres** — spécification close, aucun composant nouveau.
9. **Partage Premium** — spécification close, règle de comportement natif figée.
10. **دعاء زيارة القبر** — tout sauf le wake lock.
11. **Splash natif** Light + Dark.
12. **Corrections de bugs** listées au §6.

### B. ⏳ Nécessite une décision avant de toucher au code

| Décision | Bloque |
|---|---|
| Wake lock en mode visite (oui / non) | Une ligne de code de l'écran 3C — l'écran peut être construit sans, et la décision appliquée après |
| Paysage du HOME : colonne latérale confirmée ? | Uniquement le layout paysage du HOME |
| Déclinaison Dark de l'App Icon + export des tailles | La génération des assets d'icône, pas les écrans |
| رمضان dans le périmètre ? | Rien aujourd'hui — mais une réponse « oui » rouvrirait la structure du HOME |
| Contenu de `عن التطبيق` | Une ligne des Paramètres, non bloquante |

**Aucune de ces décisions ne bloque le premier lot.**

### C. Premier lot d'implémentation recommandé

**Lot 1 — Fondations + HOME**

1. **`ThemeData` unique** (Light + Dark) avec tous les tokens de la Phase 2, plus les polices `Lateef` et `IBM Plex Sans Arabic` déclarées dans `pubspec.yaml`. Les 5 écrans en héritent — cela supprime à lui seul les deux identités visuelles actuelles.
2. **Bibliothèque de composants communs** : boutons, chips, les 4 niveaux de carte, AppBar, snackbar `تراجع`, gabarit d'état vide.
3. **Correction P0-1** (`person_selection_screen`) et du bug de prénom conditionnel — prérequis explicite de l'onboarding.
4. **HOME complet** : AppBar 4 icônes + bandeau `bottom:`, 2 chips, ligne « pour qui » (ses deux états), carte du douʿā avec ses 6 privilèges et son pied, paire نسخ/مشاركة avec bascule verticale, animations A1–A5, B1–B2, **C1**, D1–D2, E1–E2, F1, H1.
5. Suppression des doublons et du `TextDirection.ltr` forcé.

**Pourquoi ce lot :** le HOME est l'écran de référence déclaré de la Phase 3 — tous les autres écrans citent ses décisions. Le construire d'abord valide le `ThemeData` et la bibliothèque de composants sur le cas le plus exigeant, et **C1** est la seule animation dont la spécification demande une validation à l'œil : autant la voir tôt.

**Lots suivants, dans cet ordre :** Onboarding + Person Selection (ils partagent un écran) → دعاء زيارة القبر → Recherche → Favoris → Paramètres → Partage Premium → Splash + assets d'icône.

---

## 9. État réel de publication et éléments ouverts (mise à jour du 7 septembre 2026 ; complétée le 8 septembre 2026 — LOT 3.J)

Synthèse vérifiée par lecture du code et de l'historique Git jusqu'au commit `3cee368` (branche `github-migration`, remote `github-app`). Fait foi sur toute section antérieure en cas de contradiction.

### A. Écrans / lots réellement terminés et publiés

| Écran / lot | Commit(s) | État |
|---|---|---|
| Fondations Design System (`AppTheme`, tokens, `AppTopBar`, `AppCard` N1/N2, `AppButton`, `AppChip`, `AppSnackbar`) | `902c397` | ✅ |
| HOME | `e63f4c8` | ✅ |
| دعاء زيارة القبر (`GraveVisitReadScreen`) | `e63f4c8` | ✅ (sauf wake lock, toujours ⏳) |
| Recherche | `902c397` | ✅ |
| Onboarding + Person Selection | `222ea12` | ✅ implémenté — ⚠️ ordre des 2 écrans à inverser (voir §4 Onboarding, décision verrouillée §B) |
| Favoris | `b0953b7` | ✅ |
| Paramètres (LOT 3.G) | `b44f700` | ✅ |
| Police IBM Plex Sans Arabic embarquée | `dea47c1` | ✅ |
| `DuaReadScreen` (LOT 3.I — carte hero, `duaLong`, ♥ en pied, `showAppToast`, branché depuis Recherche **et** Favoris avec resynchronisation, `DuaReadOrigin` supprimé) | `1329865` | ✅ |
| Suppression du fondu de bord du HOME (LOT 3.I.B — `ShaderMask`/`LinearGradient`/`BlendMode.dstIn` retirés de `_fadingDuaScroll`, texte pleinement opaque) | `7d6e015` | ✅ |
| Suppression du fondu de bord de دعاء زيارة القبر (LOT 3.J — `ShaderMask`/`shaderCallback`/`LinearGradient`/`BlendMode.dstIn`/`_fadeHeight` retirés de `_FadingDuaText`, texte pleinement opaque) | `3cee368` | ✅ |

### B. Décisions nouvellement verrouillées par ce lot documentaire

1. 🔒 **Ordre Onboarding définitif :** `لمن تدعو؟` → `تذكير يومي؟`. Toute référence à l'ordre inverse est obsolète. **Non encore répercuté dans le code** (voir §4 Onboarding).
2. 🔒 **Chiffres occidentaux 0-9** dans toute l'interface fonctionnelle (heures, valeurs de paramètres, compteurs, nombres, dates) — exception stricte pour le contenu religieux original, jamais modifié pour s'y conformer. **Déjà conforme dans le code publié.**

### C. Éléments confirmés ❌ supprimés (à ne pas réintroduire)

- **Rappel après-midi** (`بعد الظهر`) — UI, persistance, canal de notification, planification WorkManager. Legacy annulé au démarrage de l'app.
- **Bouton `حفظ`** de Paramètres (et son comportement de sauvegarde différée + navigation forcée vers HOME).
- **Entrée `تدعو لـ`** dans Paramètres (section `الدعاء` entièrement retirée de cet écran — reste accessible uniquement depuis HOME).
- **Menu `⋮` à 3 entrées** — remplacé par un accès direct à `الإعدادات` (aucun menu intermédiaire).
- **Actions individuelles copier/partager et icône `تحديث`** de l'ancienne AppBar Favoris, ancien état vide avec bouton « العودة ».
- **`TextDirection.ltr` forcé**, `Colors.white*` dans Person Selection, perte silencieuse du prénom, troncature de `دعاء زيارة القبر` en rangée de chips, deux `ThemeData` non unifiés — tous corrigés par construction (voir §6, tableau des bugs).

⚠️ Ne pas confondre avec les éléments ⏳ ci-dessous, qui ne sont **pas** supprimés mais simplement non encore traités ou non branchés.

### D. Éléments réellement ouverts / prochains lots

Aucun élément déjà verrouillé n'est rouvert ici — seuls des points effectivement non tranchés ou non implémentés sont listés, chacun vérifié dans le code au moment de cette mise à jour :

1. **Ordre Onboarding** — décision verrouillée (§B.1) non encore appliquée dans `lib/screens/onboarding_screen.dart`. Lot de code à prévoir, avec réévaluation de la conséquence documentée (sous-titre de l'étape rappel).
2. **`مشاركة التطبيق`** — code mort (`_shareAppOnWhatsApp` dans `home_screen.dart`), non accessible depuis aucune UI. À trancher : suppression définitive ou re-rattachement à un point d'entrée.
3. **Wake lock** en mode visite (دعاء زيارة القبر) — toujours non implémenté, arbitrage d'usage jamais formellement tranché.
4. **Paysage du HOME** (colonne latérale 108 dp) — toujours provisoire, non re-vérifié visuellement dans cet audit.
5. **`dark_luxe_thumb.png`** — toujours un stub de 68 octets, jamais régénéré depuis le template validé.
6. **رمضان** (374 douʿās) — toujours hors périmètre, jamais tranché.
7. **Déclinaison Dark de l'App Icon** — toujours non produite.
8. **Contenu de `عن التطبيق`** — implémenté comme lien externe uniquement ; le contenu de cette page reste hors du dépôt Flutter.

Aucun de ces 8 points ne bloque l'un des écrans déjà publiés — ce sont des compléments ou des corrections localisées, pas des refontes. Le branchement Favoris → `DuaReadScreen`, précédemment listé ici, est **résolu** (LOT 3.I, `1329865`) — voir §4 « DuaReadScreen ». Le fondu de bord de دعاء زيارة القبر, précédemment listé ici comme 9ᵉ point (« non uniformisé »), est **résolu** (LOT 3.J, `3cee368`) — voir §4 « دعاء زيارة القبر » et le tableau A ci-dessus. Les trois écrans à texte religieux long (HOME, `DuaReadScreen`, دعاء زيارة القبر) appliquent désormais uniformément la règle « aucun fade sur le texte religieux ».

---

*Document de continuité. Les sections 1 à 8 restent la spécification et le plan d'origine (2 septembre 2026, historique). La section 9 est la mise à jour vivante synchronisée avec le code et Git (7 septembre 2026) et prévaut en cas de contradiction. Toute affirmation d'état d'implémentation de ce document est traçable soit aux documents du §0, soit à une lecture directe du code/commit citée en référence.*
