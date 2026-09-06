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
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_snackbar.dart';

/// Écran de lecture mutualisé — **une carte de lecture agrandie**, pas un
/// écran distinct (LOT 3.I, docs/ui_ux/LOT_3I_DUAREADSCREEN_SPEC.md).
/// Ouvert depuis Recherche et Favoris. AppBar minimaliste (retour seul,
/// zone B vide) ; carte N1 (`AppCard(level: hero)`, rosace incluse — §A.3
/// option (a) : c'est littéralement « la carte du douʿā agrandie », aucune
/// duplication locale) ; texte `duaLong` ; ♥ dans le **pied de la carte**,
/// jamais dans l'AppBar ; نسخ/مشاركة sous la carte. Aucun fade/blur/gradient
/// sur le texte religieux : le scroll se termine par une coupure nette.
class DuaReadScreen extends StatefulWidget {
  const DuaReadScreen({super.key, required this.duaId});

  final int duaId;

  @override
  State<DuaReadScreen> createState() => _DuaReadScreenState();
}

class _DuaReadScreenState extends State<DuaReadScreen>
    with SingleTickerProviderStateMixin {
  final _repo = DuaRepository();

  // Même suffixe que HOME/Favoris — dupliqué localement (même motif déjà
  // en place dans le projet, aucune constante partagée existante).
  static const String _attrSuffix = '\n\n— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —';

  // Un seul Future pour tout l'écran (§B.8) — douʿā et statut favori
  // chargés ensemble, un seul FutureBuilder consomme le résultat.
  late final Future<({Dua? dua, bool isFavorite})> _future;
  bool _isFavorite = false;

  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut),
    );
    _future = _load();
    // Synchronise `_isFavorite` une seule fois, à la résolution du Future
    // (pas à chaque rebuild — `snap.data` resterait sinon figé sur l'état
    // initial et écraserait un `_toggleFavorite` ultérieur).
    _future.then((data) {
      if (mounted) setState(() => _isFavorite = data.isFavorite);
    });
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  /// Résolution du texte identique au motif déjà utilisé par Favoris/HOME :
  /// texte personnalisé sauvegardé → repli sur le texte JSON brut.
  Future<({Dua? dua, bool isFavorite})> _load() async {
    final dua = await _repo.getById(widget.duaId);
    if (dua == null) return (dua: null, isFavorite: false);

    final savedText = await UserPrefs.getFavoriteText(dua.id);
    final resolved = (savedText != null && savedText.isNotEmpty)
        ? Dua(
            id: dua.id,
            category: dua.category,
            length: dua.length,
            text: savedText,
            personKey: dua.personKey,
          )
        : dua;

    final isFav = await UserPrefs.instance.isFavorite(widget.duaId);
    return (dua: resolved, isFavorite: isFav);
  }

  /// `UserPrefs` reste l'unique source de vérité (§B.4) — aucun état local
  /// indépendant. Retirer le ♥ ne ferme jamais l'écran (simple `setState`).
  /// Animation uniquement à l'ajout (scale 1 → 1.12 → 1, 200 ms) — asymétrie
  /// volontaire déjà spécifiée pour le ♥ du HOME (§A.5/§2).
  Future<void> _toggleFavorite() async {
    HapticFeedback.selectionClick();
    final wasFavorite = _isFavorite;
    await UserPrefs.instance.toggleFavorite(widget.duaId);
    final isFav = await UserPrefs.instance.isFavorite(widget.duaId);
    if (!mounted) return;
    setState(() => _isFavorite = isFav);
    if (!wasFavorite && isFav) {
      _heartCtrl.forward(from: 0).then((_) => _heartCtrl.reverse());
    }
  }

  /// Toast §3 (fond `textPrimary`, texte `onPrimary`, 2,5 s, aucun bouton)
  /// — remplace le `SnackBar` Material brut utilisé avant ce lot (§B.6).
  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: '$text$_attrSuffix'));
    HapticFeedback.selectionClick();
    showAppToast(context, 'تم النسخ');
  }

  /// Partage texte simple uniquement, mécanisme natif existant — aucun
  /// partage image dans cette interface (§B.7).
  void _share(String text) {
    Share.share('$text$_attrSuffix', subject: 'دعاء');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Même lecture que HOME/Favoris/Visite (LOT 2.2) : ivoire fixe par
    // mode, jamais `cs.onPrimary` (illisible sur le fond `appBar` Dark).
    final appBarForeground =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.onPrimary;
    final heartInactiveColor =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // AppBar minimaliste : retour uniquement, zone B vide, aucun titre
        // (le modèle `Dua` n'en a pas — §A.2), aucun ♥ ici (§A.5).
        appBar: AppTopBar(
          height: 52,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: appBarForeground),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: FutureBuilder<({Dua? dua, bool isFavorite})>(
          future: _future,
          builder: (context, snap) {
            // Lecture locale, quelques millisecondes (§B.8) : aucun
            // indicateur de chargement — un corps vide le temps d'un frame
            // plutôt qu'un `CircularProgressIndicator` qui ne ferait que
            // clignoter.
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            final dua = snap.data?.dua;
            if (dua == null) {
              return const AppEmptyState(
                message: 'تعذّر العثور على هذا الدعاء.',
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: AppCard(
                        level: AppCardLevel.hero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Seul élément défilant de l'écran (§A.6) —
                            // centré si le texte tient, défile sinon.
                            // Aucun fade/blur/gradient : coupure nette au
                            // bord de la carte (le `ClipRRect` d'`AppCard`
                            // suffit à la border proprement).
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints:
                                              const BoxConstraints(maxWidth: 340),
                                          child: Text(
                                            dua.text,
                                            textAlign: TextAlign.center,
                                            textDirection: TextDirection.rtl,
                                            style: AppTypography.duaLong
                                                .copyWith(color: cs.onSurface),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Pied de carte : ♥ seul, aligné en fin de ligne
                            // (côté gauche en flux RTL) — §A.5.
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                const Spacer(),
                                ScaleTransition(
                                  scale: _heartScale,
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: _toggleFavorite,
                                      icon: Icon(
                                        _isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 24,
                                        color: _isFavorite
                                            ? cs.error
                                            : heartInactiveColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: AppButton(
                            role: AppButtonRole.secondary,
                            icon: Icons.copy,
                            label: 'نسخ',
                            onPressed: () => _copy(dua.text),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            role: AppButtonRole.primary,
                            icon: Icons.share,
                            label: 'مشاركة',
                            onPressed: () => _share(dua.text),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
