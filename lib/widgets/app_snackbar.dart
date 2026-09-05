import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Snackbar avec annulation « تراجع » — `surfaceAlt inversé`, r 12, 6 s,
/// ancré à 16 dp du bas, une seule annulation à la fois, jamais empilée
/// (§3 « Composants communs »).
///
/// Lecture de « `surfaceAlt` inversé » : le document ne donne pas de valeur
/// hex dédiée à ce token. On utilise ici `ColorScheme.inverseSurface` /
/// `onInverseSurface` (déjà mappés sur les tokens Phase 2 dans
/// `AppTheme`, LOT 1A) — la lecture la plus directe d'une « surface
/// inversée » avec l'API Material. À confirmer si un token dédié est
/// tranché plus tard.
void showAppUndoSnackBar(
  BuildContext context, {
  required String message,
  required String actionLabel,
  required VoidCallback onUndo,
}) {
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);

  // Une seule annulation à la fois, jamais empilée.
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: cs.inverseSurface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.buttonRadius),
      margin: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        style: AppTypography.body.copyWith(color: cs.onInverseSurface),
      ),
      action: SnackBarAction(
        label: actionLabel,
        textColor: cs.onInverseSurface,
        onPressed: onUndo,
      ),
    ),
  );
}
