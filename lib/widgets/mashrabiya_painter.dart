import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Treillis mashrabiya léger et performant :
/// - Grille carrée (cellSize)
/// - Petite rosace par superposition de 2 carrés (rotation 45°)
/// - Couleurs/opacités paramétrables
class MashrabiyaPainter extends CustomPainter {
  MashrabiyaPainter({
    required this.strokeColor,
    required this.fillColor,
    this.cellSize = 96.0,
    this.strokeWidth = 0.9,
    this.starSize = 14.0,
    this.starFillOpacity = 0.08,
    this.gridStrokeOpacity = 0.18,
  });

  final Color strokeColor;
  final Color fillColor;
  final double cellSize;
  final double strokeWidth;
  final double starSize;
  final double starFillOpacity;
  final double gridStrokeOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Grille
    final gridPaint = Paint()
      ..color = strokeColor.withOpacity(gridStrokeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2) Rosaces aux intersections (2 carrés : 0° et 45°)
    final starStroke = Paint()
      ..color = strokeColor.withOpacity(gridStrokeOpacity + 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final starFill = Paint()
      ..color = fillColor.withOpacity(starFillOpacity)
      ..style = PaintingStyle.fill;

    final half = starSize / 2;

    for (double y = 0; y <= size.height; y += cellSize) {
      for (double x = 0; x <= size.width; x += cellSize) {
        final center = Offset(x, y);
        final cx = center.dx;
        final cy = center.dy;

        // Carré 0°
        final rect0 = Rect.fromCenter(center: center, width: starSize, height: starSize);
        final rrect0 = RRect.fromRectAndRadius(rect0, const Radius.circular(2));
        canvas.drawRRect(rrect0, starFill);
        canvas.drawRRect(rrect0, starStroke);

        // Carré 45°
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(math.pi / 4);
        final rect45 = Rect.fromCenter(center: Offset.zero, width: starSize, height: starSize);
        final rrect45 = RRect.fromRectAndRadius(rect45, const Radius.circular(2));
        canvas.drawRRect(rrect45, starFill);
        canvas.drawRRect(rrect45, starStroke);
        canvas.restore();

        // Petits points décoratifs (quart d’intersection)
        final dotPaint = Paint()
          ..color = strokeColor.withOpacity(gridStrokeOpacity + 0.04)
          ..style = PaintingStyle.fill;
        const dot = 1.8;
        canvas.drawCircle(Offset(cx + half, cy), dot, dotPaint);
        canvas.drawCircle(Offset(cx - half, cy), dot, dotPaint);
        canvas.drawCircle(Offset(cx, cy + half), dot, dotPaint);
        canvas.drawCircle(Offset(cx, cy - half), dot, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MashrabiyaPainter old) {
    return old.strokeColor != strokeColor ||
        old.fillColor   != fillColor   ||
        old.cellSize    != cellSize    ||
        old.strokeWidth != strokeWidth ||
        old.starSize    != starSize    ||
        old.starFillOpacity   != starFillOpacity ||
        old.gridStrokeOpacity != gridStrokeOpacity;
  }
}