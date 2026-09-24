# LOT 68-B.0.1 — Migration technique du site GitHub Pages

> **Statut :** migration préparée **localement**, **non commitée, non poussée**. Aucun réglage GitHub n'a été modifié : ils ne sont pas modifiables depuis Claude Code et **n'ont pas été modifiés**.
> **Date :** 25 septembre 2026
> **Branche :** `github-migration` @ `e8e27a4` (HEAD inchangé)
> **Références :** [LOT68_AUDIT_SITE.md](LOT68_AUDIT_SITE.md) (68-A), [LOT68_B0_ARCHITECTURE_SITE.md](LOT68_B0_ARCHITECTURE_SITE.md) (68-B.0, option A3 retenue)

---

## 1. Objectif

Isoler le site public dans `site/` et préparer une publication GitHub Pages **par GitHub Actions ne publiant que ce dossier**, afin que le code Flutter, `docs/` et les fichiers techniques ne soient plus servis.

Contraintes respectées :
- aucune modification de contenu ou de design du site ;
- aucune modification de l'application ;
- URL publiques strictement inchangées.

---

## 2. Architecture avant

```
repo allahomairhamabi (branche main publiée)
├── index.html, privacy_ar.html, privacy_fr.html     ← site (racine)
├── Logo.jpg, mockup_*.png, mockup_*.jpeg            ← assets du site (racine)
├── lib/, android/, ios/, assets/, docs/, test/ …    ← app + doc interne
└── (pas de .github/)
Pages : « Deploy from a branch » → main, / (racine) → Jekyll implicite
        ⇒ tout le repo (hors dotfiles) servi sous /allahomairhamabi/
```

---

## 3. Architecture après

```
repo allahomairhamabi
├── site/                                ← SEUL contenu publié
│   ├── index.html
│   ├── privacy_ar.html
│   ├── privacy_fr.html
│   ├── Logo.jpg
│   ├── mockup_home.png, mockup_favorites.png, mockup_settings.png
│   └── mockup_home.jpeg, mockup_favorites.jpeg, mockup_settings.jpeg
├── .github/workflows/deploy-site.yml    ← publie site/ uniquement
├── lib/, android/, ios/, assets/, docs/, test/ …   ← inchangés, NON publiés
Pages (après réglage manuel, §12) : Source = « GitHub Actions »
        ⇒ /allahomairhamabi/ = contenu de site/, servi tel quel (pas de Jekyll)
```

La structure de `site/` est **plate**, comme la racine d'avant. Les chemins relatifs du site restent donc valides sans aucune modification.

---

## 4. Fichiers déplacés

Déplacés avec `git mv` : historique conservé, renommages **placés dans l'index Git mais pas commités**. Contenu vérifié identique par **SHA-256, 10/10**.

| Avant | Après | Justification |
|---|---|---|
| `index.html` | `site/index.html` | Page d'accueil du site |
| `privacy_ar.html` | `site/privacy_ar.html` | Politique AR (URL déclarée sur Google Play) |
| `privacy_fr.html` | `site/privacy_fr.html` | Politique FR |
| `Logo.jpg` | `site/Logo.jpg` | Utilisé par les 3 pages. Aucune référence hors site. |
| `mockup_home.png`, `mockup_favorites.png`, `mockup_settings.png` | `site/…` | Utilisés par `index.html`. Aucune référence hors site. |
| `mockup_home.jpeg`, `mockup_favorites.jpeg`, `mockup_settings.jpeg` | `site/…` | **Non référencés**, mais publics aujourd'hui (URL en 200) et exclusivement liés au site. Déplacés pour **préserver leurs URL** plutôt que les dépublier implicitement ; leur suppression éventuelle relève du LOT 68-B. |

**Non déplacés** (conformément au périmètre) : `docs/`, `lib/`, `android/`, `ios/`, `test/`, `assets/`, `web/`, `pubspec.yaml`, `README.md`.

---

## 5. Fichiers modifiés et ajoutés

| Fichier | Type | Changement |
|---|---|---|
| `test/privacy_policy_content_test.dart` | Modifié (test uniquement) | 3 chemins de lecture : `privacy_ar.html` → `site/privacy_ar.html`, `privacy_fr.html` → `site/privacy_fr.html`, `index.html` → `site/index.html` ; plus 2 lignes de commentaire d'en-tête. **Aucune assertion modifiée** : les 13 tests vérifient exactement les mêmes propriétés. |
| `.github/workflows/deploy-site.yml` | Ajouté | Workflow de publication (§6) |
| `docs/LOT68_B01_MIGRATION_SITE.md` | Ajouté | Ce rapport |

