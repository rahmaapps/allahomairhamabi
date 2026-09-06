# LOT 3.I — `DuaReadScreen` : spécification consolidée

**Application :** اللَّهُمَّ ارْحَمْ أَبِي (Flutter, RTL, arabe)
**Base :** `rahmaapps/allahomairhamabi@github-migration`, commit `0cc0b24` (LOT 3.H)
**Source de vérité amont :** `docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md`
**Date :** 7 septembre 2026
**Statut :** spécification close — 2 points ⏳ non bloquants, 0 point bloquant

**Convention :** 🔒 décision verrouillée · ✅ comportement attendu · ❌ exclusion · ⏳ point ouvert

Ce document remplace le classement « §7 hors périmètre, non tranché » de l'écran de lecture dans `ETAT_CONSOLIDE_UI_UX.md`. Aucune décision nouvelle n'y est introduite au-delà des arbitrages du 7 septembre 2026.

---

## 0. Concept

🔒 `DuaReadScreen` est **une carte de lecture agrandie**, pas un écran distinct ni une page de texte nu. L'utilisateur ouvre une version immersive de la carte de douʿā qu'il connaît déjà.

🔒 Conséquence structurante : tout ce qui appartient à la carte reste **dans** la carte — le texte, et le ♥. L'AppBar ne reçoit rien d'autre que le retour.

---

## A. Structure de l'écran

```
┌──────────────────────────────────────────┐
│ AppTopBar h 52 — fond primary/appBar     │  zone A : →   (aucun titre)
│  →                                       │  zone B : VIDE
├──────────────────────────────────────────┤
│              ↕ 16 (sous l'AppBar)        │
│  ┌────────────────────────────────────┐  │
│  │ ▔▔▔ filet d'or 2 px ▔▔▔▔▔▔▔▔▔▔▔▔▔ │  │
│  │                                    │  │  CARTE DE LECTURE — Expanded
│  │        texte du douʿā              │  │  surface · r-hero 24 · e2
│  │        Lateef 31 / 2.15            │  │  padding 24
│  │        centré · RTL                │  │  SEUL élément élastique
│  │        ← seul élément défilant →   │  │
│  │                                    │  │
│  │  ─────────────────────────────────  │  │
│  │                              ♥     │  │  pied de carte
│  └────────────────────────────────────┘  │
│              ↕ 12                        │
│  [   نسخ   ]  ↔ 12  [   مشاركة   ]      │  h 48, largeurs égales
│              ↕ 16 (au-dessus du bord sûr)│
└──────────────────────────────────────────┘
     marge horizontale d'écran : 20
```

### A.1 AppBar

🔒 `AppTopBar`, hauteur **52**, **sans titre**, **zone B vide**.
- `leading` : `→` (`Icons.arrow_forward`) → `Navigator.maybePop`.
- Aucune action, aucune icône. Rétablit la règle §3 « les écrans secondaires n'ont aucune icône d'action dans leur AppBar ».
- Foreground **ivoire fixe par mode** (`AppColorsDark.textPrimary` en sombre, `AppColorsLight.onPrimary` en clair) — jamais `cs.onPrimary`. Correction déjà appliquée au HOME/Favoris/Visite, à conserver telle quelle.
- Style (fond, absence d'ombre et de filet d'or) porté par `AppBarTheme` — ne pas le redéfinir localement.

### A.2 Titre du douʿā

🔒 **Aucun titre.** Point factuel : le modèle `Dua` n'a pas de champ titre (`id`, `category`, `length`, `text`, `personKey`). Il n'y a donc rien à afficher, et rien à inventer.
❌ Aucune catégorie affichée — arbitrage antérieur maintenu (~70 % des douʿās sont `عام`, l'information n'a aucune valeur ici).

### A.3 Carte de lecture

