import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// AppBar commune à 3 zones (§3 « AppBars ») :
/// - **A — Identité** : `title`/`titleStyle`, fournis par l'appelant (HOME
///   utilise Lateef 25, les écrans secondaires Plex 16/600 + `leading` de
///   retour — ce composant ne décide pas lequel, il les rend tels quels).
///   `title` est optionnel : l'écran de lecture (§ Lecture) n'en porte
///   aucun (« AppBar sans titre : retour + ♥ »).
/// - **B — Actions** : `actions` (zone B, icônes 24 px, zone tactile 48 —
///   assurée par [IconButton] par défaut).
/// - **C — `bottom:`** : `bandeau`, réservé au HOME (bandeau زيارة القبر).
///
/// Style commun (fond `primary`/`appBar`, aucune ombre, aucun filet d'or)
/// déjà porté par [AppBarTheme] (LOT 1A) — ce widget ne le redéfinit pas.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleStyle,
    this.leading,
    this.actions,
    this.bandeau,
    this.height = 52,
  });

  final String? title;
  final TextStyle? titleStyle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bandeau;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      leading: leading,
      title: title == null
          ? null
          : Text(title!, textDirection: TextDirection.rtl, style: titleStyle),
      actions: actions,
      bottom: bandeau,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + (bandeau?.preferredSize.height ?? 0));
}

/// Zone **C** de l'AppBar du HOME — bandeau nommé, h 44, hors du `body`
/// (§1 « Traitement de دعاء زيارة القبر », §2 structure du HOME). Purement
/// présentationnel : libellé, sous-titre et action sont fournis par
/// l'appelant, aucun texte ni navigation n'est codé en dur ici.
class AppVisitBandeau extends StatelessWidget implements PreferredSizeWidget {
  const AppVisitBandeau({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.bandVisite : AppColorsLight.primaryPressed;
    const onBackground = AppColorsLight.onPrimary; // ivoire, identique Light/Dark

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          alignment: Alignment.center,
          // Une seule ligne (§2 : `‹ دعاء زيارة القبر · للقراءة عند الزيارة`) —
          // libellé et sous-titre fondus dans un seul Text.rich pour que
          // l'ellipse s'applique à l'ensemble de la ligne, y compris à 320dp.
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.chevron_left, color: onBackground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: AppTypography.bodyStrong.copyWith(color: onBackground),
                      ),
                      TextSpan(
                        text: ' · $subtitle',
                        style: AppTypography.label.copyWith(
                          color: onBackground.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_height);
}
