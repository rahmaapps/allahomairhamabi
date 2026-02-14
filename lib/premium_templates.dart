// lib/premium_templates.dart
import 'package:flutter/material.dart';

enum PremiumTemplate { darkLuxe, emerald, whiteElegant }

extension PremiumTemplateX on PremiumTemplate {
  String get bgAsset {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return 'assets/premium/backgrounds/dark_luxe_bg.png';
      case PremiumTemplate.emerald:
        return 'assets/premium/backgrounds/emerald_bg.png';
      case PremiumTemplate.whiteElegant:
        return 'assets/premium/backgrounds/white_elegant_bg.png';
    }
  }

  String get thumbAsset {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return 'assets/premium/previews/dark_luxe_thumb.png';
      case PremiumTemplate.emerald:
        return 'assets/premium/previews/emerald_thumb.png';
      case PremiumTemplate.whiteElegant:
        return 'assets/premium/previews/white_elegant_thumb.png';
    }
  }

  String get displayName {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return 'Dark Luxe';
      case PremiumTemplate.emerald:
        return 'Emerald';
      case PremiumTemplate.whiteElegant:
        return 'White';
    }
  }
}
