import 'package:flutter/material.dart';

import '../dua_repository.dart';
import '../models/dua.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_empty_state.dart';

/// دعاء زيارة القبر — écran de lecture dédié (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md,
/// §1/§4/§6.5 + arbitrages LOT 3.F). Écran plein de lecture seule : aucune
/// action (ni copie, ni partage, ni favori, ni « دعاء آخر »), AppBar sans
/// titre (retour uniquement), N2 délibérément vide.
///
/// Carte dédiée locale — pas `AppCard(level: hero)`, qui peint toujours la
/// rosace, interdite ici : filet or + ✦ fixe en tête, aucune rosace, aucune
/// attribution en pied (décision finale LOT 3.F : « aucune attribution et
/// aucune source affichée » — remplace le `رواه مسلم` du document).
///
/// Le choix de la personne a déjà eu lieu en amont (bottom sheet HOME,
/// LOT 3.F) : cet écran ne porte lui-même aucun sélecteur ni chip de
/// personne.
class GraveVisitReadScreen extends StatefulWidget {
  const GraveVisitReadScreen({super.key, required this.personKey});

  final String personKey;

  @override
  State<GraveVisitReadScreen> createState() => _GraveVisitReadScreenState();
}

class _GraveVisitReadScreenState extends State<GraveVisitReadScreen> {
  final _repo = DuaRepository();
  late final Future<Dua?> _futureDua;

  @override
  void initState() {
    super.initState();
    _futureDua = _loadDua();
  }

  /// Charge le douʿā `grave_visit` de [personKey] — jamais un objet `Dua`
  /// copié depuis l'appelant (même discipline que `DuaReadScreen`).
  /// Exactement un douʿā `grave_visit` par `PersonType` (vérifié lors du
  /// pré-audit du LOT 3.F) : `.first` est donc fiable. Aucun
  /// `DuaPersonalizer` ici (décision explicite du LOT 3.F) — le texte est
  /// affiché tel qu'il provient des données.
  Future<Dua?> _loadDua() async {
    final list = await _repo.loadFilteredForPersons(
      personKeys: [widget.personKey],
      lengthFilter: 'all',
      categoryFilter: 'grave_visit',
    );
    return list.isEmpty ? null : list.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Même lecture que HOME/Favoris/Lecture (LOT 2.2/3.C.1/3.D.1) : jamais
    // `ColorScheme.onPrimary` pour le texte/icônes d'AppBar.
    final appBarForeground = isDark ? AppColorsDark.textPrimary : AppColorsLight.onPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppTopBar(
          // Sans titre, aucune action (§4 : « aucune icône d'action »).
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: appBarForeground),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        // N2 délibérément vide (§4) : rien d'autre que la carte.
        // `SafeArea(top: false, …)` : le haut est déjà purgé par le
        // `Scaffold` sous `AppTopBar` ; sans bottom bar ici (contrairement à
        // `DuaReadScreen`), le bas doit être protégé explicitement pour que
        // la dernière ligne du douʿā reste remontable au-dessus de la barre
        // de navigation système (anomalie constatée en test manuel).
        body: SafeArea(
          top: false,
          child: FutureBuilder<Dua?>(
            future: _futureDua,
            builder: (context, snap) {
              // Lecture locale (§P2-B) — même traitement que Recherche/
              // DuaReadScreen : aucun indicateur de chargement.
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final dua = snap.data;
              if (dua == null) {
                // Jamais d'écran blanc (§P1-G) — même gabarit/message que
                // `DuaReadScreen` pour le même cas (douʿā introuvable).
                return const AppEmptyState(
                  message: 'تعذّر العثور على هذا الدعاء.',
                );
              }
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _GraveVisitCard(text: dua.text),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Carte dédiée — `surface` · `r-hero 24` · `e2` · filet or 2px + ✦ fixe en
/// tête · aucune rosace · aucune attribution en pied. Dupliquée plutôt que
/// paramétrée dans `AppCard` pour un seul appelant (même logique que les
/// autres duplications locales du projet).
class _GraveVisitCard extends StatelessWidget {
  const _GraveVisitCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final goldLine = isDark ? AppColorsDark.gold : AppColorsLight.goldLine;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.heroRadius,
        boxShadow: AppShadows.e2,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.heroRadius,
        child: Container(
          color: cs.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 2, color: goldLine),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Center(
                  child: Text(
                    '✦',
                    style: TextStyle(color: goldLine, fontSize: 20, height: 1),
                  ),
                ),
              ),
              Expanded(child: _FadingDuaText(text: text)),
              // Bas de carte volontairement vide (décision finale LOT 3.F :
              // aucune attribution, aucune source affichée).
            ],
          ),
        ),
      ),
    );
  }
}

/// Texte du douʿā — seul élément défilant de l'écran, largeur plafonnée
/// 340 dp (même motif que `DuaReadScreen`). LOT 3.J : texte pleinement
/// opaque, aucun fondu artificiel — coupure nette aux limites du scroll,
/// alignée sur la règle appliquée à HOME (LOT 3.I.B) et à `DuaReadScreen`.
class _FadingDuaText extends StatelessWidget {
  const _FadingDuaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Centré verticalement si le texte tient ; défile sinon — même
        // idiome que `DuaReadScreen`.
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                // Tablette : largeur de lecture plafonnée à 340 dp (§4).
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.duaBody.copyWith(
                    fontSize: 27,
                    height: 2.0,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
