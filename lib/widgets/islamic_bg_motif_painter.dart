// lib/widgets/islamic_bg_motif_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Motif islamique (rosaces 16 pointes) pour arrière-plan.
/// Réglages 'gold' un peu plus visibles par défaut.
class IslamicBgMotifPainter extends CustomPainter {
  IslamicBgMotifPainter({
    Color? ink,
    this.grid = 104.0,              // un peu plus dense (↓) que 112
    this.starRadius = 24.0,         // motif un poil plus grand
    this.strokeOpacity = 0.18,      // trait plus visible (0.16–0.22)
    this.fillOpacity = 0.07,        // aplat plus présent (0.05–0.09)
    this.strokeWidth = 1.1,
    this.phase = const Offset(28, 14),
  }) : ink = ink ?? const Color(0xFFB8860B); // DarkGoldenRod (doré doux)

  /// Couleur d'encre (doré par défaut)
  final Color ink;

  /// Espacement entre motifs (plus petit => plus dense)
  final double grid;

  /// Taille d’une rosace
  final double starRadius;

  /// Visibilité du trait et de l’aplat
  final double strokeOpacity;
  final double fillOpacity;

  /// Épaisseur du trait
  final double strokeWidth;

  /// Décalage de phase (évite la rigidité de la grille)
  final Offset phase;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = ink.withOpacity(strokeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fill = Paint()
      ..color = ink.withOpacity(fillOpacity)
      ..style = PaintingStyle.fill;

    for (double y = -phase.dy; y < size.height + grid; y += grid) {
      for (double x = -phase.dx; x < size.width + grid; x += grid) {
        _drawRosace16(canvas, Offset(x, y), starRadius, stroke, fill);
      }
    }
  }

  void _drawRosace16(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final path = Path();
    const int points = 16;
    final double step = (2 * math.pi) / points;
    final double start = math.pi / 8;

    for (int i = 0; i < points; i++) {
      final radius = (i.isEven) ? r : r * .45;
      final double ang = start + i * step;
      final dx = c.dx + radius * math.cos(ang);
      final dy = c.dy + radius * math.sin(ang);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    // Aplat + trait
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant IslamicBgMotifPainter old) {
    return ink != old.ink ||
        grid != old.grid ||
        starRadius != old.starRadius ||
        strokeOpacity != old.strokeOpacity ||
        fillOpacity != old.fillOpacity ||
        strokeWidth != old.strokeWidth ||
        phase != old.phase;
  }
}