🔒 Carte **N1** du Design System : `surface` · `r-hero` **24** · `e2` · **padding 24** · **filet d'or 2 px en tête**.
✅ `Expanded` — c'est le seul élément élastique de l'écran. L'AppBar et la barre d'actions ne bougent jamais.
✅ Marges : 20 horizontal (marge d'écran), 16 sous l'AppBar, 12 avant la barre d'actions.

⏳ **Rosace** — `AppCard(level: hero)` peint la rosace 16 pointes à 5,5 % ; `GraveVisitReadScreen` l'avait exclue en dupliquant une carte locale. Deux options, aucune ne bloque :
- **(a) recommandée** — utiliser `AppCard(level: AppCardLevel.hero)` **tel quel, rosace incluse** : zéro divergence, zéro duplication, et c'est littéralement « la carte du douʿā agrandie ».
- **(b)** — carte sans rosace, comme la visite : nécessite une 3ᵉ duplication locale ou une variante de `AppCard`.
Le §3 réserve les trois signes (filet, rosace, `e2`) à « la carte du douʿā » — cet écran **est** une carte du douʿā, l'option (a) ne viole donc aucune règle. Décision d'œil, à prendre sur appareil.

### A.4 Texte religieux

🔒 `AppTypography.duaLong` — **Lateef 31 / interligne 2.15**, poids 400, `letterSpacing: 0`.
Rôle déjà défini au §3 pour la lecture longue, aujourd'hui utilisé nulle part. Remplace `duaBody` (29/2.05), qui reste le rôle de la carte du HOME.

✅ `textAlign: center`, `textDirection: rtl`. Aucune justification (elle crée des rivières dans le texte arabe).
✅ Largeur de lecture plafonnée **340 dp** (§3, tablette) — ⏳ à vérifier à l'œil sur téléphone large, seul le rendu réel peut trancher.
✅ Couleur `cs.onSurface`. Opacité **1** en permanence.
✅ `textScaler` suivi jusqu'à **1,6×**, aucune hauteur figée.
✅ Centré verticalement si le texte tient dans la carte ; défile sinon.
🔒 Le texte n'est **jamais réduit** pour gagner de la place (§6.10). On accepte plus de défilement.

### A.5 ♥ Favori

🔒 **Dans le pied de la carte de lecture.** Jamais dans l'AppBar.
✅ Niveau **N3** de la hiérarchie visuelle (comme le ♥ du HOME) — il ne concurrence pas le texte.
✅ Zone tactile **48 × 48**, glyphe 24, aligné en fin de ligne (côté gauche en flux RTL), séparé du texte par un espacement de 12 ou 16.
✅ États : `Icons.favorite_border` (`textSecondary`) → `Icons.favorite` (`cs.error`).
✅ Animation **ajout** : `scale 1 → 1.12 → 1`, **200 ms**. Animation **retrait** : aucune (asymétrie volontaire déjà spécifiée au §2).
✅ `MediaQuery.disableAnimations` respecté — l'état est lisible sans l'animation.
❌ Aucun snackbar, aucun toast, aucun dialogue sur ce geste : le remplissage du ♥ EST la confirmation.

### A.6 Zone scrollable

🔒 Le scroll vit **à l'intérieur de la carte**, sur le texte seul. La page ne défile jamais.
🔒 **Coupure nette et naturelle** du contenu au bord de la carte.
❌ Aucun fade, aucun blur, aucun gradient, aucune opacité partielle, aucun `ShaderMask`, aucune ombre interne, aucun chevron, aucune barre de défilement Material, aucun indicateur graphique d'aucune sorte.
✅ Rebond de défilement natif conservé (`ClipRRect` de la carte suffit à borner le contenu).

### A.7 Actions نسخ / مشاركة

🔒 Paire horizontale à **largeurs égales**, hauteur **48**, gap **12**, `SafeArea`, 16 au-dessus du bord sûr.
- `نسخ` — `AppButtonRole.secondary`, icône copie.
- `مشاركة` — `AppButtonRole.primary`, icône partage. **Texte simple uniquement.**
✅ Bascule verticale si largeur/action < 132 dp, `textScaler` ≥ 1,3, ou libellé tronqué (§2).
✅ Un seul bouton Primary visible sur l'écran (§3) : c'est `مشاركة`.

---

## B. Comportement UX

### B.1 Ouverture depuis Recherche

✅ Tap sur **le contenu** de `AppDuaResultCard` → `DuaReadScreen`.
✅ Transition : `SlideTransition` RTL, **300 ms** `easeInOutCubic` (150 ms en fondu si `disableAnimations`). Déjà implémentée — ne pas la modifier.
✅ Au retour : recherche **intégralement restaurée** (terme, résultats, défilement), clavier **fermé**. Fonctionne par construction (le `State` de la Recherche survit au `push`).
✅ Les cartes de résultat n'affichent **pas** de ♥ — rien à resynchroniser au retour.

### B.2 Ouverture depuis Favoris

🔒 Tap sur **le contenu** de la carte → `DuaReadScreen`. Applique le §4 Favoris (« le reste de la carte ouvre la lecture : deux cibles distinctes »), resté non câblé faute de spec d'écran de lecture.
✅ `onTap` à fournir à `AppDuaResultCard` (le paramètre existe déjà, volontairement omis jusqu'ici).
✅ Même transition que la Recherche : RTL 300 ms `easeInOutCubic`.
✅ **Resynchronisation obligatoire au retour** : si l'utilisateur a retiré le favori depuis l'écran de lecture, la carte ne doit plus être dans la liste. C'est le seul point où Favoris diffère de la Recherche (ses cartes portent un ♥).
✅ Le ♥ **de la carte** conserve son comportement actuel : retrait immédiat + snackbar `تراجع` 6 s restaurant la carte à sa position d'origine. Inchangé.

### B.3 HOME

🔒 Le douʿā du HOME reste **directement lisible sur le HOME**. Ouvrir `DuaReadScreen` n'est **jamais** obligatoire.
❌ Aucune navigation HOME → `DuaReadScreen` n'est introduite par ce LOT. Le HOME n'est pas touché.

### B.4 ♥

✅ `UserPrefs` reste l'**unique source de vérité** — aucun état local indépendant.
✅ Retirer le ♥ depuis l'écran de lecture **ne ferme jamais l'écran** : simple changement d'état, le douʿā reste lisible.
✅ Le geste est identique où qu'il soit dans l'app : un tap, effet immédiat, aucun dialogue.

### B.5 Retour

✅ `→` et le geste système reviennent à l'écran appelant, **sans perte d'état**, sans dialogue, sans confirmation.
✅ Aucune sauvegarde différée : tout est déjà persisté au moment du geste.

### B.6 Copie

✅ Copie du texte + suffixe d'attribution `\n\n— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —` (identique au HOME).
✅ `HapticFeedback.selectionClick()`.
✅ Retour : **toast du §3** — fond `textPrimary`, texte `onPrimary` 13,5, r 12, **2,5 s**, une seule ligne, aucun bouton. Remplace le `SnackBar` Material brut utilisé aujourd'hui.

### B.7 Partage texte

🔒 **Partage texte simple uniquement**, via le mécanisme natif existant (`Share.share`), avec le même suffixe d'attribution.
✅ La feuille système **est** la confirmation : aucun message, aucun écran intermédiaire, aucune animation. L'annulation ramène exactement à l'écran de lecture, sans perte d'état.
🔒 Aucun partage image dans l'interface de cet écran.
**Précision de périmètre :** cet écran n'a jamais eu de partage image — il utilise déjà `Share.share`. La décision 🔒 n'a donc **rien à retirer ici** ; elle acte que le LOT n'en ajoute pas. Le partage image reste dans `home_screen.dart` (icône ⤴), hors périmètre.

### B.8 États

✅ **Chargement** : rien. Lecture locale de quelques millisecondes — le §4 Recherche a déjà tranché « aucun indicateur de chargement » pour la même raison. Supprime le `CircularProgressIndicator` actuel.
✅ **Douʿā introuvable** : `AppEmptyState`, jamais un écran blanc (aujourd'hui `SizedBox.shrink()`). Une phrase, aucun bouton.
✅ Un **seul** `FutureBuilder` pour l'écran (aujourd'hui deux sur le même Future).

---

## C. Cohérence Design System

Aucun composant nouveau, aucun token nouveau, aucun style parallèle.

| Élément | Origine | Usage dans ce LOT |
|---|---|---|
| `AppTopBar` | `lib/widgets/app_bar.dart` | h 52, sans titre, sans action |
| `AppCard(level: hero)` | `lib/widgets/app_card.dart` | carte de lecture (rosace : voir ⏳ A.3) |
| `AppDuaResultCard` | `lib/widgets/app_dua_result_card.dart` | `onTap` désormais fourni par Favoris |
| `AppButton` | `lib/widgets/app_button.dart` | `secondary` نسخ / `primary` مشاركة |
| `AppEmptyState` | `lib/widgets/app_empty_state.dart` | douʿā introuvable |
| `AppTypography.duaLong` | `lib/theme/app_typography.dart` | texte religieux — **Lateef** |
| `AppTypography.button` | idem | libellés d'action — **IBM Plex Sans Arabic** |
| `AppSpacing` | `lib/theme/app_spacing.dart` | `lg` 16 · `xl` 20 · `xxl` 24 · `md` 12 |
| `AppColors` / `AppRadii` / `AppShadows` | `lib/theme/` | `surface`, `goldLine`/`gold`, `heroRadius`, `e2` |

✅ Deux polices, jamais trois : **Lateef** pour le douʿā, **IBM Plex Sans Arabic** pour tout le reste (ici : les libellés de boutons). Les deux sont embarquées localement depuis `dea47c1`.
✅ Toutes les valeurs d'espacement viennent de l'échelle base 4. Aucune valeur hors échelle.
✅ Contraste : texte du douʿā à opacité 1 sur `surface` — 13,9:1 en clair, ivoire sur `#18241F` en sombre.

---

## D. Règles de navigation consolidées

| Écran | Lecture du douʿā | ♥ |
|---|---|---|
| **HOME** | 🔒 directement lisible sur place — ouverture de `DuaReadScreen` **non obligatoire**, et non introduite par ce LOT | dans le pied de la carte du HOME |
| **Recherche** | 🔒 tap sur le **contenu** de la carte → `DuaReadScreen` | pas de ♥ sur les cartes de résultat |
| **Favoris** | 🔒 tap sur le **contenu** de la carte → `DuaReadScreen` | 🔒 ♥ = cible **indépendante**, retrait + `تراجع` |
| **`DuaReadScreen`** | l'écran de lecture lui-même | 🔒 dans le **pied de la carte**, jamais dans l'AppBar |
| **دعاء زيارة القبر** | écran dédié, lecture seule, **aucune action** | ❌ aucun ♥ — inchangé |

🔒 **Un point d'entrée par fonction.** Le ♥ et l'ouverture de la lecture sont deux cibles distinctes partout où les deux coexistent.

---

## E. ❌ Hors périmètre du LOT

- **Partage en image dans l'interface** de `DuaReadScreen` (la logique existante de `home_screen.dart` / `premium_export_card.dart` n'est pas touchée).
- **Premium**, monétisation, prix, badge, verrou, écran de présentation.
- **Fade / blur / gradient / opacité partielle** sur du texte religieux — refusé partout dans l'application.
- **Tout nouvel indicateur artificiel de scroll** (chevron, barre, ombre interne, dégradé).
- **Refonte du Design System** : ce LOT étend et finalise l'existant.
- **Toute obligation d'ouvrir `DuaReadScreen` depuis le HOME.**
- **Le HOME lui-même** : aucune modification.
- `دعاء آخر`, swipe entre douʿās, suggestions, catégorie affichée, historique.
- Wake lock, paysage du HOME, رمضان, `عن التطبيق` — points ouverts hérités du §7, sans rapport avec ce LOT.

---

## F. ⚠️ Incohérences signalées (non résolues par ce LOT)

**F-1 — La règle « aucun texte religieux estompé » est violée sur deux écrans publiés.**
La décision 🔒 s'applique à toute l'application. Or le `ShaderMask` + `LinearGradient` (`BlendMode.dstIn`) subsiste à deux endroits :
- `lib/home_screen.dart:765` — fondu de bord de la carte du douʿā (spécifié 44 px au §2) ;
- `lib/screens/grave_visit_read_screen.dart:172` — `_FadingDuaText`, 34 px (spécifié au §4).

Ce n'est pas un flou mais un fondu d'opacité : les glyphes deviennent transparents, ce qui se lit exactement comme un texte flou. Les deux écrans sont marqués 🟢 terminés et les deux fondus sont **des décisions verrouillées du document consolidé** — la nouvelle règle les contredit frontalement.

➡️ **Recommandation : LOT 3.J distinct** (retrait des deux `ShaderMask`, mise à jour de `ETAT_CONSOLIDE_UI_UX.md` §2 et §4). Ne pas le fondre dans le LOT 3.I : ce sont deux écrans validés, et mélanger les deux périmètres rendrait la revue impossible. Tant que le LOT 3.J n'est pas fait, la règle 🔒 n'est respectée que sur `DuaReadScreen`.

**F-2 — Asymétrie du partage entre HOME et écran de lecture.**
Après ce LOT : partage **image** disponible depuis le HOME (⤴), partage **texte** seulement depuis l'écran de lecture. Cohérent avec la décision 🔒 (retrait de l'image de cette interface), mais c'est une asymétrie assumée à connaître — elle devra être arbitrée le jour où le partage image reviendra.

