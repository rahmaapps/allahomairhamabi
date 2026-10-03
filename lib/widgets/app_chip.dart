import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Deux variantes, deux intensités — jamais une troisième (§3 « Chips »).
/// - `category` : chips de catégorie du HOME (`عام`, `دعاء الجمعة`).
/// - `person` : chips de personne (Person Selection).
///
/// Interdits par la spécification : croix de suppression, icône dans la
/// chip, compteur, bordure épaissie — ce widget ne les expose pas.
enum AppChipVariant { category, person }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.variant = AppChipVariant.category,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipVariant variant;

  static const Color _personSelectedBorder = Color(0xFFC3DED2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final border = isDark ? AppColorsDark.border : AppColorsLight.border;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    final double height = variant == AppChipVariant.category ? 44 : 40;

    Color background;
    Color borderColor;
    Color textColor;
    FontWeight weight;

    if (variant == AppChipVariant.category) {
      if (selected) {
        background = cs.primary;
        borderColor = cs.primary;
        textColor = cs.onPrimary;
        weight = FontWeight.w600;
      } else {
        background = cs.surface;
        borderColor = border;
        textColor = textSecondary;
        weight = FontWeight.w500;
      }
    } else {
      if (selected) {
        background = cs.primaryContainer;
        borderColor = _personSelectedBorder;
        textColor = cs.primary;
        weight = FontWeight.w600;
      } else {
        background = Colors.transparent;
        borderColor = border;
        textColor = textSecondary;
        weight = FontWeight.w500;
      }
    }

    // Hauteur visible 44/40 (§3), zone tactile minimale 48 (§3 « Espacements »)
    // : le conteneur visible est centré dans une zone de frappe de 48.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadii.pillRadius,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              style: AppTypography.chip.copyWith(color: textColor, fontWeight: weight),
            ),
          ),
        ),
      ),
    );
  }
}
