# LOT 68-B.0 — Architecture et stratégie de publication GitHub Pages

> **Nature :** rapport d'analyse **read-only**. Aucun fichier existant n'a été modifié. Aucun merge, reset, commit ou push, aucun changement de branche, aucun changement de Pages ou de workflow.
> **Date :** 25 septembre 2026
> **Baseline locale :** `github-migration` @ `e8e27a415d666a4952e70ccf83e3acaae883534f`
> **Précédent :** [LOT68_AUDIT_SITE.md](LOT68_AUDIT_SITE.md) (LOT 68-A)
> **Méthode :**
> - `git ls-remote` (état distant réel, **sans `fetch`**, pour ne pas toucher aux refs locales) ;
> - `git diff` et `git log` entre refs ;
> - API GitHub publique ;
> - clone read-only de `rahmaapps.github.io` **dans un dossier temporaire hors projet** ;
> - sondage HTTP de 57 fichiers représentatifs du site publié ;
> - lecture de la fiche Google Play publique.

---

## A. Situation actuelle

En une phrase : **le site vitrine, les politiques de confidentialité et tout le code source de l'application sont publiés ensemble par GitHub Pages depuis la racine de la branche `main` du repo applicatif `rahmaapps/allahomairhamabi`**. En parallèle, un second repo (`rahmaapps/rahmaapps.github.io`) sert le vrai `app-ads.txt` lu par AdMob.

Quatre faits nouveaux par rapport au LOT 68-A, qui changent l'analyse :

1. **La fiche Google Play déclare deux URL** (source : page publique de la fiche) :
   - site du développeur : `https://rahmaapps.github.io/`, donc AdMob lit `https://rahmaapps.github.io/app-ads.txt` ;
   - politique de confidentialité : `https://rahmaapps.github.io/allahomairhamabi/privacy_ar.html`.
   Deux URL sont donc **critiques**, pas une seule : la page d'accueil du site (lien « عن التطبيق » dans l'app) **et** `privacy_ar.html` (déclarée à Google Play).
2. **Un test Flutter lit les fichiers du site à la racine du repo** : `test/privacy_policy_content_test.dart` lit `privacy_ar.html`, `privacy_fr.html` et `index.html`, et vérifie que `index.html` contient `href="privacy_ar.html"`. Déplacer ou modifier le site a donc un impact sur la suite de tests de l'app (pas sur le code `lib/`).
3. **La branche publiée `main` contient le code de l'app tel qu'il était le 28/08/2026.** Toute la monétisation (LOTs 5.x), le Design System et le LOT 67 n'y sont pas. Les deux seuls commits postérieurs sur `main` touchent `app-ads.txt` et les politiques.
4. **Un rapport de build Gradle est versionné et publié** : `android/build/reports/problems/problems-report.html`, 147 Ko, suivi depuis `78a5320` (14/02/2026). Il ne contient aucun chemin local (vérifié), mais c'est un artefact de build qui n'a rien à faire dans le repo.

---

## B. Repositories et branches

### B.1 Compte GitHub

`rahmaapps` est un compte **User** (pas une organisation), créé le 19/02/2026, avec **2 repos publics** au total.

### B.2 Repository application : `rahmaapps/allahomairhamabi`

