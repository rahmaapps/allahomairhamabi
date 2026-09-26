# LOT 68-A — Audit read-only du site vitrine Rahma Apps

> **Nature du document :** rapport d'audit uniquement. Aucun fichier du site n'a été modifié, rien n'a été commité ni poussé, aucun réglage GitHub Pages n'a été changé.
> **Date de l'audit :** 24 septembre 2026
> **Site audité :** https://rahmaapps.github.io/allahomairhamabi/
> **Référence fonctionnelle (app) :** branche `github-migration`, commit `e8e27a415d666a4952e70ccf83e3acaae883534f` (fin du LOT 67)
> **Méthode :** lecture des sources locales, comparaison octet par octet avec la version publiée (`curl`), inspection de l'API GitHub publique, rendu réel dans un navigateur à 1920, 1366, 768 et 375 px, console, requêtes réseau, mesures DOM.

---

## A. État actuel du site

### A.1 Identification

| Élément | Constat |
|---|---|
| Repository | `rahmaapps/allahomairhamabi` (public, langage détecté : Dart) |
| Owner | `rahmaapps` (compte GitHub) |
| Remote local | `github-app` → `https://github.com/rahmaapps/allahomairhamabi.git` (le remote `origin` pointe vers GitLab `rahmaapps/rahmaapps`) |
| Branche publiée | `main` (branche par défaut ; HEAD `5760ca9 docs(privacy): publish rewarded ads policy`) |
| Source Pages | Mode « Deploy from a branch », racine `/` de `main` : un seul workflow, `pages-build-deployment` (dynamique, créé le 19/02/2026). L'API `/pages` renvoie 404 sans authentification, donc la source exacte (`/` ou `/docs`) est **déduite** : `index.html` est servi à la racine du site. |
| Build | Build **Jekyll** implicite de GitHub (aucun `.nojekyll`, aucun `_config.yml`) |
| GitHub Actions | Aucun workflow dans `.github/` (il n'existe pas) ; seul le workflow Pages automatique |
| Domaine | Aucun `CNAME`. URL projet `/allahomairhamabi/` sous le site utilisateur `rahmaapps.github.io` (repo `rahmaapps/rahmaapps.github.io`, un site Jekyll « Rahma Apps developer site ») |
| Base path | `/allahomairhamabi/`. Tous les liens du site sont relatifs, donc compatibles. |
| Technologie | 1 page HTML statique + CSS inline. Aucun JS, aucun framework, aucun CDN sur `index.html` |
| Dernière publication | `Last-Modified: Wed, 23 Sep 2026 20:27:51 GMT` |

### A.2 Fichiers publiés du site

| Fichier | Rôle | Remarque |
|---|---|---|
| `index.html` (4,4 Ko) | Page vitrine unique (AR, RTL) | Identique octet pour octet entre la version locale (`HEAD`) et la version publiée |
| `privacy_ar.html` | Politique de confidentialité AR | Identique local/publié ; mise à jour le 23/09/2026 (annonces avec récompense) |
| `privacy_fr.html` | Politique de confidentialité FR | Identique local/publié ; **aucun lien vers elle depuis `index.html`** |
| `Logo.jpg` | Logo | 200×200 JPEG, 3 Ko |
| `mockup_home/favorites/settings.png` | Visuels « صور التطبيق » | 1080×1920 PNG, 224 à 437 Ko chacun |
| `mockup_*.jpeg` | Doublons JPEG des mockups | Publiés mais **non référencés** |
| `app-ads.txt` | Déclaration AdMob | Présent sur `main` et publié (`google.com, pub-2998944710358464, DIRECT, f08c47fec0942fa0`), **absent de la branche `github-migration`** (voir H.1) |

### A.3 Structure de la page (ordre réel)

1. **Header** : logo 120 px, H1 `تطبيق "اللهم ارحم أبي"`, accroche, bouton CTA `تحميل التطبيق من متجر Google Play`
2. **H2** `✨ المميزات التي تجعل موقعنا خيارك الأفضل` suivi d'une liste de 15 fonctionnalités (emoji + texte)
3. **H2** `صور التطبيق` : 3 mockups (Home, Favoris, Settings)
4. **H2** `سياسة الخصوصية` : un lien vers `privacy_ar.html`
5. **Footer** : `© 2026 – تطبيق اللهم ارحم أبي` / `تم التطوير بواسطة Rahma Apps`

Pas de navigation, pas de `<main>`/`<nav>`, pas de page secondaire autre que les deux politiques.

### A.4 Contenu

- **Langue :** arabe uniquement (`lang="ar" dir="rtl"`). Pas de version FR/EN de la vitrine. La politique FR existe mais est orpheline.
- **Nom affiché :** « اللهم ارحم أبي », sans tashkīl. L'app affiche `اللَّهُمَّ ارْحَمْ أَبِي` (avec tashkīl) dans son titre et ses textes de partage, et le libellé Android est `اللهم ارحم أبي`.
- **Accroche :** « أدعية مختارة لوالدك، مصنّفة وعشوائية، مع مشاركة سهلة وتصميم جميل » : centrée sur « le père / ton père ».
- **Lien avec l'app :** le menu `الإعدادات ← عن التطبيق` de l'app ouvre **cette page** (`lib/settings_screen.dart:327`). Le site fait donc partie de l'expérience in-app, en plus de son rôle de vitrine.

### A.5 Visuel

| Aspect | Site | Design System de l'app (`lib/theme/`) |
|---|---|---|
| Fond | Vert très sombre `#063F1D` uniforme | Light : crème `#FFFBF1`. Dark : `#101A16` |
| Couleur primaire | `#0B542E` / hover `#0E7045` | `#006A4E` (Light), `#009F6B` (Dark), accent or `#D4AF37` / `#E3C570` |
| Texte | Crème `#FCEECB` | `#1E2A24` (Light), `#F3EEE1` (Dark) |
| Typographie | `"Noto Kufi Arabic", sans-serif`, **non chargée** (ni `@font-face` ni Google Fonts), donc police système de repli | `Lateef` (texte du douʿā, titre) + `IBM Plex Sans Arabic` (UI), embarquées |
| Cartes | `rgba(255,255,255,.1)`, rayon 10 px | Surfaces blanches/crème, bordure `#EADFC8`, ombres teintées vert |
| Iconographie | Emojis | Icônes Material et motifs islamiques (mashrabiya) |
| Logo | `Logo.jpg` 200×200 : même dessin (mains + calligraphie) que `assets/icon/app_icon.png` (1024×1024), mais en basse résolution et en JPEG | App icon figée (voir `docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md`) |

Les « screenshots » sont des **mockups marketing** (titre, sous-titre, capture dans un cadre) qui montrent **l'ancienne interface** (voir D.2).

---

## B. Architecture du repository

```
rahmaapps/allahomairhamabi (main)          ← repo public, sert À LA FOIS l'app Flutter et le site
├── index.html, privacy_ar.html, privacy_fr.html     ← site
├── Logo.jpg, mockup_*.png, mockup_*.jpeg            ← assets du site (à la racine)
├── app-ads.txt                                      ← AdMob (main uniquement)
├── lib/, android/, ios/, web/, test/, assets/ ...   ← code source de l'app
├── docs/ (V1.2_PROGRESS.md, backups JSON, premium_previews/…)
└── README.md, pubspec.yaml, …
```

- **233 fichiers** sur `main`. Comme Pages publie la racine entière avec Jekyll, **tout le repo est servi en HTTP** sous `/allahomairhamabi/`. Vérifié (réponse 200) : `README.md`, `pubspec.yaml`, `lib/main.dart`, `android/app/build.gradle.kts`, `web/index.html`, `docs/V1.2_PROGRESS.md` et même `docs/V1.2_PROGRESS.html` (rendu Markdown→HTML par Jekyll).
- Aucun secret détecté dans l'arbre publié : `key.properties`, `local.properties`, `*.jks` et `google-services.json` sont absents et ignorés par `.gitignore`. Le repo étant public, ce contenu est déjà visible sur GitHub. L'exposition via Pages ajoute donc de la **découvrabilité et du bruit SEO**, pas une fuite nouvelle.
- **Branches divergentes :** `github-app/main` n'est **pas** un ancêtre de `github-migration`. `main` porte 2 commits absents localement (`6c09043 chore: add AdMob app-ads.txt`, `5760ca9 docs(privacy): publish rewarded ads policy`), et `github-migration` a 42 commits en avance.
- Pas de séparation site/app : pas de dossier `site/` ou `docs/` dédié, pas de branche `gh-pages`.

---

## C. Ce qui doit être conservé

| Élément | Raison |
|---|---|
| URL `https://rahmaapps.github.io/allahomairhamabi/` | Référencée **en dur dans l'app** (`عن التطبيق`, `lib/settings_screen.dart:327`). Changer l'URL casserait ce lien dans les versions installées. |
| URLs `privacy_ar.html` / `privacy_fr.html` | Probablement déclarées dans la Play Console (à confirmer). Leur contenu est à jour (23/09/2026) et cohérent avec l'app (voir J). |
| `app-ads.txt` servi par Pages | Requis par AdMob (vérification vendeur). Voir H.1 sur sa localisation réelle. |
| RTL arabe comme langue principale | L'app est mono-langue arabe RTL (`locale: Locale('ar')`, `lib/main.dart`). |
| Identité verte et émotion (ton « rahma ») | Cohérent avec l'app. La teinte exacte reste à aligner. |
| Dessin du logo (mains + calligraphie) | Identique à l'icône de l'app. |
| Mentions éditeur « Rahma Apps » et contact | Déjà présents dans les politiques. |
| Plusieurs messages fonctionnels encore vrais | Favoris, rappels, douʿās du vendredi, recherche, thème clair/sombre, variété courts/longs (voir tableau D.1). |

---

## D. Ce qui est obsolète

### D.1 Liste des fonctionnalités, ligne par ligne (15 items)

| # | Texte du site (résumé) | Statut vs app `e8e27a4` |
|---|---|---|
| H2 | « المميزات التي تجعل **موقعنا** خيارك الأفضل » | ❌ **Erreur** : parle de « notre site », pas de l'application |
| 1 | Douʿās courts et longs pour le défunt | ✅ Vrai (champ `length` قصيرة/طويلة). Le filtre de longueur n'est plus un réglage visible (voir mockup Settings). |
| 2 | Douʿās choisis pour **ton père** | ⚠️ Réducteur : l'app couvre **11 personnes** (أب، أم، والدين، جد، جدة، أخ، أخت، ابن، ابنة، زوج، زوجة), sélection multiple et prénom optionnel |
| 3 | Douʿās spéciaux « **ليلة** الجمعة » | ✅ En substance (onglet `دعاء الجمعة`, 25 par personne + 8 généraux). La formulation « nuit du vendredi » est à vérifier avec le contenu réel. |
| 4 | Douʿās spéciaux **Ramadan** | ⚠️ **À trancher** : 374 douʿās Ramadan présents dans les données (34 × 11), **sans entrée dédiée dans l'UI**. Ils ne sont atteignables que par la Recherche (`getAllDuas()` indexe tout). `ETAT_CONSOLIDE_UI_UX.md` les qualifie de « hors périmètre, non tranché ». L'ancien Home avait un chip `دعاء رمضان`, visible sur le mockup. |
| 5 | Sauvegarde des favoris | ✅ Vrai |
| 6 | Douʿā aléatoire | ✅ Vrai (bouton `دعاء آخر`) |
| 7 | Rappel **quotidien** | ✅ Vrai, et plus riche : rappels matin, soir **et vendredi**, heures configurables |
| 8 | Fonctionne **entièrement** hors ligne | ⚠️ Partiellement vrai : le contenu est embarqué, mais les publicités et le consentement UMP utilisent Internet (permission déclarée dans la politique) |
| 9 | Design élégant | ✅ (et refondu depuis, voir D.2) |
| 10 | Contenu fiable et choisi avec soin | ✅ (LOT 67 : corrections éditoriales) |
| 11 | Partage rapide **via WhatsApp** | ❌ **Obsolète** : l'intégration WhatsApp a été supprimée (LOT 3.O). Le partage passe par la feuille native du système (texte) et « مشاركة كصورة ». |
| 12 | Accès rapide aux favoris | ✅ Doublon de l'item 5 |
| 13 | Moteur de recherche intelligent | ✅ Recherche plein texte (debounce 250 ms) sur tout le catalogue. « ذكي » est un peu survendu. |
| 14 | Thème clair et sombre | ✅ Vrai (تلقائي / فاتح / داكن) |
| 15 | « تجربة نقية 100% **بدون إعلانات** مزعجة » | ❌ **Faux et contradictoire** : l'app affiche des bannières, des interstitiels et des annonces avec récompense AdMob, ce que la politique publiée sur ce même site déclare explicitement. Risque de conformité (Play / publicité mensongère). |

### D.2 Mockups `صور التطبيق` : tous obsolètes

Relevé visuel des 3 PNG :

- **mockup_home :** chips `عام / دعاء الجمعة / دعاء رمضان` (le chip Ramadan n'existe plus), bouton vert `شارك الأجر – أرسل التطبيق لأهلك` avec l'icône WhatsApp (supprimé), sous-titre « انسخ وشارك عبر واتساب ». Pas de ligne `تدعو لـ …`, pas d'entrée `دعاء زيارة القبر`.
- **mockup_favorites :** style Material 3 par défaut (fond lavande, chips grises), antérieur au Design System Phase 2.
- **mockup_settings :** interrupteurs **violets** Material par défaut, rappel **`بعد الظهر` 15:00** (supprimé, LOT 3.G), section `الطول المفضل` (plus présente), bouton `حفظ` (les réglages s'enregistrent maintenant automatiquement), sous-titre anglais **« SETTING »** (faute : il faudrait « SETTINGS »). Aucune trace de `خيارات الخصوصية`, de l'heure sans publicité ni de `مشاركة التطبيق`.

### D.3 Autres éléments obsolètes

- Bouton `تحميل التطبيق من متجر Google Play` avec `href="#"` et le commentaire « à activer après publication ». **La fiche Play existe et répond** (`https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi` → 200), et l'app elle-même partage déjà ce lien (`lib/settings_screen.dart:68`).
- `Logo.jpg` en 200×200 JPEG alors que l'icône master existe en 1024×1024 PNG et en SVG (`assets/icon/`).

---

## E. Ce qui manque

Les fonctionnalités réelles absentes du site sont listées ci-dessous. **Leur présence sur le site n'est pas une obligation** : c'est une décision produit (colonne « Décision »).

| Fonctionnalité app | Présente sur le site ? | Intérêt vitrine | Décision |
|---|---|---|---|
| **Choix de la personne (11 types, multi-sélection, prénom optionnel)** | Non (le site ne parle que du père) | ⭐ Fort : c'est le différenciateur principal | Recommandé |
| **Onboarding** `لمن تدعو؟` → `تذكير يومي؟` | Non | Moyen | Optionnel |
| **Écran de lecture** (typographie Lateef, grand confort) | Non | ⭐ Fort : c'est le cœur émotionnel | Recommandé |
| **دعاء زيارة القبر** (GraveVisit, sans publicité) | Non | Fort, différenciant | Décision produit (sensibilité du sujet) |
| **مشاركة كصورة** (Share as Image, modèles premium Emerald / Dark Luxe / White Elegant, pagination) | Non | ⭐ Fort visuellement | **Décision produit** : fonction débloquée par une annonce avec récompense ; il faut une présentation honnête |
| Copier / partager le texte (gratuit, toujours) | Partiel (« WhatsApp ») | Moyen | À reformuler |
| Rappels matin / soir / vendredi | Partiel (« quotidien ») | Moyen | À préciser |
| Publicités + « heure sans publicité » via annonce avec récompense | **Non, et le site affirme le contraire** | Transparence | **Obligatoire** : a minima retirer « sans publicité » ; décision sur la manière d'en parler |
| Consentement UMP / `خيارات الخصوصية` | Non (seulement dans la politique) | Faible (vitrine), fort (confiance) | Couvert par la politique |
| In-App Review | Non | Nul en vitrine | Ne pas présenter |
| Nombre de douʿās (Recherche : « ابحث في N دعاء ») | Non | Moyen (preuve de richesse) | Décision : chiffre exact à figer |
| Lien vers la politique **FR** | Non | Légal / confiance | Recommandé |
| Contact éditeur (`contact.rahmaapps@gmail.com`) | Non (seulement dans les politiques) | Confiance, requis par Play pour le site développeur | Recommandé |
| Mention plateforme (Android uniquement) | Non | Clarté | Recommandé. iOS n'est pas publié : `CFBundleDisplayName` vaut encore `Test 1` dans `ios/Runner/Info.plist`. |

---

## F. Problèmes UX/UI

1. **Aucune démonstration réelle du produit** au-dessus de la ligne de flottaison : à 1366×768, le premier écran ne montre que logo, titre, accroche, CTA et le début de la liste.
2. **CTA principal mort** (`href="#"`) : l'action la plus importante de la page ne fait rien.
3. **Liste à plat de 15 items** avec emojis : pas de hiérarchie, des doublons (favoris ×2), un ton générique (« خيارك الأفضل »).
4. **Identité visuelle déconnectée de l'app** : fond vert sombre uniforme contre une app crème/or en Light ; police système au lieu de Lateef/Plex ; emojis au lieu du langage graphique de l'app.
5. **Mockups à fort texte intégré** (titres dans l'image) : non traduisibles, non accessibles, et en conflit visuel avec les H2 du site.
6. **Messages faux** (sans publicité, WhatsApp) : ils minent la confiance, surtout pour une app religieuse où la sincérité compte.
7. Le texte « موقعنا » (notre site) crée une confusion site/app.
8. **Footer minimal** : pas de lien vers la politique, pas de contact, pas de mention Android.
9. Le lien vers la politique est une section entière (H2) pour un seul lien, sans version FR.

---

## G. Problèmes responsive

Mesures réelles dans le navigateur (DOM + captures) :

| Largeur | Hauteur page | Débordement horizontal | Constats |
|---|---|---|---|
| **1920** (desktop large) | 2 422 px | Non | Colonne de contenu figée à 650 px (`max-width:600px` + padding) : grands vides latéraux, page « mobile étirée ». Mockups de 274 px de large, petits. |
| **1366** (desktop standard) | 2 422 px | Non | Idem. 3 mockups sur une ligne. Le premier écran ne contient aucun visuel produit. |
| **768** (tablette) | 2 934 px | Non | Mockups en **2 + 1** : le 3ᵉ se retrouve orphelin, centré sur une seconde ligne. |
| **375** (smartphone) | **4 050 px** | Non (`scrollWidth = 375`, aucun élément hors viewport) | Page très longue : 15 cartes puis 3 mockups empilés (≈ 484 px chacun). Le libellé du CTA se coupe de façon disgracieuse (« Google / Play » sur deux lignes, visible sur la capture). H1 de 32 px sur 2 lignes. |

Autres constats :

- **Aucune media query** dans `index.html` : tout le responsive repose sur le flux inline et `max-width`.
- Images servies en 1080×1920 PNG quelle que soit la taille d'affichage (pas de `srcset`, `width/height` ni `loading="lazy"`), environ **960 Ko** d'images pour 3 vignettes de 274 px.
- `text-align:center` global avec `.features` en `text-align:right` : correct en RTL, mais le mélange centre/droite est incohérent.

---

## H. Problèmes techniques

### H.1 Critiques / à traiter en priorité dans le LOT 68-B

1. **`app-ads.txt` : risque de régression.** Il existe sur `main` (`6c09043`) mais **pas** sur `github-migration`. Si `main` est un jour remplacé par `github-migration` (reset ou force-push au lieu d'un merge), le fichier disparaît et AdMob peut limiter la diffusion. **Point d'attention :** AdMob lit `app-ads.txt` à la **racine du domaine développeur**, c'est-à-dire `https://rahmaapps.github.io/app-ads.txt`. Ce fichier existe et répond 200, **servi par le repo `rahmaapps/rahmaapps.github.io`**. La copie sous `/allahomairhamabi/app-ads.txt` n'est probablement pas celle que lit AdMob. À confirmer : le « site web du développeur » déclaré dans la Play Console.
2. **Branches divergentes :** `main` et `github-migration` ont un historique divergent (2 commits d'un côté, 42 de l'autre). La stratégie de publication du LOT 68-B doit être décidée **avant** toute modification du site.
3. **Tout le repo est publié** par Pages (source Flutter, `docs/` internes, backups JSON de douʿās, notes de progression rendues en HTML par Jekyll). Ce n'est pas une fuite de secrets, mais c'est du bruit indexable, de la documentation interne exposée et un couplage fort site/app.

### H.2 Constats de fonctionnement

| Contrôle | Résultat |
|---|---|
| Erreurs console | Aucune |
| Ressources cassées (index) | Aucune (4/4 images en 200) |
| Liens morts | 1 lien factice (`#`, CTA Play). `privacy_ar.html` → 200. |
| Favicon | ❌ Absent : aucun `<link rel="icon">` ; `/favicon.ico` → 404 (sous le projet comme à la racine du domaine) |
| Police | `Noto Kufi Arabic` déclarée mais jamais chargée : le rendu varie selon l'OS |
| Poids | HTML 4,4 Ko et images ≈ 960 Ko (PNG non optimisés). Doublons JPEG publiés inutilement (≈ 380 Ko). |
| Cache | `Cache-Control: max-age=600` (défaut GitHub Pages) |
| Politique FR | Charge une image décorative depuis **`https://i.imgur.com/rPc05iI.png`**, qui répond **302** (redirection, probablement supprimée ou bloquée) : dépendance tierce fragile |
| Politiques AR/FR | Chargent Google Fonts (Amiri, Lateef), ce qui fait une requête vers un tiers (Google) sans consentement ; à signaler dans le contexte RGPD |

### H.3 Accessibilité (constats évidents)

- `alt="Logo"`, `alt="Home"`, `alt="Favorites"`, `alt="Settings"` : textes alternatifs **en anglais** sur une page arabe, et non descriptifs.
- Pas de landmarks (`<main>`, `<nav>`), hiérarchie H1 → H2 correcte mais les emojis dans les titres sont lus par les lecteurs d'écran.
- Liens au style inline (`#B8F3C2`) ; pas d'état `:focus` visible défini ; le bouton n'a pas d'état focus.
- Contraste texte crème sur vert sombre : bon. Cartes `rgba(255,255,255,.1)` : contraste correct mais faible séparation visuelle.
- Le logo `<img>` de la politique FR n'a **pas d'attribut `alt`**.

### H.4 RTL

- `lang="ar" dir="rtl"` correctement posés sur `index.html` et `privacy_ar.html`.
- Aucun problème de sens constaté. Les chaînes mixtes (« Google Play ») se rendent correctement dans le bouton, mais la coupure de ligne mobile isole « Play ».
- `privacy_fr.html` : `lang="fr"` en LTR, avec des fragments arabes inline (`« Réglages → خيارات الخصوصية »`) sans `<bdi>`/`dir` : rendu bidi à vérifier.

---

## I. SEO / metadata

| Élément | `index.html` |
|---|---|
| `<title>` | `تطبيق اللهم ارحم أبي` : présent, court, sans marque « Rahma Apps » ni mot-clé (أدعية للميت…) |
| meta description | ❌ Absente |
| canonical | ❌ Absent |
| Open Graph (`og:title/description/image/url/type/locale`) | ❌ Absent. Un partage WhatsApp ou Facebook du lien n'affiche ni image ni description (important : l'app partage des contenus et le site est le lien « عن التطبيق »). |
| Twitter/X cards | ❌ Absentes |
| favicon / apple-touch-icon | ❌ Absents |
| `lang` / `dir` | ✅ `ar` / `rtl` |
| `hreflang` (AR ↔ FR) | ❌ Absent (seules les politiques existent en FR) |
| Données structurées (`SoftwareApplication` / `MobileApplication`) | ❌ Absentes |
| `robots.txt` / `sitemap.xml` | ❌ 404 |
| `theme-color` | ❌ Absent |
| Indexation parasite | ⚠️ Fichiers source et docs internes servis et indexables (voir H.1-3) |

---

## J. Privacy / liens légaux

| Point | Constat |
|---|---|
| Lien depuis la vitrine | `privacy_ar.html` uniquement (relatif) ; **pas de lien vers `privacy_fr.html`** |
| Contenu AR et FR | Tous deux datés du **23 septembre 2026**, parallèles, et **cohérents avec l'app** : données locales (personnes, prénoms, favoris, rappels, thème, dates techniques, heure sans publicité, jeton « partage comme image ») ; AdMob (bannières sur Home/Recherche/Favoris ; interstitiels au retour Recherche/Favoris → Home, au plus 1 toutes les 10 min ; annonces avec récompense facultatives : 1 h sans publicité ou 1 partage en image) ; aucune publicité pendant la lecture, sur la visite au cimetière, l'onboarding, au démarrage ni dans les réglages ; UMP ; `خيارات الخصوصية` ; In-App Review ; permissions ; aucune analytics ni crash reporting ; contact `contact.rahmaapps@gmail.com` ; éditeur Rahma Apps (Maroc). |
| **Contradiction majeure** | La vitrine dit « 100% **بدون إعلانات** » alors que la politique, sur le même site, décrit trois formats publicitaires. |
| Lien Google Play | Absent de la vitrine (`#`). Fiche active : `https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi`. |
| App Store | Aucun lien, et c'est cohérent : app non publiée sur iOS (la politique dit « application … pour Android »). |
| Trackers / analytics sur le site | **Aucun** sur `index.html` (aucun script, aucune requête tierce). Les **politiques** chargent Google Fonts ; `privacy_fr.html` charge aussi une image imgur. Aucun bandeau cookies nécessaire aujourd'hui pour la vitrine seule. |
| `app-ads.txt` | Voir H.1-1 |
| Mentions légales / contact sur la vitrine | Absents (présents seulement dans les politiques) |
| Titre FR | La politique FR utilise « **Allahuma Irham Abi** » : translittération à harmoniser avec le nom Play et le nom interne (`allahomairhamabi`) |

Aucun texte légal n'a été modifié.

---

## K. Proposition de structure future

> 💡 **PROPOSITION — À VALIDER**
> Rien ci-dessous n'est une décision. Cette structure sert de base à la discussion du LOT 68-B.

**Principes proposés :** une seule page, arabe RTL d'abord ; honnêteté totale (publicités mentionnées) ; vraies captures ; identité alignée sur le Design System Phase 2 ; URLs existantes conservées.

1. **Hero** : icône HD, nom `اللَّهُمَّ ارْحَمْ أَبِي`, accroche élargie à « من تحب » (pas seulement le père), **badge Google Play officiel actif**, capture principale (Home ou lecture) visible dès le premier écran sur desktop.
2. **« لمن تدعو؟ »** : bloc sur la personnalisation (11 personnes, multi-sélection, prénom optionnel) avec la capture de sélection.
3. **Lire et invoquer** : écran de lecture, `دعاء آخر`, douʿās du vendredi (et Ramadan **seulement si** la décision produit le permet).
4. **Retrouver** : Recherche et Favoris (2 captures).
5. **Moments** : rappels matin, soir et vendredi ; دعاء زيارة القبر (si validé).
6. **Partager le أجر** : copier/partager le texte (gratuit) et partager en image (modèles). Formulation honnête sur le déblocage via annonce avec récompense, **à valider**.
7. **Transparence** : bloc court « gratuit, financé par la publicité ; aucune publicité pendant la lecture ni en visite au cimetière ; aucun compte ; données sur l'appareil » avec un lien vers la politique.
8. **Footer** : politique AR et FR, contact, Rahma Apps, « Android », © 2026.

Options à trancher : version FR ou EN de la vitrine (ou non) ; sous-dossier dédié au site ; `.nojekyll` et/ou exclusion Jekyll des sources ; section « nombre de douʿās ».

---

## L. Screenshots recommandés

> Captures **réelles** de l'app à `e8e27a4` (ou à la baseline qui sera figée), **aucune prise dans ce LOT**.
> **Règles communes :** portrait 9:16 sur un appareil Android réel ou un émulateur propre (1080×2400 ou 1080×1920) ; barre d'état nettoyée (heure neutre, batterie pleine, pas de notifications, via le *demo mode* Android) ; **aucune publicité visible** (utiliser une heure sans publicité active ou les unités de test hors cadre, et ne jamais montrer une bannière de test « Test Ad ») ; aucune donnée personnelle réelle (prénoms fictifs neutres ou aucun) ; même thème pour toute la série, avec éventuellement une variante Dark pour 1 ou 2 écrans.

| # | Écran | Objectif | Orientation | Cadrage | À éviter | État à préparer | Pourquoi sur le site |
|---|---|---|---|---|---|---|---|
| 1 | **Home** (douʿā du jour) | Hero : montrer immédiatement l'app réelle | Portrait | Plein écran, sans le clavier | Bannière publicitaire en bas ; toast ; douʿā trop long qui déborde | Personne sélectionnée (ex. `أبي`), ligne `تدعو لـ أبي`, douʿā court ou moyen bien lisible, onglet `عام` | Première impression, preuve de qualité visuelle |
| 2 | **Sélection d'une personne** (`PersonSelectionScreen` ou onboarding `لمن تدعو؟`) | Montrer le différenciateur : 11 proches | Portrait | Grille de chips complète visible | Snackbar « تراجع » ; clavier ouvert | 2 à 3 personnes cochées, champ prénom vide ou prénom fictif | Élargit la cible au-delà du « père » |
| 3 | **Lecture d'une douʿā** (`DuaReadScreen`) | Confort de lecture (Lateef, interligne ≥ 2) | Portrait | Texte centré, marges visibles | Texte coupé ; très long douʿā | Douʿā moyen, idéalement ouvert depuis les Favoris | Cœur émotionnel du produit |
| 4 | **Recherche** | Richesse du catalogue et rapidité | Portrait | Champ et 3 ou 4 résultats | Clavier plein écran (ou le garder volontairement, à décider) ; « لا توجد نتائج » | Requête courte pertinente (ex. `الجنة`) avec résultats | Utilité concrète |
| 5 | **Favoris** | Retrouver ses douʿās | Portrait | Liste de 3 cartes | État vide ; snackbar de suppression ; bannière publicitaire | 3 favoris de longueurs variées | Fidélisation |
| 6 | **Douʿā du vendredi** (Home, onglet `دعاء الجمعة`) | Moment spirituel du vendredi | Portrait | Comme le n°1 | Confusion visuelle avec le n°1 | Onglet vendredi actif | Montre la catégorie sans capture dédiée (optionnel si fusion avec le n°1) |
| 7 | **دعاء زيارة القبر** (`GraveVisitReadScreen`) | Accompagnement au cimetière | Portrait | Écran de lecture complet | Tout élément commercial (l'écran est garanti sans publicité) | Personne choisie | Différenciant, **sous réserve de validation produit** (sensibilité) |
| 8 | **Share as Image** (image exportée, pas l'écran) | Qualité des visuels partageables | Portrait (format d'export) | L'image générée seule, éventuellement avec 2 ou 3 modèles côte à côte | Feuille de confirmation « annonce avec récompense » ; feuille de partage système | Générer l'export Emerald et Dark Luxe sur un douʿā court | Argument visuel fort ; **présentation à valider** (déblocage par récompense) |
| 9 | **Settings** | Rappels et thème | Portrait | Sections `التذكير` et `المظهر` | Ligne « heure sans publicité » si elle prête à confusion (décision) ; permission refusée | Rappels matin, soir et vendredi activés à des heures lisibles | Montre la personnalisation. **Moins prioritaire** que les n°1 à 5. |
| 10 | *(optionnel)* **Home en Dark** | Montrer le thème sombre | Portrait | Comme le n°1 | Mélange Light/Dark dans une même rangée | Thème `داكن` | Répond à l'item « فاتح وداكن » |

Sélection minimale suggérée (**à valider**) : 1, 2, 3, 4, 5 et 8. Les autres sont optionnelles.

---

## M. Intervention Claude Design

Points à faire valider par Claude Design dans le LOT 68-B, **avant** toute implémentation :

1. **Direction visuelle** : vitrine claire (crème `#FFFBF1` + vert `#006A4E` + or) alignée sur le Light de l'app, sombre alignée sur le Dark (`#101A16`), ou hybride (hero sombre, contenu clair).
2. **Cohérence avec le Design System Phase 2** (`docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md` §3, `lib/theme/*`) : quels tokens (couleurs, rayons, ombres teintées, espacements base 4) reprendre sur le web.
3. **Typographie web** : Lateef (titres et citations de douʿā) + IBM Plex Sans Arabic (UI) en auto-hébergé ou via Google Fonts (impact vie privée, voir J), tailles responsives, interligne des citations.
4. **Hiérarchie des sections** et longueur de page cible, notamment sur mobile (aujourd'hui 4 050 px).
5. **Présentation des screenshots** : cadre d'appareil ou capture nue, ombre, rayon ; alternance texte/capture ; carrousel ou grille ; gestion desktop, tablette (éviter le 2 + 1) et mobile.
6. **Responsive** : breakpoints, largeur max du contenu desktop, comportement du hero.
7. **RTL** : miroir des alternances texte/image, placement du badge Play, chiffres (occidentaux, décision UX déjà prise dans l'app pour la Recherche).
8. **CTA** : badge Google Play officiel (règles de marque Google), répétition éventuelle en bas de page.
9. **Branding** : icône HD (le master SVG existe), nom avec ou sans tashkīl, place de « Rahma Apps », motif islamique (mashrabiya) sur le web ou non.
10. **Bloc transparence publicité** : ton et placement (honnête sans être anxiogène).
11. **Image Open Graph** (1200×630) : composition.
12. **Favicon** : déclinaison à 16/32 px. L'icône a un défaut connu sous 32 px (voir `ETAT_CONSOLIDE_UI_UX.md`, « État de l'App Icon »), il faut donc peut-être une version simplifiée.

---

## N. Plan LOT 68-B

| Étape | Contenu | Dépendances / décisions préalables |
|---|---|---|
| **0. Pré-requis Git/Pages** *(ajouté par l'audit)* | Décider de la stratégie de branche (réconcilier `main` ↔ `github-migration`, avec préservation garantie de `app-ads.txt` et des politiques) ; décider de l'isolation du site (dossier dédié, `.nojekyll`, `_config.yml` avec `exclude`, ou repo séparé) **sans changer l'URL publique** ; confirmer quel `app-ads.txt` lit AdMob. | Validation utilisateur |
| **1. Validation de la structure** | Arbitrer la proposition K ; trancher Ramadan, GraveVisit, Share as Image (formulation récompense), langues de la vitrine, nombre de douʿās affiché, publicités. | Décisions produit |
| **2. Préparation des écrans de l'app** | Build de release ou de profil à la baseline figée ; données de démo (personnes, favoris, rappels) ; demo mode de la barre d'état ; stratégie « aucune publicité visible ». | Étape 1 |
| **3. Captures réelles** | Série de la section L, même appareil, même thème, nommage stable. | Étape 2 |
| **4. Validation visuelle des captures** | Revue Claude Design et utilisateur : lisibilité, cohérence, absence de publicité ou de donnée perso ; export WebP/PNG optimisé + `srcset`. | Étape 3 |
| **5. Implémentation du site** | HTML/CSS statique (pas de framework requis), tokens DS, polices, sections validées, textes AR relus (et FR si retenu). | Étapes 1 et 4 + maquette Claude Design |
| **6. Responsive** | Tests 1920 / 1366 / 768 / 375 (+ 320), RTL, mode sombre éventuel. | Étape 5 |
| **7. SEO** | `title`, meta description, canonical, Open Graph et Twitter, image OG, favicon et apple-touch-icon, `theme-color`, JSON-LD `MobileApplication`, `robots.txt`, `hreflang` si FR. | Étape 5 |
| **8. Privacy / legal links** | Liens AR et FR dans le footer, contact, suppression de « بدون إعلانات », lien Play actif ; décider de la dépendance imgur et de Google Fonts dans les politiques (modifications à valider séparément, **sans** toucher au fond juridique). | Étape 1 |
| **9. QA** | Liens (Play, politiques, `app-ads.txt` aux deux emplacements), console, poids des pages, Lighthouse (perf, a11y, SEO), vérification du lien `عن التطبيق` depuis l'app, aperçu de partage WhatsApp. | Étapes 5 à 8 |
| **10. Publication GitHub Pages** | Merge et push selon la stratégie de l'étape 0 ; vérification post-déploiement (`index`, politiques, `app-ads.txt`, 404 attendus) ; aucun changement d'URL. | Validation finale utilisateur |

---

## Annexe — Contrôle Git de l'audit

- Aucun fichier existant modifié.
- Aucun commit, aucun push, aucun changement GitHub Pages.
- Seul nouveau fichier : `docs/LOT68_AUDIT_SITE.md` (ce rapport), **non suivi et non commité**.
