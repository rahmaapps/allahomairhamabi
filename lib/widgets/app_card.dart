import 'package:flutter/material.dart';

import 'islamic_pattern_painter.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Niveaux de carte — Design System Phase 2 (§3 « Hiérarchie des cartes »,
/// 4 niveaux N1-N4).
///
/// `hero` (N1, la carte du douʿā), `content` (N2, carte de contenu —
/// Favoris/résultats de recherche) et `settingsGroup` (N3, groupe de
/// réglages — Paramètres, LOT 3.G) sont implémentés. N4 (cartes discrètes)
/// sera ajouté avec le lot qui le consomme réellement, pour éviter de
/// deviner son usage aujourd'hui.
enum AppCardLevel { hero, content, settingsGroup }

/// Carte N1 — `surface` · `r-hero` (24) · `e2` · padding 24 · filet d'or
/// 2 px en tête · rosace 16 pointes en filigrane à 5,5 %. « Seule surface à
/// porter les trois signes » (§3).
///
/// Carte N2 — `surface` · `r-card` (16) · `e0` (trait 1px, aucune ombre) ·
/// padding 20 (§3 Espacements : « padding de carte 20 »). Ni filet d'or, ni
/// rosace, ni `e2` — ces trois signes restent exclusifs à N1.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.level = AppCardLevel.hero,
  });

  final Widget child;
  final AppCardLevel level;

  @override
  Widget build(BuildContext context) {
    switch (level) {
      case AppCardLevel.hero:
        return _HeroCard(child: child);
      case AppCardLevel.content:
        return _ContentCard(child: child);
      case AppCardLevel.settingsGroup:
        return _SettingsGroupCard(child: child);
    }
  }
}

/// N1 — comportement strictement inchangé depuis le LOT 1B/1B.2.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final goldLine = isDark ? AppColorsDark.gold : AppColorsLight.goldLine;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.heroRadius,
        boxShadow: AppShadows.e2,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.heroRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: cs.surface),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicGoldPatternPainter(
                  isDark: isDark,
                  onSurface: cs.onSurface,
                  fillOpacity: 0.055,
                  strokeOpacity: 0.055,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 2, color: goldLine),
                // Expanded (et non un enfant Column non-flexible) : borne
                // explicitement la hauteur donnée à `child` sur celle,
                // finie, déjà résolue pour la carte elle-même — un enfant
                // non-flexible reçoit sinon une hauteur non bornée de la
                // part de Column, ce qu'un contenu interne entièrement
                // positionné (Positioned.fill) ne peut pas tolérer.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: child,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// N2 — carte de contenu. Aucun des 3 privilèges exclusifs de N1 (filet
/// d'or, rosace, `e2`) : un simple trait 1px (`e0`) sur fond `surface`.
class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: cs.outline, width: AppShadows.e0BorderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

/// N3 — groupe de réglages (Paramètres, §4). `surfaceAlt` · `r-card` · `e0`
/// (trait 1px) · **aucun padding propre** : les lignes et les séparateurs
/// « 1 px pleine largeur, absents sur la dernière ligne » (§4) sont posés
/// par l'appelant, afin que les traits touchent réellement les deux bords
/// du groupe (contrairement à N3 générique du §3, indenté de 16).
class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: cs.outline, width: AppShadows.e0BorderWidth),
      ),
      child: child,
    );
  }
}
