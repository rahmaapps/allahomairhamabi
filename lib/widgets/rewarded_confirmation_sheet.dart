import 'package:flutter/material.dart';

import '../monetization/rewarded_wording.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Confirmation préalable à tout Rewarded (LOT 5.G.B) : le Rewarded reste
/// un choix explicite de l'utilisateur, jamais déclenché d'un seul tap.
///
/// Aucun nouveau composant générique : même habillage que les feuilles déjà
/// présentes dans l'application (fond `bg`, rayon `hero`, poignée — voir
/// `_openTemplatePicker` dans `home_screen.dart`), et boutons `AppButton`
/// du Design System.
///
/// Retourne `true` uniquement si l'utilisateur confirme ; toute fermeture
/// (bouton d'annulation, glissement, tap hors feuille, retour) vaut refus.
Future<bool> showRewardedConfirmation(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
    ),
    builder: (sheetContext) {
      final cs = Theme.of(sheetContext).colorScheme;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                RewardedWording.confirmation,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTypography.body.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                role: AppButtonRole.primary,
                label: RewardedWording.confirmAction,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                role: AppButtonRole.secondary,
                label: RewardedWording.cancelAction,
                onPressed: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