**F-3 — `DuaReadOrigin` est du code mort.**
`enum DuaReadOrigin { search, favorites }` est un paramètre obligatoire jamais lu, ce que le code documente lui-même. Avec Favoris désormais câblé, il reste inutile. À supprimer dans ce LOT, ou à charger d'une différence réelle — sans quoi il devient une dette permanente.

**F-4 — Le document consolidé doit être mis à jour.**
`ETAT_CONSOLIDE_UI_UX.md` §7 classe encore l'écran de lecture « hors périmètre, non tranché », et son en-tête affirme qu'aucune ligne de Flutter n'a été écrite. Ce document-ci le remplace pour l'écran de lecture ; le §7 doit être corrigé en même temps que le LOT.

---

## G. Périmètre technique estimé

| Fichier | Intervention |
|---|---|
| `lib/screens/dua_read_screen.dart` | **Cœur du LOT** — carte N1, `duaLong`, ♥ en pied, AppBar sans action, états, toast, un seul `FutureBuilder` |
| `lib/favorites_screen.dart` | `onTap` → `DuaReadScreen` + resynchronisation de la liste au retour |
| `lib/widgets/app_card.dart` | Uniquement si l'option (b) de ⏳ A.3 est retenue (carte sans rosace) |
| `lib/search_screen.dart` | Marginal — seulement si `DuaReadOrigin` est supprimé |
| `lib/theme/app_typography.dart` | **Aucune modification** — `duaLong` existe déjà |
| `lib/widgets/app_empty_state.dart` | **Aucune modification** — réutilisation |
| `docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md` | Mise à jour §7 (voir F-4) |

---

## H. Verdict

### ✅ SPECIFICATION READY FOR IMPLEMENTATION

Aucun point bloquant. Deux points ⏳ ouverts, qui ne bloquent ni la structure ni le développement :

1. **Rosace dans la carte de lecture** (A.3) — défaut recommandé : `AppCard(level: hero)` tel quel, rosace incluse. Une ligne de code, décidable à l'œil après build.
2. **Largeur de lecture 340 dp sur téléphone large** (A.4) — à confirmer sur appareil réel, comme le §3 le prévoit déjà pour ce type de point.

Un LOT dépendant à ouvrir séparément : **LOT 3.J — retrait des fondus de bord** sur le HOME et دعاء زيارة القبر (F-1), sans quoi la règle 🔒 « aucun texte religieux estompé » ne vaut que pour cet écran.
