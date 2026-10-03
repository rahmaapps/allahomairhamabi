import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Gabarit unique d'état vide, à 4 couches (§3 « Composants communs ») :
/// rosace filigrane 88-96 px à 15 %, une phrase en Lateef 24-25, une phrase
/// d'aide en Plex 12,5, zéro ou un bouton Primary. Centrage vertical
/// décalé de −24. Jamais d'écran vide, jamais d'illustration.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.helper,
    this.buttonLabel,
    this.onButtonPressed,
    this.watermarkSize = 92,
    this.watermarkIcon,
  });

  final String message;
  final String? helper;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  /// 88-96 px (§3).
  final double watermarkSize;

  /// Glyphe de filigrane optionnel, à la place de la rosace par défaut —
  /// certains écrans (Favoris §4 : « glyphe ♡ ») spécifient un glyphe
  /// différent de la rosace générique du gabarit (§3). `null` (défaut) :
  /// comportement strictement inchangé, rosace peinte comme avant.
  final IconData? watermarkIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColorsDark.gold : AppColorsLight.goldLine;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: watermarkSize,
              height: watermarkSize,
              child: watermarkIcon == null
                  ? CustomPaint(
                      painter: _RosetteWatermarkPainter(color: ink, opacity: 0.15),
                    )
                  : Icon(
                      watermarkIcon,
                      size: watermarkSize,
                      color: ink.withValues(alpha: 0.15),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTypography.display.copyWith(fontSize: 24, color: cs.onSurface),
            ),
            if (helper != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                helper!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTypography.label.copyWith(
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(label: buttonLabel!, onPressed: onButtonPressed),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rosace 16 pointes, instance unique (non carrelée) — même géométrie que
/// celle déjà utilisée pour les motifs de fond de l'app
/// (`islamic_pattern_painter.dart`, `islamic_bg_motif_painter.dart`),
/// reprise ici pour un filigrane centré isolé plutôt que dupliquée en trame.
class _RosetteWatermarkPainter extends CustomPainter {
  const _RosetteWatermarkPainter({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final fill = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    const points = 16;
    const step = (2 * math.pi) / points;
    const start = math.pi / 8;

    for (int i = 0; i < points; i++) {
      final r = i.isEven ? radius : radius * 0.46;
      final angle = start + i * step;
      final dx = center.dx + r * math.cos(angle);
      final dy = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _RosetteWatermarkPainter old) =>
      color != old.color || opacity != old.opacity;
}
