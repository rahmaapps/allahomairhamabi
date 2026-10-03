import 'package:flutter/material.dart';

/// Rayons — Design System Phase 2 (§3).
class AppRadii {
  const AppRadii._();

  static const double field = 8;
  static const double fieldCompact = 6; // cases à cocher
  static const double button = 12;
  static const double card = 16;
  static const double hero = 24; // carte du douʿā, haut des bottom sheets
  static const double pill = 999;

  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(field));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius heroRadius = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
}
