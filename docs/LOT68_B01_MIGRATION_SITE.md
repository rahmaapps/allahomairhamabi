# LOT 68-B.0.1 — Migration technique du site GitHub Pages (branche `lot68-b01-pages`)

> **Contexte :** cette branche reproduit **uniquement** la migration technique du site, **directement sur `github-app/main`**, afin qu'une PR vers `main` ne contienne que ce changement. Aucun des 42 commits applicatifs antérieurs de `github-migration` n'est inclus.
> **Branche :** `lot68-b01-pages`, créée depuis `github-app/main` @ `5760ca9dbaba500eb6399103ed946e943348cebf`
> **Migration de référence :** commit `46fb8ff` sur `github-migration` (validé ; rapport d'origine sur cette branche)
> **Date :** 25 septembre 2026

---

## 1. Objectif

Faire publier par GitHub Pages **uniquement** le dossier `site/`, via GitHub Actions. Les URL publiques restent strictement inchangées, et le contenu et le design du site ne changent pas.

---

## 2. Architecture avant (état de `main`)

- Site à la racine du repo : `index.html`, `privacy_ar.html`, `privacy_fr.html`, `Logo.jpg` et 6 `mockup_*`.
- Pages en mode « Deploy from a branch » (`main`, racine) avec Jekyll implicite : **tout le repo** (code Flutter, `docs/`, etc.) est servi sous `/allahomairhamabi/`.

---

## 3. Architecture après

```
site/                                  ← SEUL contenu publié
├── index.html, privacy_ar.html, privacy_fr.html
├── Logo.jpg
└── mockup_home|favorites|settings .png / .jpeg
.github/workflows/deploy-site.yml      ← publie site/ uniquement
app-ads.txt                            ← inchangé, reste à la racine du repo (non publié)
lib/, android/, ios/, assets/, test/, docs/ …   ← inchangés, non publiés
```

Source Pages : **GitHub Actions** (réglage déjà effectué sur le repo, selon Hamza).

---

## 4. Fichiers déplacés (`git mv`, contenu identique à 100 %)

| Avant (`main`) | Après |
|---|---|
| `index.html` | `site/index.html` |
| `privacy_ar.html` | `site/privacy_ar.html` |
| `privacy_fr.html` | `site/privacy_fr.html` |
| `Logo.jpg` | `site/Logo.jpg` |
| `mockup_home.png`, `mockup_favorites.png`, `mockup_settings.png` | `site/…` |
| `mockup_home.jpeg`, `mockup_favorites.jpeg`, `mockup_settings.jpeg` | `site/…` (non référencés, déplacés pour préserver leurs URL actuelles) |

Structure plate conservée : les chemins relatifs du site (`Logo.jpg`, `mockup_*.png`, `privacy_ar.html`) restent valides sans modification.

---

## 5. Fichiers ajoutés

| Fichier | Contenu |
|---|---|
| `.github/workflows/deploy-site.yml` | Workflow validé au LOT 68-B.0.1, **identique octet pour octet** au blob du commit `46fb8ff` |
| `docs/LOT68_B01_MIGRATION_SITE.md` | Ce rapport |

**Aucun fichier modifié** sous `lib/`, `android/`, `ios/`, `assets/`, `test/`, `pubspec.yaml` ou `pubspec.lock`.

---

## 6. Workflow GitHub Pages

- **Déclencheurs :** `push` sur `main` touchant `site/**` ou le workflow, plus `workflow_dispatch`.
- **Permissions :** `contents: read`, `pages: write`, `id-token: write`. Environnement `github-pages`.
- **Étapes :** `actions/checkout@v7` → `actions/configure-pages@v6` → `actions/upload-pages-artifact@v5` avec **`path: site`** → `actions/deploy-pages@v5`.
- **Aucun build :** pas de Jekyll, Node ni générateur. Seul `site/` est empaqueté ; les fichiers cachés sont exclus par défaut.

---

## 7. URL publiques préservées

| URL | Servie après migration par |
|---|---|
| `https://rahmaapps.github.io/allahomairhamabi/` | `site/index.html` |
| `https://rahmaapps.github.io/allahomairhamabi/privacy_ar.html` (URL déclarée sur Google Play) | `site/privacy_ar.html` |
| `https://rahmaapps.github.io/allahomairhamabi/privacy_fr.html` | `site/privacy_fr.html` |

Sur cette baseline, le code de l'app (`lib/settings_screen.dart`, **non modifié**) référence `…/allahomairhamabi/` et `…/allahomairhamabi/privacy_ar.html`. Les deux URL restent valides.

---

## 8. app-ads.txt

- **Non déplacé :** `app-ads.txt` reste à la racine du repo applicatif, inchangé.
- Comme il n'est pas dans `site/`, `https://rahmaapps.github.io/allahomairhamabi/app-ads.txt` **ne sera plus servi** après le premier déploiement par Actions (404).
- L'URL lue par AdMob est **`https://rahmaapps.github.io/app-ads.txt`**. Elle est servie par le repository séparé **`rahmaapps/rahmaapps.github.io`**, qui reste seul responsable de ce fichier, **n'est pas touché** par cette migration et en est indépendant (site utilisateur contre site projet `/allahomairhamabi/`).

---

## 9. Test Privacy Policy

`test/privacy_policy_content_test.dart` **n'est volontairement pas inclus** :
- il n'existe pas sur la baseline `github-app/main` ;
- il dépend de composants applicatifs (`lib/monetization/ads_config.dart`) présents uniquement dans l'historique de `github-migration`.

La version adaptée à `site/` reste sur `github-migration` (commit `46fb8ff`).

Sur cette baseline, **aucun test** ne lit les fichiers du site.

---

## 10. Vérifications effectuées

- 10/10 fichiers de `site/` identiques aux blobs de `github-app/main` (renommages à 100 %).
- Blob du workflow identique à celui de `46fb8ff`.
- `site/index.html` référence toujours `Logo.jpg`, `mockup_home.png`, `mockup_favorites.png`, `mockup_settings.png` et `privacy_ar.html`, tous présents dans `site/`.
- Diff limité à `site/` (10 renommages), au workflow et à ce rapport.
- `git diff --check` : aucune erreur.

---

## 11. Actions manuelles et ordre de mise en service

1. Revue, puis commit sur `lot68-b01-pages`.
2. Push de la branche, puis PR `lot68-b01-pages → main`.
3. Au merge sur `main`, le push touche `site/**` et déclenche `deploy-site.yml`. La source Pages est déjà « GitHub Actions ».
4. Vérifications post-déploiement :
   - `…/allahomairhamabi/`, `privacy_ar.html` et `privacy_fr.html` → 200 ;
   - `…/allahomairhamabi/lib/main.dart` et `…/pubspec.yaml` → 404 ;
   - `https://rahmaapps.github.io/app-ads.txt` → 200, contenu inchangé.

---

## 12. Risques résiduels

| Risque | Mitigation |
|---|---|
| `github-migration` devra plus tard être réconciliée avec `main`, qui contiendra cette migration | Même contenu des deux côtés (`site/` et workflow identiques) ; le test adapté est déjà sur `github-migration` |
| 404 sur `/allahomairhamabi/app-ads.txt` | AdMob lit `https://rahmaapps.github.io/app-ads.txt` (repo séparé) |
| Propagation CDN (~10 min) | Revérifier les URL après déploiement |
| Anomalies de contenu connues (slogan, bouton Play, `pattern.png`, SEO…) | Hors périmètre : LOT 68-B.1 et suivants |

---

## 13. Conclusion

Cette branche contient **uniquement** la migration technique du site : 10 renommages sans changement de contenu, le workflow validé et ce rapport. Elle part directement de `github-app/main` et n'embarque aucun travail applicatif antérieur.
