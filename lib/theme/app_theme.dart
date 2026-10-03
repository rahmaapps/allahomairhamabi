import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Thème applicatif centralisé — Material 3, construit à partir des tokens
/// du Design System Phase 2. Ce lot ne branche que `main.dart` sur ce thème ;
/// aucun écran n'est refondu ici, les couleurs codées en dur dans les écrans
/// existants sont traitées dans les lots suivants.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColorsLight.primary,
          onPrimary: AppColorsLight.onPrimary,
          primaryContainer: AppColorsLight.primaryContainer,
          onPrimaryContainer: AppColorsLight.primaryPressed,
          secondary: AppColorsLight.secondary,
          onSecondary: AppColorsLight.onPrimary,
          secondaryContainer: AppColorsLight.surfaceAlt,
          onSecondaryContainer: AppColorsLight.textPrimary,
          tertiary: AppColorsLight.goldText,
          onTertiary: AppColorsLight.bg,
          tertiaryContainer: AppColorsLight.surfaceAlt,
          onTertiaryContainer: AppColorsLight.goldText,
          error: AppColorsLight.error,
          onError: AppColorsLight.onPrimary,
          surface: AppColorsLight.surface,
          onSurface: AppColorsLight.textPrimary,
          surfaceContainerHighest: AppColorsLight.surfaceAlt,
          onSurfaceVariant: AppColorsLight.textSecondary,
          outline: AppColorsLight.border,
          outlineVariant: AppColorsLight.borderStrong,
          shadow: AppShadowTint.base,
          scrim: AppColorsLight.scrim,
          inverseSurface: AppColorsLight.textPrimary,
          onInverseSurface: AppColorsLight.bg,
          inversePrimary: AppColorsLight.primaryContainer,
        ),
        scaffoldBackground: AppColorsLight.bg,
        appBarBackground: AppColorsLight.primary,
        appBarForeground: AppColorsLight.onPrimary,
        disabledBg: AppColorsLight.disabledBg,
        textDisabled: AppColorsLight.textDisabled,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColorsDark.primary,
          onPrimary: AppColorsDark.onPrimary,
          primaryContainer: AppColorsDark.surfaceAlt,
          onPrimaryContainer: AppColorsDark.textPrimary,
          secondary: AppColorsDark.accent,
          onSecondary: AppColorsDark.onPrimary,
          secondaryContainer: AppColorsDark.surfaceAlt,
          onSecondaryContainer: AppColorsDark.textPrimary,
          tertiary: AppColorsDark.gold,
          onTertiary: AppColorsDark.bg,
          tertiaryContainer: AppColorsDark.surfaceAlt,
          onTertiaryContainer: AppColorsDark.gold,
          error: AppColorsDark.error,
          onError: AppColorsDark.onPrimary,
          surface: AppColorsDark.surface,
          onSurface: AppColorsDark.textPrimary,
          surfaceContainerHighest: AppColorsDark.surfaceAlt,
          onSurfaceVariant: AppColorsDark.textSecondary,
          outline: AppColorsDark.border,
          outlineVariant: AppColorsDark.border,
          shadow: AppShadowTint.base,
          scrim: AppColorsDark.scrim,
          inverseSurface: AppColorsDark.textPrimary,
          onInverseSurface: AppColorsDark.bg,
          inversePrimary: AppColorsDark.primary,
        ),
        scaffoldBackground: AppColorsDark.bg,
        appBarBackground: AppColorsDark.appBar,
        appBarForeground: AppColorsDark.textPrimary,
        disabledBg: AppColorsDark.surfaceAlt,
        textDisabled: AppColorsDark.textDisabled,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color disabledBg,
    required Color textDisabled,
  }) {
    // Police embarquée localement (asset .ttf déclaré dans pubspec.yaml) —
    // aucun appel à google_fonts, aucun téléchargement runtime.
    final baseTextTheme = (brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true).textTheme
            : ThemeData.light(useMaterial3: true).textTheme)
        .apply(
      fontFamily: AppTypography.plexFamily,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      disabledColor: textDisabled,
      textTheme: baseTextTheme.copyWith(
        titleLarge: AppTypography.screenTitle.copyWith(color: colorScheme.onSurface),
        titleMedium: AppTypography.sectionTitle.copyWith(color: colorScheme.onSurface),
        bodyLarge: AppTypography.body.copyWith(color: colorScheme.onSurface),
        bodyMedium: AppTypography.body.copyWith(color: colorScheme.onSurfaceVariant),
        labelLarge: AppTypography.button.copyWith(color: colorScheme.onSurface),
        labelMedium: AppTypography.chip.copyWith(color: colorScheme.onSurfaceVariant),
        labelSmall: AppTypography.label.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.display.copyWith(
          fontSize: 22,
          color: appBarForeground,
        ),
      ),
    );
  }
}
