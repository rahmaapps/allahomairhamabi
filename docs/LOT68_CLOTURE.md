# LOT 68 — Landing page publique : clôture

> **Statut : ✅ CLÔTURÉ / PUBLIÉ** — 26 septembre 2026
> Document de clôture (LOT 68-B.5). Il consolide l'état final du LOT 68 et les résultats du QA de production (68-B.4). Aucune modification du site, de l'application, du workflow, de `app-ads.txt` ni des pages de confidentialité n'est faite par ce lot.

---

## 1. Production

| Élément | Valeur |
|---|---|
| URL publique | https://rahmaapps.github.io/allahomairhamabi/ |
| Commit de production | `4b94279` — *Merge pull request #2 from rahmaapps/lot68-b3b-site* (parents `37550ec` + `da7ba7e`) |
| PR | #2 `lot68-b3b-site` → `main` (mergée le 26/09/2026), commits `65e238d` + `da7ba7e` |
| Branche de travail | `lot68-b3b-site` |
| Base | `main` |
| Déploiement | GitHub Pages — source « GitHub Actions » |
| Workflow | `Deploy site to GitHub Pages` (`.github/workflows/deploy-site.yml`) — exécution sur `4b94279` : succès (26/09/2026 15:45 UTC) |
| Contenu publié | `site/` uniquement |

---

## 2. Statut des sous-lots

| Sous-lot | Statut | Référence |
|---|---|---|
| 68-A — Audit read-only | ✅ Terminé | [`LOT68_AUDIT_SITE.md`](LOT68_AUDIT_SITE.md) |
| 68-B.0 — Architecture | ✅ Validé | [`LOT68_B0_ARCHITECTURE_SITE.md`](LOT68_B0_ARCHITECTURE_SITE.md) — option A3 (`site/` + GitHub Actions) |
| 68-B.0.1 — Migration technique | ✅ Terminé / Production | [`LOT68_B01_MIGRATION_SITE.md`](LOT68_B01_MIGRATION_SITE.md) — PR #1 `lot68-b01-pages` (`3169bbc`) → `main` `37550ec` |
| 68-B.1 — Direction visuelle | ✅ Validé | [`LOT68_B1_VISUAL_DIRECTION.md`](LOT68_B1_VISUAL_DIRECTION.md) |
| 68-B.2 — Captures réelles | ✅ Terminé | [`LOT68_B2_CAPTURE_PROTOCOL.md`](LOT68_B2_CAPTURE_PROTOCOL.md) |
| 68-B.3-A — Design final | ✅ Validé | Prototype Claude Design `Landing.dc.html` + `Landing Spec.dc.html` (hors dépôt) |
| 68-B.3-B — Implémentation | ✅ Terminé | PR #2 — `65e238d` (landing page) + `da7ba7e` (numérotation des étapes en chiffres 0-9) |
| 68-B.4 — QA de production | ✅ QA validé | §4 de ce document |
| 68-B.5 — Clôture | ✅ Clôturé / Publié | Ce document |

---

## 3. Résumé du LOT 68

- **Migration du site vers `site/`** : le site public vit dans `site/` ; GitHub Pages publie uniquement ce dossier via le workflow `Deploy site to GitHub Pages` (source « GitHub Actions »).
- **Séparation du site public et du code Flutter** : le code source (`lib/`, `pubspec.yaml`, `docs/`…) n'est plus servi par GitHub Pages (404 constaté au QA B.4).
- **Nouvelle landing page** : implémentation statique (HTML/CSS, sans JavaScript) du design B.3-A, en 10 sections — En-tête, Hero, لمن تدعو؟, كل يوم, عند زيارة القبر, تذكير, شارك الأجر, بوضوح, CTA Google Play, Footer. Arabe, RTL, thème clair uniquement.
- **Captures réelles B.2** : C1–C6 (1080×2340) intégrées sans modification dans `site/images/` (hashes identiques aux originaux B.2).
- **Share as Image** : les trois exports réels de l'application présentés sous leurs noms exacts **Dark Luxe**, **Emerald**, **White**.
- **Optimisation WebP** : exports convertis en WebP 1200 px sur le grand côté (86–156 Ko au lieu de 8–11 Mo), contenu visuel inchangé.
- **SEO** : `lang="ar"`, `dir="rtl"`, title, meta description, canonical, Open Graph, carte Twitter `summary`, favicon et apple-touch-icon (`Logo.jpg`).
- **Responsive** : mise en page testée à 1440, 834 et 390 px (voir §4).
- **Liens Google Play** : 4 liens vers `https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi`.
- **Privacy AR/FR** : liens relatifs `privacy_ar.html` et `privacy_fr.html` dans le footer ; pages non modifiées par ce lot.
- **Transparence publicitaire** : bloc « بوضوح » reprenant mot pour mot le texte validé (`مجاني، مع إعلانات محدودة.` + 5 points) ; aucune mention « 100% بدون إعلانات » ; aucune publicité sur le site.
- **QA de production** : 68-B.4 réalisé sur l'URL publique — aucun FAIL.

