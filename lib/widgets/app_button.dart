import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Rôles de bouton — Design System Phase 2 (§3 « Boutons »).
///
/// `primary` (LOT 1B), `secondary` et `action` (tonal, LOT 2) sont
/// implémentés — les seuls dont un élément d'écran concret a été identifié
/// (état vide, دعاء آخر, نسخ/مشاركة du HOME). `text` et `destructive`
/// restent non implémentés : le document les spécifie mais aucun écran ne
/// leur a encore assigné d'usage concret — ils seront ajoutés quand ce sera
/// le cas, plutôt que d'inventer une affectation.
enum AppButtonRole { primary, secondary, action }

/// Bouton commun — hauteur 48, rayon 12, Plex 16/600, pressé = couleur
/// pressée + `scale .98`, aucune ondulation Material, jamais `opacity: .38`
/// pour désactiver (§3).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.role = AppButtonRole.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonRole role;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final border = isDark ? AppColorsDark.border : AppColorsLight.border;

    Color background;
    Color foreground;
    BoxBorder? boxBorder;

    switch (widget.role) {
      case AppButtonRole.primary:
        // Le document ne définit un token `primaryPressed` distinct que pour
        // le Light Mode (§3). Aucune valeur "pressée" propre au Dark Mode
        // n'est validée : on retombe sur `primary` en Dark plutôt que d'en
        // inventer une — voir rapport LOT 1B.
        if (!enabled) {
          background = isDark ? AppColorsDark.surfaceAlt : AppColorsLight.disabledBg;
          foreground = isDark ? AppColorsDark.textDisabled : AppColorsLight.textDisabled;
        } else if (_pressed) {
          background = isDark ? AppColorsDark.primary : AppColorsLight.primaryPressed;
          foreground = cs.onPrimary;
        } else {
          background = cs.primary;
          foreground = cs.onPrimary;
        }
        break;

      case AppButtonRole.secondary:
        // Repos : `surface`, trait 1,5 `primary` · pressé : `primaryContainer`
        // · désactivé : trait `border` (§3).
        if (!enabled) {
          background = cs.surface;
          foreground = isDark ? AppColorsDark.textDisabled : AppColorsLight.textDisabled;
          boxBorder = Border.all(color: border, width: 1.5);
        } else if (_pressed) {
          background = cs.primaryContainer;
          foreground = cs.primary;
          boxBorder = Border.all(color: cs.primary, width: 1.5);
        } else {
          background = cs.surface;
          foreground = cs.primary;
          boxBorder = Border.all(color: cs.primary, width: 1.5);
        }
        break;

      case AppButtonRole.action:
        // Repos : `surfaceAlt` / `textPrimary` · pressé : `#F5E8CE` (Light —
        // aucune valeur Dark distincte validée, on retombe sur `surfaceAlt`,
        // même lecture que `primaryPressed` en Dark ci-dessus) · désactivé :
        // `disabledBg` (§3).
        if (!enabled) {
          background = isDark ? AppColorsDark.surfaceAlt : AppColorsLight.disabledBg;
          foreground = isDark ? AppColorsDark.textDisabled : AppColorsLight.textDisabled;
        } else if (_pressed) {
          background = isDark ? AppColorsDark.surfaceAlt : const Color(0xFFF5E8CE);
          foreground = isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
        } else {
          background = isDark ? AppColorsDark.surfaceAlt : AppColorsLight.surfaceAlt;
          foreground = isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
        }
        break;
    }

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            border: boxBorder,
            borderRadius: AppRadii.buttonRadius,
          ),
          child: Material(
            color: background,
            borderRadius: AppRadii.buttonRadius,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: AppRadii.buttonRadius,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: foreground),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.button.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
