import 'package:flutter/material.dart';

import 'app_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Carte de résultat commune Recherche ↔ Favoris (§4 Recherche, §4 Favoris :
/// « La carte de favori EST la carte de résultat de recherche, inchangée.
/// Seul ajout : un ♥ en tête de ligne »).
///
/// Coquille N2 (`AppCard(level: content)`) + extrait Lateef 22/1,75 limité
/// à 2 lignes, carte entière tappable, ♥ optionnel en tête. Ni chip, ni
/// action copier/partager/supprimer intégrée à la carte — ces actions
/// vivent ailleurs (écran de lecture, non construit dans ce lot).
///
/// Purement présentationnel : aucune logique métier ni persistance.
class AppDuaResultCard extends StatelessWidget {
  const AppDuaResultCard({
    super.key,
    required this.text,
    this.onTap,
    this.showFavoriteHeart = false,
    this.onFavoriteTap,
    this.highlightQuery,
  });

  final String text;

  /// `null` (par défaut) : le reste de la carte est explicitement neutre —
  /// aucune ondulation, aucune interaction (ex. Favoris tant que l'écran de
  /// lecture n'est pas spécifié, §7). Fourni par un futur appelant
  /// (Recherche) quand une destination existe réellement.
  final VoidCallback? onTap;

  /// Affiche le ♥ (toujours plein, §4 Favoris) en tête de ligne. `false`
  /// par défaut — Recherche n'en a pas.
  final bool showFavoriteHeart;

  /// Cible de tap dédiée au ♥, distincte de [onTap] (« deux cibles
  /// distinctes », §4 Favoris). Sans effet si [showFavoriteHeart] est
  /// `false` ou si `null`.
  final VoidCallback? onFavoriteTap;

  /// Terme à surligner (fond `#FDF0C8`, §4 Recherche) — `null`/vide
  /// (défaut) : texte rendu tel quel, comportement strictement inchangé
  /// (Favoris n'en fournit pas).
  final String? highlightQuery;

  static const Color _highlightBackground = Color(0xFFFDF0C8);

  List<InlineSpan> _highlightedSpans(String source, String query, TextStyle style) {
    if (query.isEmpty) return [TextSpan(text: source, style: style)];

    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final index = source.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: source.substring(start), style: style));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: source.substring(start, index), style: style));
      }
      spans.add(TextSpan(
        text: source.substring(index, index + query.length),
        // Couleur de texte figée (indépendante du thème) : le fond de
        // surlignage est lui-même une couleur fixe (#FDF0C8), donc
        // `cs.onSurface` (blanc en sombre) y devient illisible.
        style: style.copyWith(
          backgroundColor: _highlightBackground,
          color: AppColorsLight.textPrimary,
        ),
      ));
      start = index + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: AppCard(
          level: AppCardLevel.content,
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showFavoriteHeart) ...[
                if (onFavoriteTap != null)
                  InkWell(
                    onTap: onFavoriteTap,
                    customBorder: const CircleBorder(),
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(Icons.favorite, size: 20, color: cs.error),
                    ),
                  )
                else
                  Icon(Icons.favorite, size: 20, color: cs.error),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _highlightedSpans(
                      text,
                      highlightQuery ?? '',
                      AppTypography.duaCompact.copyWith(
                        fontSize: 22,
                        height: 1.75,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