**Fichiers Flutter fonctionnels modifiés : NONE.** (`lib/`, `android/`, `ios/`, `assets/` et `pubspec.yaml` sont intacts.)

**Contenu du site modifié : NONE** (aucun octet des fichiers de `site/`).

---

## 6. Workflow GitHub Pages

Fichier : `.github/workflows/deploy-site.yml`

| Élément | Valeur | Raison |
|---|---|---|
| Déclencheurs | `push` sur **`main`**, filtré sur `site/**` et le workflow lui-même ; `workflow_dispatch` (manuel) | `main` est la branche publiée. Un push qui ne touche que l'app ne redéploie pas le site. |
| Permissions | `contents: read`, `pages: write`, `id-token: write` | Minimum requis par `deploy-pages` |
| Concurrence | groupe `pages`, sans annulation en cours | Pas de déploiement concurrent |
| Environnement | `github-pages` | Environnement standard de Pages |
| Étapes | `actions/checkout@v7` → `actions/configure-pages@v6` → `actions/upload-pages-artifact@v5` (**`path: site`**) → `actions/deploy-pages@v5` | Actions officielles, dernières versions majeures (vérifiées via l'API GitHub le 25/09/2026) |
| Build | **Aucun** : pas de Node, Ruby, Jekyll ni générateur | Site HTML statique |
| Garde-fou | Seul `site/` est empaqueté. `upload-pages-artifact` exclut aussi les fichiers cachés par défaut (`include-hidden-files: false`). | La racine du repo n'est jamais publiée |

Validation : YAML parsé avec succès (paquet Dart `yaml` du projet). Déclencheurs, permissions, environnement et étapes relus.

Effet de bord positif : le déploiement par artefact **n'utilise plus Jekyll**. Les `.md` ne sont plus rendus en HTML et le site est servi exactement tel qu'il est dans `site/`.

---

## 7. URL publiques préservées

Vérification locale : une copie de `site/` a été servie sous `/allahomairhamabi/` (simulation de l'artefact Pages), puis comparée à la production.

| URL | Local (`site/`) | Production | Identique ? |
|---|---|---|---|
| `/allahomairhamabi/` | 200 | 200 | ✅ (voir la note sur les fins de ligne) |
| `/allahomairhamabi/index.html` | 200 | 200 | ✅ (idem) |
| `/allahomairhamabi/privacy_ar.html` | 200 | 200 | ✅ octet pour octet |
| `/allahomairhamabi/privacy_fr.html` | 200 | 200 | ✅ octet pour octet |
| `Logo.jpg`, 3 × `mockup_*.png`, 3 × `mockup_*.jpeg` | 200 | 200 | ✅ octet pour octet (7/7) |
| `pattern.png` (référencé par `privacy_ar.html`) | 404 | 404 | ✅ même état (**anomalie préexistante**, non corrigée ici) |

**Note sur les fins de ligne :** `index.html` diffère dans la copie de travail Windows uniquement par ses fins de ligne CRLF (`core.autocrlf=true`). Le **blob Git** de `site/index.html` (celui que le workflow publiera depuis un checkout Linux) a le **même SHA-256 que la production** (`ac5f10c3…`). Il n'y a donc aucune différence de contenu.

Rendu navigateur, local contre production :
- même titre, `lang="ar"`, `dir="rtl"` ;
- même texte (1 055 caractères) ;
- 4/4 images chargées aux mêmes dimensions ;
- captures d'écran visuellement identiques ;
- le lien « اضغط هنا لقراءة سياسة الخصوصية » ouvre bien `privacy_ar.html` (logo chargé) ;
- `privacy_fr.html` : OK, logo chargé.

Ce qui reste inchangé :
- les URL `https://rahmaapps.github.io/allahomairhamabi/`, `…/privacy_ar.html` et `…/privacy_fr.html` : même repo, même project site, mêmes noms de fichiers ;
- aucun `CNAME`, aucune redirection introduite ;
- la redirection automatique sans slash → avec slash reste gérée par Pages.

---

## 8. Privacy Policy

- `site/privacy_ar.html` et `site/privacy_fr.html` sont **identiques octet pour octet** aux fichiers d'avant **et** à la production.
- L'URL déclarée sur Google Play (`…/allahomairhamabi/privacy_ar.html`) reste valide après déploiement.
- Le test `privacy_policy_content_test.dart` : **13/13 OK** avec les nouveaux chemins.
- Aucune modification du texte des politiques.

---

## 9. app-ads.txt

| Point | Constat |
|---|---|
| Repo `rahmaapps/rahmaapps.github.io` | **Non touché** (aucune action sur ce repo dans ce LOT) |
| `https://rahmaapps.github.io/app-ads.txt` (URL lue par AdMob) | Servi par le **user site**, indépendant du project site `/allahomairhamabi/` ; la migration ne l'affecte pas |
| Copie projet (`/allahomairhamabi/app-ads.txt`) | Existe **uniquement** sur `github-app/main` (`6c09043`), pas sur `github-migration`, donc **absente de `site/`**. **Non ajoutée** dans ce LOT : ce serait une création de fichier hors périmètre. |

**Conséquence à connaître :** après la bascule vers le déploiement par Actions, `https://rahmaapps.github.io/allahomairhamabi/app-ads.txt` passera de 200 à **404**, même après merge, puisque le fichier resterait à la racine du repo et non dans `site/`. D'après l'analyse 68-B.0 §E, **AdMob ne lit pas cette copie** (site développeur = `rahmaapps.github.io`). Il reste une **décision à prendre** avant publication : ajouter `site/app-ads.txt` (copie identique) pour une rupture zéro, ou accepter le 404 (voir §12).

---

## 10. Tests exécutés

| Commande | Avant migration (baseline) | Après migration |
|---|---|---|
| `flutter test test/privacy_policy_content_test.dart` | — | ✅ **13/13 passent** |
| `flutter test` (suite complète) | 358 ✅ / 1 ❌ | 358 ✅ / 1 ❌ (**identique**) |
| `flutter analyze` | 11 issues (11 `info`, 0 warning, 0 error) | 11 issues, **liste identique** (diff vide) |

Seul échec, **préexistant, connu et non modifié** : `test/settings_screen_lot3g_test.dart`, test « LOT 3.G — WorkManagerService.initialDelayForNextFriday autre jour avant vendredi (lundi) → vendredi de la même semaine ». Il échoue à l'identique avant et après la migration (écart d'une heure lié au fuseau local, déjà documenté dans `docs/V1.2_PROGRESS.md`).

Autres vérifications :
- recherche de références aux anciens chemins : `lib/` → aucune ; `test/` → uniquement les 3 lectures adaptées. `docs/` → mentions **historiques** par nom de fichier (`docs/V1.2_PROGRESS.md`, `docs/monetisation/ETAT_LOTS_5.md`) et rapports LOT 68, laissées en l'état (ce sont des journaux, pas des chemins exécutés) ;
- les liens internes du site sont tous relatifs et plats (`Logo.jpg`, `mockup_*.png`, `privacy_ar.html`), donc aucun lien cassé dans `site/` ;
- la référence Flutter `lib/settings_screen.dart:327` utilise toujours exactement `https://rahmaapps.github.io/allahomairhamabi/`, **non modifiée** ;
- aucun secret introduit : le workflow n'utilise que le `GITHUB_TOKEN` implicite ; aucun fichier de configuration sensible n'est ajouté.

---

## 11. Résultats

| Critère de validation | Résultat |
|---|---|
| Site isolé dans `site/` | ✅ |
| GitHub Actions préparé | ✅ `.github/workflows/deploy-site.yml` |
| Pages prévu pour publier uniquement `site/` | ✅ côté repo. ⏳ réglage manuel requis (§12). |
| URL publiques inchangées | ✅ (vérifiées en simulation locale) |
| Privacy Policy fonctionnelle | ✅ |
| Test Privacy Policy | ✅ 13/13 |
| Aucun fichier Flutter fonctionnel modifié | ✅ NONE |
| `app-ads.txt` du repo séparé intact | ✅ |
| Aucun contenu ou design du site modifié | ✅ (SHA-256 identiques) |
| Aucun secret introduit | ✅ |
| `flutter analyze` sans régression | ✅ |
| Tests sans régression | ✅ |
| Aucun commit | ✅ |
| Aucun push | ✅ |

---

## 12. Points nécessitant une action manuelle GitHub

> ⚠️ **L'ordre est critique.** Si le code migré arrive sur `main` **alors que Pages est encore en mode « Deploy from a branch / root »**, Jekyll publiera une racine **sans `index.html` ni `privacy_ar.html`**. La page d'accueil et **la politique déclarée à Google Play renverraient 404**, et toute la doc interne de `docs/` serait publiée.

Séquence proposée (à valider en revue ; rien n'a été fait) :

1. **Revue et commit** de cette migration sur `github-migration`.
2. **Décision `app-ads.txt` projet** (§9) : ajouter `site/app-ads.txt` ou accepter le 404.
3. **Settings → Pages → Build and deployment → Source = « GitHub Actions »** sur `rahmaapps/allahomairhamabi`. D'après la documentation GitHub, le dernier déploiement reste servi jusqu'au prochain déploiement. À vérifier aussitôt : `…/allahomairhamabi/` doit toujours répondre 200.
4. **Vérifier l'environnement `github-pages`** (*Settings → Environments*) : la règle de branches de déploiement doit autoriser `main`, ce qui est le cas par défaut pour la branche par défaut.
5. **Réconcilier `main` avec `github-migration` par merge** (jamais par reset ou force-push), puis **pousser `main`**. Le push touche `site/**` et déclenche donc le workflow. Sinon, le lancer à la main : *Actions → Deploy site to GitHub Pages → Run workflow* (visible une fois le fichier présent sur `main`).
6. **Vérifications post-déploiement :**
   - `https://rahmaapps.github.io/allahomairhamabi/` → 200, même rendu ;
   - `…/privacy_ar.html` et `…/privacy_fr.html` → 200 ;
   - `…/allahomairhamabi/lib/main.dart`, `…/pubspec.yaml` et `…/docs/V1.2_PROGRESS.md` → **404** (preuve que seul `site/` est publié) ;
   - `https://rahmaapps.github.io/app-ads.txt` → 200, contenu inchangé ;
   - « عن التطبيق » depuis l'app.
7. **Rollback** si besoin : repasser *Source* à « Deploy from a branch » **et** revenir au commit précédant la migration sur `main` (les deux ensemble, sinon la racine n'a plus d'`index.html`).

---

## 13. Risques résiduels

| Risque | Niveau | Mitigation |
|---|---|---|
| Push sur `main` avant la bascule de source Pages, donc 404 sur l'accueil et la politique Google Play, et publication de la doc interne | **Élevé si l'ordre n'est pas respecté** | Suivre l'ordre du §12 : source = Actions **avant** le push |
| Fenêtre de propagation CDN (`max-age=600`) après déploiement | Faible | Revérifier les URL après ~10 min |
| 404 sur `/allahomairhamabi/app-ads.txt` | Faible (AdMob lit la racine du domaine) | Décision au §9 ; contrôler le statut AdMob après bascule |
| Divergence `main` / `github-migration` (2 commits propres à `main`) | Moyen | Merge sans reset ; `app-ads.txt` racine et politiques identiques, sans conflit attendu |
| Le repo applicatif reste public sur github.com | Connu, hors périmètre | Voir l'option C de 68-B.0 si c'est un objectif |
| Comportement de la « Source = GitHub Actions » sans déploiement préalable | Faible | Vérification immédiate de l'étape 3 ; `workflow_dispatch` disponible |
| `pattern.png` absent (404 avant et après) | Cosmétique, préexistant | LOT 68-B |
| Échec `settings_screen_lot3g_test.dart` | Préexistant | Hors périmètre |

---

## 14. Conclusion

La séparation technique est prête localement :
- le site vit dans `site/`, avec un contenu identique octet pour octet dans Git ;
- un workflow minimal publiera **uniquement** ce dossier ;
- le seul changement côté Flutter est le chemin de lecture du test des politiques, qui garde les mêmes 13 assertions ;
- tests et analyse sont strictement identiques à la baseline.

La mise en service dépend de **deux actions manuelles** : bascule de la source Pages vers « GitHub Actions », puis merge et push sur `main`, **dans cet ordre**. Elle dépend aussi d'une décision sur la copie projet d'`app-ads.txt`.

**Rien n'est commité ni poussé.** Revue attendue avant le LOT 68-B.1.
