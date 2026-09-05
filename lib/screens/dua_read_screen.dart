import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard, Haptics
import 'package:share_plus/share_plus.dart';

import '../dua_repository.dart';
import '../models/dua.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../user_prefs.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';

/// D'où l'écran a été ouvert. Cadré au LOT 3.D.0, verrouillé par
/// l'architecture du LOT 3.D.1 — n'influence aujourd'hui ni le rendu ni la
/// logique de cet écran (aucune des décisions verrouillées n'en dépend :
/// pas de surlignage de recherche, pas de comportement différencié). Conservé
/// tel quel car explicitement mandaté par l'architecture verrouillée, pas
/// parce qu'un besoin technique interne l'exigerait — voir rapport LOT 3.D.1.
enum DuaReadOrigin { search, favorites }

/// Écran de lecture mutualisé (§ Lecture, cadré LOT 3.D.0) — ouvert depuis
/// Recherche ou Favoris. Pleine page, aucune `AppCard`, aucun ombre/rayon.
/// AppBar sans titre (retour + ♥), texte `AppTypography.duaBody` centré
/// (défile si trop long), barre basse fixe نسخ (secondaire) / مشاركة
/// (primaire). Aucune catégorie affichée (retirée — audit UX : aucune
/// valeur réelle sur cet écran, ~70 % des douʿās sont `عام`), aucun
/// تدعو آخر, aucun swipe, aucune suggestion.
class DuaReadScreen extends StatefulWidget {
  const DuaReadScreen({
    super.key,
    required this.duaId,
    required this.origin,
  });

  final int duaId;
  final DuaReadOrigin origin;

  @override
  State<DuaReadScreen> createState() => _DuaReadScreenState();
}

class _DuaReadScreenState extends State<DuaReadScreen> {
  final _repo = DuaRepository();

  // Même suffixe que HOME (home_screen.dart) — dupliqué localement, comme
  // déjà fait ailleurs dans le projet (aucune constante partagée existante).
  static const String _attrSuffix = '\n\n— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —';

  late final Future<Dua?> _futureDua;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _futureDua = _loadDua();
    _loadFavoriteState();
  }

  /// Charge le douʿā par `duaId` (jamais d'objet `Dua` copié depuis
  /// l'appelant). Résolution du texte identique au motif déjà utilisé par
  /// Favoris : texte personnalisé sauvegardé → repli sur le texte JSON brut.
  Future<Dua?> _loadDua() async {
    final dua = await _repo.getById(widget.duaId);
    if (dua == null) return null;

    final savedText = await UserPrefs.getFavoriteText(dua.id);
    if (savedText != null && savedText.isNotEmpty) {
      return Dua(
        id: dua.id,
        category: dua.category,
        length: dua.length,
        text: savedText,
        personKey: dua.personKey,
      );
    }
    return dua;
  }

  Future<void> _loadFavoriteState() async {
    final isFav = await UserPrefs.instance.isFavorite(widget.duaId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  /// `UserPrefs` est l'unique source de vérité — aucun état local
  /// indépendant. Retirer ♥ ne ferme jamais cet écran (simple `setState`).
  Future<void> _toggleFavorite() async {
    await UserPrefs.instance.toggleFavorite(widget.duaId);
    final isFav = await UserPrefs.instance.isFavorite(widget.duaId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: '$text$_attrSuffix'));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ ✓'), duration: Duration(seconds: 1)),
    );
  }

  void _share(String text) {
    Share.share('$text$_attrSuffix', subject: 'دعاء');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Même lecture que HOME/Favoris (LOT 2.2 / 3.C.1) : jamais
    // `ColorScheme.onPrimary` pour le texte/icônes d'AppBar.
    final appBarForeground = isDark ? AppColorsDark.textPrimary : AppColorsLight.onPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppTopBar(
          // Sans titre (§ Lecture : « AppBar sans titre : retour + ♥ »).
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: appBarForeground),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? cs.error : appBarForeground,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: FutureBuilder<Dua?>(
          future: _futureDua,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final dua = snap.data;
            if (dua == null) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Centré verticalement si le texte tient ; défile
                      // sinon (idiome standard Flutter : ConstrainedBox
                      // avec minHeight = hauteur du viewport, à l'intérieur
                      // d'un SingleChildScrollView).
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    dua.text,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: AppTypography.duaBody.copyWith(color: cs.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: FutureBuilder<Dua?>(
          future: _futureDua,
          builder: (context, snap) {
            final dua = snap.data;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        role: AppButtonRole.secondary,
                        icon: Icons.copy,
                        label: 'نسخ',
                        onPressed: dua == null ? null : () => _copy(dua.text),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        role: AppButtonRole.primary,
                        icon: Icons.share,
                        label: 'مشاركة',
                        onPressed: dua == null ? null : () => _share(dua.text),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