---

## 4. QA de production (68-B.4)

Méthode : requêtes HTTP (`curl`), comparaison d'empreintes (Git/SHA-256), API GitHub, et navigateur réel (Chrome 154 headless piloté par DevTools Protocol, profil isolé, console et réseau enregistrés) sur l'URL publique.

### Résultats — PASS
- Production : HTTP 200, commit `4b94279` déployé ; les 13 fichiers servis sont identiques octet pour octet au commit.
- Captures C1–C6 : HTTP 200 `image/png`, identiques aux originaux B.2.
- Dark Luxe / Emerald / White : HTTP 200 `image/webp`, versions optimisées.
- Responsive 1440 / 834 / 390 : PASS — 390 testé en vraie émulation mobile (user agent mobile, tactile, viewport 390×844) ; aucun défilement horizontal, aucun bouton tronqué, aucun texte coupé, images non déformées ; galerie Share as Image défilable à 834 et 390 ; en-tête sticky, footer accessible.
- 12/12 images chargées ; aucune erreur console ; aucune ressource en échec.
- Google Play : PASS (clic dans le navigateur → fiche de l'application, HTTP 200).
- Privacy AR / FR : PASS (clic dans le navigateur → HTTP 200, `lang` correct, contenu présent).
- SEO : PASS (title, description, canonical, Open Graph, favicon).
- Accessibilité de base : PASS (un seul H1, hiérarchie H2/H3, `alt` pertinents dont les noms exacts des trois modèles, focus clavier visible).
- Ancres de l'en-tête : section positionnée à 80 px sous le haut du viewport (sous l'en-tête sticky).
- Contenu : 10 sections, textes validés présents, étapes 1/2/3 ; aucune occurrence de « 100% بدون إعلانات », 292, section Ramadan, ancien texte, ancienne maquette, `href="#"`, Noto Kufi ni mécanisme du prototype Design.

### FAIL
Aucun.

### NON TESTÉ — limitation de l'environnement
- Vrais appareils Android / iPhone.
- Safari.
- Firefox.
- Lecteurs d'écran (TalkBack, VoiceOver).
- Contraste mesuré via Lighthouse / axe.
- Aperçu de partage WhatsApp / Facebook / X.
- Option système « réduire les animations » (seule la présence de la règle CSS est vérifiée).
- Ouverture native du Play Store sur Android.
- Parcours clavier complet (seul le focus visible est vérifié).

Ces points ne sont pas bloquants ; ils restent à couvrir par un futur contrôle si nécessaire.

### INFO (sans correction)
- Le halo décoratif derrière la capture du hero dépasse de 6 px à 834 px ; il est masqué et ne permet aucun défilement horizontal.
- L'image Open Graph est `Logo.jpg` (200×200) avec une carte `summary`.
- Les polices (Lateef, IBM Plex Sans Arabic) sont chargées depuis Google Fonts.
- Les captures B.2 conservent leurs caractéristiques réelles (résolution 1080×2340, barre d'état réelle avec icône mode avion, poignée Edge panel Samsung).
- Les pages privacy n'ont pas été modifiées dans ce lot.

---

## 5. Hors périmètre

Toute amélioration future du site (contenu, design, SEO, images, pages privacy) relève d'un nouveau lot ou d'une nouvelle décision.
