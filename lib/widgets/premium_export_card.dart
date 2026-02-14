// lib/widgets/premium_export_card.dart

import 'package:flutter/material.dart';
import '../premium_templates.dart';

class PremiumExportCard extends StatelessWidget {
  final PremiumTemplate template;
  final String duaText;
  final String? footer;
  final String? logoAsset;

  const PremiumExportCard({
    super.key,
    required this.template,
    required this.duaText,
    this.footer,
    this.logoAsset,
  });

  /// Ajuste légèrement la taille de la police selon la longueur du dou'a.
  double _fontSizeFor(String text) {
    final len = text.runes.length;
    if (len <= 180) return 54; // court
    if (len <= 300) return 48; // moyen
    return 42; // long
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,   // format premium vertical 4:5
      height: 1350, // (1080 × 1350)
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(template.bgAsset), // background premium
          fit: BoxFit.cover,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0),
        child: Column(
          children: [
            const SizedBox(height: 72),

            // Logo optionnel (PNG blanc transparent conseillé)
            if (logoAsset != null)
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  logoAsset!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),

            const Spacer(),

            // Doua en arabe — important : Directionality pour RTL
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                duaText,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Lateef',
                  fontSize: _fontSizeFor(duaText),
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ),

            const Spacer(),

            // Footer optionnel (signature de l'application)
            if (footer != null)
              Text(
                footer!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 28,
                  color: Colors.white70,
                ),
              ),

            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}