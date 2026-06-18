import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Motif doré "luxe" pour la CARTE (derrière le texte),
/// paramétrable : opacités, taille de cellule, décalage/stagger.
/// - Moins visible => opacités basses + cellules plus grandes.
/// - Décalage (phase/stagger) => casse la répétitivité trop "grille".
class IslamicGoldPatternPainter extends CustomPainter {
  IslamicGoldPatternPainter({
    required this.isDark,
    required this.onSurface,

    // Réglages de VISIBILITÉ (à jouer en priorité)
    this.strokeOpacity = 0.12,   // 0.08–0.16 (trait)
    this.fillOpacity   = 0.045,  // 0.03–0.06 (aplat)
    this.strokeWidth   = 0.9,

    // Réglages de DENSITÉ
    this.cell          = 96.0,   // 88–116 (plus grand => moins dense)
    this.starRadius    = 20.0,   // 18–24

    // Réglages de DÉCALAGE
    this.phaseX        = 22.0,   // décalage absolu X (px)
    this.phaseY        = 12.0,   // décalage absolu Y (px)
    this.rowStagger    = 0.5,    // 0.0–1.0  (décale 1/2 cellule une ligne sur deux)
  });

  final bool isDark;
  final Color onSurface;

  final double strokeOpacity;
  final double fillOpacity;
  final double strokeWidth;

  final double cell;
  final double starRadius;

  final double phaseX;
  final double phaseY;
  final double rowStagger;

  // Or "brossé" + aplat or chaud
  Color get _goldStroke => const Color(0xFFB8860B).withOpacity(strokeOpacity);
  Color get _goldFill   => const Color(0xFFFFD700).withOpacity(fillOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = _goldStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fill = Paint()
      ..color = _goldFill
      ..style = PaintingStyle.fill;

    // Boucle en "lignes" + "stagger" (décalage 1/2 cellule une ligne sur deux)
    int row = 0;
    for (double y = -phaseY; y < size.height + cell; y += cell, row++) {
      final double staggerX = (row.isOdd ? (cell * rowStagger) : 0.0);
      for (double x = -phaseX + staggerX; x < size.width + cell; x += cell) {
        _drawRosace16(canvas, Offset(x, y), starRadius, stroke, fill);
      }
    }

    // Liseré intérieur ultra léger pour refermer le cadre de la carte (optionnel)
    final border = Paint()
      ..color = _goldStroke.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height).deflate(0.6),
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, border);
  }

  void _drawRosace16(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final path = Path();
    const int points = 16;
    final double step = (2 * math.pi) / points;
    final double start = math.pi / 8;

    for (int i = 0; i < points; i++) {
      final radius = (i.isEven) ? r : r * 0.46;
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
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant IslamicGoldPatternPainter old) {
    return isDark != old.isDark ||
        onSurface != old.onSurface ||
        strokeOpacity != old.strokeOpacity ||
        fillOpacity != old.fillOpacity ||
        strokeWidth != old.strokeWidth ||
        cell != old.cell ||
        starRadius != old.starRadius ||
        phaseX != old.phaseX ||
        phaseY != old.phaseY ||
        rowStagger != old.rowStagger;
  }
}