| Élément | Valeur |
|---|---|
| Visibilité | Public |
| Branche par défaut | `main` |
| Pages | Activé (`has_pages: true`) |
| Remote local `github-app` | `https://github.com/rahmaapps/allahomairhamabi.git` |
| Remote local `origin` | `https://gitlab.com/rahmaapps/rahmaapps.git` (GitLab ; `ls-remote` a renvoyé **HTTP 503** pendant l'audit ; refs locales `origin/main` = `origin/master` = `1eb5247`, 18/06/2026, donc obsolètes) |

Branches distantes (`git ls-remote github-app`, état réel) :

| Branche distante | Commit | Date | Remarque |
|---|---|---|---|
| `main` (**publiée par Pages**) | `5760ca9` | 23/09/2026 | Ref locale `github-app/main` à jour |
| `github-migration` | `c6f9a3c` | 14/09/2026 | La branche locale a **13 commits non poussés** en avance (`52ae924` … `e8e27a4`) |
| `sync/notification-migration-20260913` | `4b1b47e` | 13/09/2026 | Branche de travail ancienne |

Branches locales : `github-migration` (`e8e27a4`, courante) et `master` (`54462e9`, 28/08/2026, ancienne).

### B.3 Repository « site utilisateur » : `rahmaapps/rahmaapps.github.io`

| Élément | Valeur |
|---|---|
| Visibilité | Public, Pages activé, branche `main` |
| Contenu (intégral) | `README.md` (« Rahma Apps developer site ») + `app-ads.txt` |
| Historique | 3 commits, tous le 20/09/2026, via l'interface web : `ac70f6f Initial commit`, `bc4122b Create app-ads.txt`, `6a12b34 Update app-ads.txt` |
| Build | Jekyll par défaut (thème GitHub ; `README.md` rendu comme page d'accueil de `https://rahmaapps.github.io/`) |
| Rôle | Sert **l'`app-ads.txt` lu par AdMob** et la page « site du développeur » déclarée sur Google Play |

### B.4 Relations

```
Google Play (fiche com.joumane.allahomairhamabi)
 ├─ Site développeur ───────► https://rahmaapps.github.io/ ◄── repo rahmaapps.github.io (main, /)
 │                                   └─ /app-ads.txt  ◄── lu par AdMob (vérification vendeur)
 └─ Politique confidentialité ► https://rahmaapps.github.io/allahomairhamabi/privacy_ar.html
                                     ▲
App Flutter « عن التطبيق » ─────────► https://rahmaapps.github.io/allahomairhamabi/
                                     │
                         repo allahomairhamabi (main, /)  ── Pages projet, Jekyll
                           ├─ index.html, privacy_ar.html, privacy_fr.html, Logo.jpg, mockup_*
                           ├─ app-ads.txt   (copie, non lue par AdMob)
                           └─ tout le code Flutter + docs/  (publiés aussi)
```

---

## C. Architecture GitHub Pages actuelle

| Élément | Constat | Source |
|---|---|---|
| Type | **Project site** du repo `allahomairhamabi` sous le **user site** `rahmaapps.github.io` | API, URL |
| Branche | `main` | API (`default_branch`), `Last-Modified` cohérent avec `5760ca9` |
| Dossier publié | **`/` (racine)** | Déduit : `index.html` et tous les fichiers de la racine sont servis à `/allahomairhamabi/<chemin>`. L'endpoint API `/pages` exige une authentification (404 en anonyme), donc à confirmer dans *Settings → Pages*. |
| Méthode de build | « Deploy from a branch » + **Jekyll** (workflow dynamique `pages-build-deployment`, créé le 19/02/2026) | API `actions/workflows` |
| Workflows versionnés | Aucun (pas de dossier `.github/`) | Arbre `main` |
| `.nojekyll` / `_config.yml` | Absents, donc Jekyll traite le repo avec ses règles par défaut | Arbre `main` |
| `CNAME` / domaine perso | Aucun | Arbre `main`, URL |
| HTTPS | Actif. `http://` renvoie un 301 vers `https://`. | `curl` |
| Effets Jekyll observés | Les dotfiles sont **exclus** (`.gitignore` et `.metadata` en 404). Les `.md` sont servis bruts **et** rendus en `.html` (ex. `docs/V1.2_PROGRESS.html` → 200). | `curl` |

---

## D. Fichiers publiquement accessibles

Méthode : pour chaque entrée de premier niveau de l'arbre `main` (233 fichiers), jusqu'à 6 fichiers représentatifs (un par extension) ont été demandés en HTTP. Résultat : **57 fichiers testés, tous les fichiers non-dotfiles répondent 200.** L'exposition est **totale**, sauf pour les fichiers commençant par un point.

| Élément | Fichiers sur `main` | Accessible publiquement ? (vérifié) | Nécessaire au site ? | Recommandation |
|---|---|---|---|---|
| `index.html` | 1 | ✅ 200 | **Oui** | Conserver à la même URL |
| `privacy_ar.html` | 1 | ✅ 200 | **Oui (URL déclarée sur Google Play)** | Conserver **exactement** ce chemin |
| `privacy_fr.html` | 1 | ✅ 200 | Oui | Conserver le chemin |
| `Logo.jpg`, `mockup_*.png` | 4 | ✅ 200 | Oui aujourd'hui (remplacés en 68-B) | À remplacer par des assets du site |
| `mockup_*.jpeg` | 3 | ✅ 200 | Non (non référencés) | Ne pas publier |
| `app-ads.txt` (projet) | 1 | ✅ 200 (`/allahomairhamabi/app-ads.txt`) | Non. AdMob lit celui de la racine du domaine (voir E). | Inoffensif. À conserver ou retirer **sur décision explicite**. |
| `README.md` | 1 | ✅ 200 (brut) | Non | Ne pas publier |
| `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` | 3 | ✅ 200 | Non | Ne pas publier |
| `lib/` (code Dart) | 19 sur `main` | ✅ 200 (ex. `lib/dua_personalizer.dart`) | Non | Ne pas publier |
| `test/` | 7 | ✅ 200 | Non | Ne pas publier |
| `assets/` : `duas.json` (578 Ko, catalogue complet des douʿās), polices, icône | 10 | ✅ 200 | Non. L'icône HD pourrait servir, mais via une copie propre. | Ne pas publier (le catalogue entier est aspirable en une requête) |
| `docs/` (`V1.2_PROGRESS.md` + rendu `.html`, `duas_pre_v1.2_backup.json`, manifest d'IDs, `premium_previews/*.png`) | 21 | ✅ 200 | Non (documentation interne) | Ne pas publier |
| `android/` (Gradle, manifestes, Kotlin, ressources) | 56 | ✅ 200 | Non | Ne pas publier |
| `android/build/reports/problems/problems-report.html` | 1 | ✅ 200 (147 Ko) | Non. **Artefact de build versionné.** | Ne pas publier. À désindexer de Git (décision séparée). |
| `ios/`, `macos/`, `linux/`, `windows/` | 40 / 28 / 10 / 18 | ✅ 200 | Non | Ne pas publier |
| `web/` (`index.html` Flutter web, `manifest.json`, `favicon.png`) | 7 | ✅ 200 (`/allahomairhamabi/web/` est une coquille Flutter web non fonctionnelle) | Non | Ne pas publier |
| Dotfiles (`.gitignore`, `.metadata`, `*/.gitignore`) | ~8 | ❌ 404 (exclus par Jekyll) | Non | — |

**Constat sur la sécurité :** aucun secret dans l'arbre publié (`key.properties`, `local.properties`, `*.jks` et `google-services.json` sont absents et ignorés par `.gitignore`). Le repo étant public, ce contenu est **déjà** lisible sur github.com. Pages ajoute une **deuxième surface indexable**, sous l'URL officielle de l'app.

**Risque futur (important) :** la branche locale `github-migration` contient aujourd'hui `docs/monetisation/`, `docs/ui_ux/`, `docs/LOT67_BACKLOG.md`, les rapports LOT 68, etc. **Si elle est fusionnée dans `main` avec l'architecture actuelle, toute cette documentation interne sera automatiquement publiée** sous `https://rahmaapps.github.io/allahomairhamabi/docs/…`.

---

## E. Situation `app-ads.txt`

| Question | Réponse vérifiée |
|---|---|
| Où se trouve-t-il ? | **Deux copies identiques octet pour octet** (59 octets, LF final) : ① repo `rahmaapps.github.io`, branche `main`, racine ; ② repo `allahomairhamabi`, branche `main` uniquement (`6c09043`, 20/09/2026), racine |
| URL publiques | ① `https://rahmaapps.github.io/app-ads.txt` → **200** `text/plain` ; ② `https://rahmaapps.github.io/allahomairhamabi/app-ads.txt` → **200** `text/plain` |
| Contenu | `google.com, pub-2998944710358464, DIRECT, f08c47fec0942fa0` |
| Cohérence avec l'app | ✅ L'ID éditeur `pub-2998944710358464` correspond aux identifiants de production de `lib/monetization/ads_config.dart` (App ID `ca-app-pub-2998944710358464~3134659675` et unités `/4992782235`, `/7219490327`, `/7965966915`). `f08c47fec0942fa0` est l'identifiant TAG standard de Google. |
| URL attendue par AdMob | AdMob lit `app-ads.txt` **à la racine du domaine du « site du développeur » déclaré sur Google Play**. Ce site est `https://rahmaapps.github.io/` (constaté sur la fiche publique). L'URL lue est donc **`https://rahmaapps.github.io/app-ads.txt`**, servie par le repo **`rahmaapps.github.io`**. |
| Le site `allahomairhamabi` en dépend-il ? | **Non.** La copie ② n'est pas celle qu'AdMob consulte. Le site vitrine ne la référence nulle part. |
| Présence sur `github-migration` | Absente (locale comme distante) |

**Conclusion pour la refonte :** le fonctionnement AdMob dépend **uniquement** du repo `rahmaapps.github.io`, qui n'est touché par aucune des options ci-dessous, sauf l'option C, qui ajoute des fichiers à ce repo **sans toucher `app-ads.txt`**. La copie ② peut être perdue sans effet AdMob attendu. Il reste recommandé de ne pas la supprimer **implicitement** (voir F) et d'en décider explicitement.

À confirmer par Hamza dans la console AdMob (*Apps → app-ads.txt*) : statut « Vérifié » et URL crawlée.

---

## F. Divergence `github-migration` / `github-app/main`

- **Ancêtre commun :** `5a5edf8` (28/08/2026, « merge: integrate GitHub website history »).
- **Commits uniquement sur `github-app/main` (2) :**

| Commit | Auteur | Fichiers | Équivalent sur `github-migration` ? |
|---|---|---|---|
| `6c09043` 20/09 `chore: add AdMob app-ads.txt` | `contact.rahmaapps@gmail.com` (interface web) | `app-ads.txt` (+1) | ❌ **Aucun** |
| `5760ca9` 23/09 `docs(privacy): publish rewarded ads policy` | `hjoumane@gmail.com` | `privacy_ar.html`, `privacy_fr.html` | ✅ Contenu **identique** à `9aa1919` (local). `git diff github-app/main HEAD -- privacy_*.html` est vide. |

- **Commits uniquement sur `github-migration` locale (42)** : `902c397` (04/09) → `e8e27a4` (24/09). Ils couvrent la refonte UI et le Design System, l'onboarding, GraveVisit, les rappels `zonedSchedule`, la signature release, toute la monétisation (5.A→5.G.B), In-App Review, les politiques (`9aa1919`) et le LOT 67. 13 d'entre eux ne sont **pas encore poussés** sur `github-app/github-migration`.
- **Volume :** `github-app/main` → `HEAD` : 164 fichiers (118 ajoutés, 45 modifiés, **1 supprimé : `app-ads.txt`**), +17 476 / −2 792 lignes.
- **Fichiers du site** (`index.html`, `privacy_*.html`, `Logo.jpg`, `mockup_*`) : **identiques** entre `github-app/main` et `HEAD`.

### Ce qui serait perdu si `github-app/main` était remplacé par `github-migration` (reset ou force-push)

| Élément | Perdu ? | Impact |
|---|---|---|
| `app-ads.txt` du repo projet | **Oui** | Faible : AdMob lit la copie du repo `rahmaapps.github.io` (voir E) |
| Politiques mises à jour | Non (contenu identique déjà sur `github-migration`) | — |
| Site vitrine | Non (identique) | — |
| Historique des 2 commits | Oui (réécriture d'historique sur la branche par défaut publique) | Traçabilité |

Un **merge** (et non un remplacement) de `github-app/main` dans `github-migration`, ou l'inverse, se ferait sans conflit sur ces fichiers : `app-ads.txt` est un ajout pur, et les politiques sont identiques. Ce merge n'a **pas** été effectué.

---

## G. Options d'architecture

> Aucune option n'est choisie ici. Les sous-variantes sont décrites pour montrer l'éventail réel.

### Option A — Garder le site dans le repo Flutter

**A1 — Statu quo + filtrage Jekyll.** Le site reste à la racine de `main`. Un `_config.yml` avec `exclude:` (ou `include:` minimal) empêche Jekyll de publier `lib/`, `android/`, `docs/`, etc.
- ✅ Aucun changement d'URL, de chemin ou de test. Changement minimal.
- ❌ Le site reste mélangé au code (fichiers HTML et images à la racine d'un projet Flutter). Liste d'exclusion à maintenir à chaque nouveau dossier (risque d'oubli, donc de fuite de docs internes). Le repo reste public par nécessité (Pages gratuit = repo public pour un compte User Free).

**A2 — Source Pages = `/docs`.** Le site est déplacé dans `docs/`.
- ✅ Séparation visible dans l'arborescence. URL conservée si les fichiers gardent leurs noms.
- ❌ **Conflit direct** : `docs/` contient déjà la documentation interne du projet (monétisation, UI/UX, backups JSON, rapports LOT), qui serait alors **publiée**. Il faudrait d'abord renommer la doc interne (ex. `project_docs/`), ce qui casse les références croisées existantes (`docs/ui_ux/...` est cité dans le code, par exemple `lib/theme/app_colors.dart`). Le test `privacy_policy_content_test.dart` est à adapter (chemins). Bascule de la source Pages nécessaire.

**A3 — Dossier `site/` + déploiement GitHub Actions.** Le site vit dans `site/`. Un workflow (`actions/upload-pages-artifact` + `actions/deploy-pages`) ne publie **que** ce dossier. La source Pages passe à « GitHub Actions ».
- ✅ Publication strictement limitée au site (plus d'exposition du code via Pages). URL conservée (même repo, donc même project site). Site versionné avec l'app, d'où la possibilité de faire évoluer site et politiques dans le même commit que la fonctionnalité correspondante. Aucun Jekyll implicite.
- ❌ Ajoute un workflow à maintenir. Test à adapter (`site/privacy_ar.html`). Le repo applicatif reste public (Pages Free l'exige). Le déploiement dépend de la branche choisie dans le workflow, donc la divergence `main`/`github-migration` doit être réglée d'abord.

**Commun à A :** le code source de l'app reste public sur github.com, puisque Pages impose un repo public sur le plan gratuit. **Plan GitHub actuel : non vérifiable anonymement, à confirmer.**

### Option B — Repository dédié au site

**Contrainte technique décisive :** un project site est servi à `https://<owner>.github.io/<NOM_DU_REPO>/`. Pour conserver `/allahomairhamabi/`, le repo du site **doit s'appeler `allahomairhamabi`**, et ce nom est pris par le repo applicatif. Un repo `allahomairhamabi-site` publierait sur `/allahomairhamabi-site/`, **ce qui casse l'URL**.

B nécessite donc : ① renommer le repo applicatif (ex. `allahomairhamabi-app`) ; ② créer un nouveau repo `allahomairhamabi` qui ne contient que le site ; ③ activer Pages sur ce nouveau repo.
- ✅ Séparation parfaite. Repo du site minimal et lisible. Le repo applicatif peut devenir **privé** (plus besoin de Pages dessus), ce qui répond aussi à l'exposition du code sur github.com. Historique du site indépendant.
- ❌ **Risque de migration élevé :**
  - GitHub ne redirige **pas** les URL Pages d'un repo renommé. Entre le renommage et la première publication du nouveau repo, `/allahomairhamabi/` et **`privacy_ar.html` (URL déclarée sur Google Play)** renvoient 404.
  - La redirection automatique des URL git de l'ancien nom **cesse dès qu'un nouveau repo reprend ce nom**. Le remote `github-app` doit donc être mis à jour, de même que toute intégration qui pointe vers l'ancien nom.
  - Les issues et releases éventuelles restent sur le repo renommé.
  - Deux repos à synchroniser : les politiques décrivent le comportement de l'app, mais ne vivent plus avec son code.
  - Le test `privacy_policy_content_test.dart` ne peut plus lire les fichiers localement : il faut le réécrire, le déplacer ou le supprimer (décision).
- `app-ads.txt` : non concerné (repo `rahmaapps.github.io`).

### Option C — Héberger le site dans le user site `rahmaapps.github.io`

Le repo `rahmaapps.github.io` (qui porte déjà `app-ads.txt` et le « site développeur » déclaré sur Google Play) reçoit un dossier `allahomairhamabi/` contenant le site. Pages est ensuite **désactivé** sur le repo applicatif. L'URL `https://rahmaapps.github.io/allahomairhamabi/` est alors servie par le user site, et le **chemin reste identique**.
- ✅ Un seul repo « web » pour Rahma Apps : page développeur à la racine, `app-ads.txt`, et un sous-dossier par application. C'est cohérent avec la fiche Play (site développeur = `rahmaapps.github.io`) et extensible à de futures apps sans nouveau repo.
- ✅ Aucun renommage. Pas de trou de nom de repo.
- ✅ Le repo applicatif n'a plus besoin de Pages, donc il **peut** devenir privé (décision séparée).
- ✅ Bascule à faible interruption : le dossier peut être préparé à l'avance dans `rahmaapps.github.io`, puis Pages désactivé sur le repo applicatif (voir la réserve de précédence ci-dessous).
- ❌ **Point à vérifier avant d'engager :** tant que le project site `allahomairhamabi` est actif, il a **priorité** sur un dossier du même nom dans le user site (comportement documenté par GitHub pour les project sites, **non testé ici**). La bascule est effective au moment où Pages est désactivé sur le repo applicatif. Il faut vérifier juste après que `index.html`, `privacy_ar.html` et `privacy_fr.html` répondent bien. Le délai de propagation (CDN, `max-age=600`) implique jusqu'à ~10 min d'état intermédiaire possible.
- ❌ Le user site utilise Jekyll avec un thème par défaut. Un `.nojekyll` ou un `_config.yml` sera nécessaire pour que le dossier soit servi tel quel, à décider avec précaution pour **ne pas altérer `app-ads.txt` ni la page racine**.
- ❌ Comme pour B : politiques séparées du code de l'app, test `privacy_policy_content_test.dart` à réécrire ou relocaliser.
- ❌ Les modifications futures du site touchent le repo qui porte `app-ads.txt` : il faut une discipline de revue, voire une protection de ce fichier.

### Option A3 bis *(variante de A3 à signaler)*

A3 peut aussi publier `site/` depuis une **branche dédiée** (`gh-pages`) alimentée par le workflow. C'est plus ancien et moins propre qu'un déploiement direct par artefact : cette variante est mentionnée pour mémoire, sans avantage net ici.

---

## H. Comparaison des compromis

> Analyse qualitative. **Aucun score ni classement.**

| Critère (importance) | A1 statu quo + `exclude` | A2 `/docs` | A3 `site/` + Actions | B repo dédié renommé | C user site `rahmaapps.github.io` |
|---|---|---|---|---|---|
| **Conservation URL** (CRITIQUE) | Garantie, rien ne bouge | Garantie si les noms de fichiers sont conservés | Garantie (même project site) | Interruption pendant la bascule ; dépend d'un renommage | Garantie en régime établi ; bascule par désactivation de Pages, à vérifier (précédence) |
| **Impact app Flutter** (CRITIQUE) | Aucun | Aucun sur `lib/`. Test à adapter, doc interne à déplacer. | Aucun sur `lib/`. Test à adapter (chemin). | Aucun sur `lib/`. Test à réécrire ou relocaliser. | Aucun sur `lib/`. Test à réécrire ou relocaliser. |
| **Impact AdMob / `app-ads.txt`** (CRITIQUE) | Aucun | Aucun | Aucun | Aucun | Aucun si `app-ads.txt` et la racine ne sont pas modifiés ; **repo sensible touché** |
| Séparation du site (HAUTE) | Faible (mélange à la racine) | Moyenne, avec conflit avec la doc interne | Bonne (dossier dédié, seul publié) | Excellente | Excellente (site hors du repo app) |
| Maintenance (HAUTE) | Liste `exclude` à tenir à jour | Réorganisation de `docs/` | 1 workflow + 1 dossier | 2 repos, remote à changer | 2 repos, dont un « web » partagé |
| Déploiement (HAUTE) | Inchangé (push sur `main`) | Push sur `main` | Push, puis workflow | Push sur le repo du site | Push sur `rahmaapps.github.io` |
| Fiabilité Pages (HAUTE) | Jekyll implicite, dépend de la liste | Jekyll implicite | Artefact explicite, sans Jekyll | Simple | Simple, avec Jekyll du user site à maîtriser |
| SEO (MOYENNE) | Code encore indexable si l'exclusion est incomplète | Risque de publier la doc interne | Seul le site est indexable | Seul le site est indexable | Seul le site est indexable, plus page développeur à la racine |
| Évolutivité (HAUTE) | Limitée | Moyenne | Bonne, liée au cycle de l'app | Bonne | Bonne, multi-apps |
| **Risque de migration** (HAUTE) | Très faible | Moyen (déplacement de docs) | Faible à moyen (bascule de source Pages, dépend de la branche) | **Élevé** (renommage, trou d'URL, remote) | Moyen (précédence et bascule à vérifier, repo `app-ads` touché) |
| Code de l'app rendu privé possible | Non (Pages Free) | Non | Non | Oui | Oui |
| Dépendance à la divergence `main`/`github-migration` | Forte (publie `main`) | Forte | Forte (branche déployée) | Faible (le site sort du repo app) | Faible (le site sort du repo app) |

---

## I. Conservation de l'URL

Comportement actuel vérifié :

| Requête | Résultat |
|---|---|
| `https://rahmaapps.github.io/allahomairhamabi` (sans slash) | **301** → `…/allahomairhamabi/` (redirection automatique de Pages) |
| `https://rahmaapps.github.io/allahomairhamabi/` | 200 (`index.html`) |
| `…/allahomairhamabi/index.html` | 200 |
| `http://…/allahomairhamabi/` | 301 → HTTPS |
| `…/ALLAHOMAIRHAMABI/` | 404 (sensible à la casse) |
| `…/allahomairhamabi/privacy_ar.html` / `privacy_fr.html` | 200 |

Conditions pour conserver l'URL, quelle que soit l'option :

1. **Chemin `/allahomairhamabi/`** : il faut soit un project site dont le repo s'appelle exactement `allahomairhamabi` (A, B), soit un dossier `allahomairhamabi/` dans le user site sans project site concurrent (C). La casse compte.
2. **Pas de `CNAME`** : aucun domaine perso aujourd'hui. En ajouter un redirigerait `rahmaapps.github.io/...` vers le nouveau domaine, ce qui est hors périmètre et ne doit pas être fait implicitement. Dans l'option C, un `CNAME` sur le user site s'appliquerait à **tout** le domaine, `app-ads.txt` compris.
3. **Fichiers à la racine du site** : `index.html`, **`privacy_ar.html`** (URL Google Play) et `privacy_fr.html` doivent garder exactement ces noms et cet emplacement. Un éventuel renommage (ex. `/privacy/ar/`) devra laisser une page à l'ancien chemin. GitHub Pages ne gère pas les redirections serveur : il faudrait une page HTML `meta refresh` + canonical.
4. **Liens relatifs** : le site actuel n'utilise que des liens relatifs (`Logo.jpg`, `privacy_ar.html`). Il faut les conserver (pas de `/…` absolu, qui pointerait vers la racine du **user site**).
5. **Assets** : même règle, chemins relatifs sous `/allahomairhamabi/`.
6. **Routing** : site statique sans routeur. Aucune SPA, donc aucun besoin de 404 de repli.
7. **Trailing slash** : le 301 automatique existe déjà, mais le lien de l'app utilise déjà le slash final (bon).

---

## J. Impact sur l'application Flutter

Recherche exhaustive dans `lib/`, `android/app/src`, `ios/Runner`, `web/`, `test/` et `pubspec.yaml` :

| Référence | Emplacement | Nature |
|---|---|---|
| `https://rahmaapps.github.io/allahomairhamabi/` | `lib/settings_screen.dart:327` | **Codée en dur**, **unique** référence runtime au site (ouverte par « عن التطبيق » via `launchUrl`) |
| même chaîne | `test/privacy_policy_content_test.dart:127` | Le test vérifie que l'URL reste inchangée |
| `privacy_ar.html`, `privacy_fr.html`, `index.html` (lecture de fichier local) | `test/privacy_policy_content_test.dart:21-22, 132` | Le **test lit les fichiers du site à la racine du repo** |
| Lien Google Play | `lib/settings_screen.dart:68` | Pas lié au site |
| Aucune autre référence | `android/`, `ios/`, `web/`, `pubspec.yaml` | — |

L'app n'ouvre ni `privacy_ar.html` ni `privacy_fr.html` directement : la confidentialité in-app passe par le formulaire UMP. La politique n'est atteinte que via la page d'accueil du site et via Google Play.

**Conclusions :**
- **Aucune option ne nécessite de modifier `lib/`** tant que l'URL `…/allahomairhamabi/` est conservée.
- **Les options A2, A3, B et C imposent une modification de `test/privacy_policy_content_test.dart`** (chemins, ou déplacement des assertions « site » vers le repo du site). Seule **A1** laisse la suite de tests intacte. C'est une modification du repo applicatif, **hors code de production**, à valider explicitement.

---

## K. Workflow recommandé pour LOT 68-B

| Étape | Qui | Contenu | Sortie |
|---|---|---|---|
| **1. Architecture validée** | Hamza | Choix A1 / A3 / B / C (section M) ; stratégie Git (F) ; décision sur la copie projet d'`app-ads.txt`, sur `problems-report.html` et sur le test des politiques | Décision écrite |
| **2. Claude Design** | Claude Design | Structure (base : LOT 68-A §K), direction visuelle alignée sur le DS Phase 2, responsive (1920/1366/768/375), présentation des screenshots, RTL, CTA Play, bloc transparence publicité, favicon, image OG | Maquette et specs validées |
| **3. Préparation des captures** | Hamza, avec l'aide de Claude Code | Build à baseline figée, données de démo, demo mode de la barre d'état, aucune publicité visible (LOT 68-A §L) | App prête à capturer |
| **4. Validation des captures** | Hamza + Claude Design | Revue : lisibilité, cohérence, aucune donnée perso, aucune publicité | Jeu de captures final |
| **5. Implémentation** | Claude Code | Site statique selon l'architecture choisie : contenu AR, captures optimisées, SEO et OG, liens (Play, politiques AR et FR, contact), adaptation du test politiques si besoin | Branche ou PR, **non publiée** |
| **6. QA** | Claude Code + Hamza | Liens, console, responsive, Lighthouse, vérification des URL critiques (§I), `app-ads.txt` (§E), « عن التطبيق » depuis l'app, aperçu de partage, `flutter test` vert | Rapport QA |
| **7. Publication** | Hamza (validation) → Claude Code | Déploiement selon l'architecture ; vérification post-déploiement de **`/allahomairhamabi/`, `privacy_ar.html`, `privacy_fr.html` et `rahmaapps.github.io/app-ads.txt`** ; statut AdMob | Site en ligne |

---

## L. Pré-requis avant implémentation

1. **Décision d'architecture** (section M).
2. **Stratégie de réconciliation Git** entre `github-app/main` et `github-migration` : merge ou fast-forward, **jamais de force-push ni de reset** de `main` sans décision explicite. Sort explicite de la copie projet d'`app-ads.txt`. Poussée préalable (ou non) des 13 commits locaux.
3. **Garde-fou contre la publication de la doc interne** : avant tout merge de `github-migration` dans `main`, s'assurer que l'architecture ne publie plus la racine du repo. Sinon, `docs/monetisation/`, `docs/ui_ux/`, les rapports LOT et les backups JSON deviennent publics.
4. **Vérifications côté consoles (Hamza) :**
   - Pages : *Settings → Pages* du repo `allahomairhamabi` (source et dossier exacts) et du repo `rahmaapps.github.io` ;
   - AdMob : statut `app-ads.txt` « Vérifié » ;
   - Play Console : URL de politique et site développeur (confirmer ce qu'on voit sur la fiche publique) ;
   - plan GitHub du compte (Free ou Pro), qui conditionne la possibilité de rendre privé un repo qui publie Pages.
5. **Décision sur `test/privacy_policy_content_test.dart`** : conserver, adapter les chemins ou déplacer les assertions (selon l'option).
6. **Décision sur `android/build/reports/problems/problems-report.html`** : le retirer du suivi Git (artefact de build). À faire hors LOT 68 ou en tâche dédiée.
7. **Validation Claude Design** (LOT 68-A §M) **après** la décision d'architecture, puisque l'architecture conditionne la gestion des assets et des polices (auto-hébergées ou non).
8. **Remote `origin` GitLab** : 503 pendant l'audit, refs locales datées du 18/06/2026. Décider s'il reste une cible de push (hors LOT 68, à noter).

---

## M. Recommandation technique proposée

> **💡 PROPOSITION — À VALIDER PAR HAMZA**
> Ceci n'est **pas** une décision. Aucune action n'a été engagée.

**Proposition principale : Option A3 (dossier `site/` dans le repo applicatif + déploiement GitHub Actions ne publiant que ce dossier).**

Pourquoi, au regard des critères critiques :
- **URL :** même repo, donc même project site, donc `/allahomairhamabi/` et `privacy_ar.html` conservés **sans renommage ni bascule entre repos**.
- **App Flutter :** aucune modification de `lib/`. Seul le chemin lu par `test/privacy_policy_content_test.dart` change (`site/…`), et le test **garde son rôle** de garde-fou entre politiques et comportement réel de l'app, parce que site et code restent dans le même repo et le même commit.
- **AdMob :** aucun contact avec `rahmaapps.github.io`. La copie projet d'`app-ads.txt` peut être conservée dans `site/` à l'identique si on veut une rupture zéro.
- **Exposition :** met fin à la publication de `lib/`, `docs/`, `assets/duas.json`, etc. via Pages, et désamorce le risque « merge = publication de la doc interne ».
- **Limite assumée :** le repo applicatif reste public sur github.com. Si rendre le code privé devient un objectif, **l'option C** est la meilleure alternative : elle est cohérente avec la fiche Play (site développeur = `rahmaapps.github.io`), multi-apps, et sans renommage, au prix d'une bascule à vérifier (précédence project/user site) et d'un test à relocaliser.

**Option à écarter sauf raison forte :** B (renommage de repo, trou d'URL sur la politique déclarée à Google Play, remote à changer).
**A1** reste un repli acceptable à court terme (zéro risque de migration), mais fragile dans la durée (liste d'exclusion).
**A2** est déconseillée tant que `docs/` sert à la documentation interne.

Séquence indicative si A3 est retenue (**à valider**, rien n'est engagé) :
1. Réconcilier `main` et `github-migration` par merge, sans reset, en préservant `app-ads.txt`.
2. Créer `site/` avec **copie à l'identique** du site actuel (`index.html`, `privacy_*.html`, `Logo.jpg`, `mockup_*.png`, `app-ads.txt`).
3. Adapter le test.
4. Ajouter le workflow Pages.
5. Basculer la source Pages sur « GitHub Actions ».
6. Vérifier les URL critiques.
7. Seulement ensuite : LOT 68-B.1 (Claude Design), puis la refonte du contenu dans `site/`.

Cette séquence sépare **changement d'architecture** et **changement de contenu**, afin qu'un éventuel incident soit immédiatement attribuable.

---

## Annexe — Contrôle final

- `git status` : aucun fichier suivi modifié. Nouveaux fichiers non suivis : `docs/LOT68_AUDIT_SITE.md` (LOT 68-A) et `docs/LOT68_B0_ARCHITECTURE_SITE.md` (ce rapport), **non commités**.
- Aucun commit, aucun push, aucun merge, aucun reset, aucun `fetch`.
- Aucun changement GitHub Pages, workflows, branches ou `app-ads.txt`.
- Aucune modification de l'application (`lib/`, `test/`, `android/`, `ios/`…).
- Le clone read-only de `rahmaapps.github.io` a été fait dans le dossier temporaire de session, hors projet.
