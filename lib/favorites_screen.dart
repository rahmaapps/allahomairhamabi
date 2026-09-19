import 'package:flutter/material.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'screens/dua_read_screen.dart';
import 'user_prefs.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'widgets/app_bar.dart';
import 'widgets/app_dua_result_card.dart';
import 'widgets/app_empty_state.dart';
import 'widgets/app_snackbar.dart';

/// Favoris — spécification close (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §4 ;
/// navigation vers l'écran de lecture : LOT 3.I). AppBar h52, `المفضلة`,
/// aucune icône d'action. Carte = `AppDuaResultCard` (identique à la carte
/// de résultat de recherche, ♥ en tête). Ordre : plus récemment ajouté en
/// premier, non modifiable. Tap sur le contenu → `DuaReadScreen` (même
/// transition RTL que Recherche) ; le ♥ reste une cible indépendante.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repo = DuaRepository();

  late Future<List<Dua>> _futureFavs;
  List<Dua> _favs = [];

  @override
  void initState() {
    super.initState();
    _futureFavs = _loadFavorites();
  }

  /// Charge les favoris dans l'ordre plus récemment ajouté → plus ancien
  /// (§4) via `getFavoriteIds().reversed` — `UserPrefs` n'est pas modifié,
  /// `addFavoriteId` ajoute déjà en fin de liste (voir rapport LOT 3.A).
  /// Résolution du texte : identique à l'existant (texte personnalisé
  /// sauvegardé → repli sur le texte JSON brut).
  Future<List<Dua>> _loadFavorites() async {
    final ids = await UserPrefs.instance.getFavoriteIds();
    final orderedIds = ids.reversed.toList();

    final all = await _repo.getAllDuas();
    final byId = {for (final d in all) d.id: d};

    final result = <Dua>[];
    for (final id in orderedIds) {
      final d = byId[id];
      if (d == null) continue;

      final savedText = await UserPrefs.getFavoriteText(d.id);
      if (savedText != null && savedText.isNotEmpty) {
        result.add(
          Dua(
            id: d.id,
            category: d.category,
            length: d.length,
            text: savedText,
            personKey: d.personKey,
          ),
        );
      } else {
        result.add(d);
      }
    }

    _favs = result;
    return result;
  }

  Future<void> _refresh() async {
    final newList = await _loadFavorites();
    if (!mounted) return;
    setState(() {
      _futureFavs = Future.value(newList);
    });
  }

  /// Tap sur le contenu de la carte → `DuaReadScreen` (§B.2 LOT 3.I). Même
  /// transition RTL que Recherche (300 ms `easeInOutCubic`, dupliquée
  /// localement — même motif déjà en place dans le projet, aucune
  /// constante/fonction partagée existante pour cette transition).
  /// Resynchronise la liste au retour : un retrait de favori fait depuis
  /// l'écran de lecture doit immédiatement disparaître de cette liste.
  Future<void> _openReading(Dua dua) async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DuaReadScreen(duaId: dua.id),
        transitionDuration: Duration(milliseconds: reduceMotion ? 150 : 300),
        reverseTransitionDuration: Duration(milliseconds: reduceMotion ? 150 : 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          );
        },
      ),
    );

    await _refresh();
  }

  /// Retrait silencieux, jamais bloquant (§4) : suppression immédiate +
  /// snackbar `تراجع` qui restaure la carte à sa position d'origine dans
  /// la liste affichée.
  ///
  /// `snackBarContext` doit être un descendant du `ScaffoldMessenger`
  /// propre à cet écran (voir `build()`) — jamais `this.context` (l'élément
  /// de `FavoritesScreen` lui-même se trouve *au-dessus* de ce
  /// `ScaffoldMessenger` local, pas en dessous).
  void _removeFavorite(BuildContext snackBarContext, Dua dua) {
    final index = _favs.indexOf(dua);
    if (index == -1) return;

    setState(() {
      _favs.removeAt(index);
      _futureFavs = Future.value(List<Dua>.from(_favs));
    });
    UserPrefs.instance.toggleFavorite(dua.id);

    showAppUndoSnackBar(
      snackBarContext,
      message: 'تمت إزالة الدعاء من المفضلة',
      actionLabel: 'تراجع',
      onUndo: () {
        setState(() {
          _favs.insert(index, dua);
          _futureFavs = Future.value(List<Dua>.from(_favs));
        });
        UserPrefs.instance.toggleFavorite(dua.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Même lecture que HOME (LOT 2.2) : jamais `ColorScheme.onPrimary`
    // pour le texte/icônes d'AppBar — quasi noir en Dark Mode, donc
    // illisible sur le fond `appBar`, lui aussi quasi noir. Ivoire fixe
    // par mode, alignée sur les tokens déjà utilisés par `AppBarTheme`.
    final appBarForeground = isDark ? AppColorsDark.textPrimary : AppColorsLight.onPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      // ScaffoldMessenger local à cet écran : le snackbar تراجع est ainsi
      // physiquement détaché quand FavoritesScreen quitte l'arbre (retour
      // arrière), au lieu du ScaffoldMessenger racine de MaterialApp
      // (partagé par toute l'app, ce qui le laissait visible après avoir
      // quitté l'écran).
      child: ScaffoldMessenger(
        child: Scaffold(
          appBar: AppTopBar(
            title: 'المفضلة',
            height: 52,
            titleStyle: AppTypography.sectionTitle.copyWith(color: appBarForeground),
          ),
          body: FutureBuilder<List<Dua>>(
            future: _futureFavs,
            builder: (context, snap) {
              // Lecture locale (§P2-B) — même traitement que Recherche/
              // DuaReadScreen : aucun indicateur de chargement, un cadre
              // vide le temps d'un frame plutôt qu'un spinner qui ne ferait
              // que clignoter.
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final favs = snap.data ?? const <Dua>[];

              if (favs.isEmpty) {
                return const AppEmptyState(
                  message: 'اضغط ♡ على أي دعاء لحفظه هنا.',
                  watermarkIcon: Icons.favorite_border,
                );
              }

              // `RefreshIndicator` retiré (§P2-B) : liste locale déjà
              // resynchronisée au retour de la lecture (`_refresh()` après
              // le `push`) — rien à rafraîchir par un geste de tirage, qui
              // n'introduisait qu'un spinner Material non spécifié.
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: favs.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final d = favs[index];
                  return AppDuaResultCard(
                    text: d.text,
                    showFavoriteHeart: true,
                    onFavoriteTap: () => _removeFavorite(context, d),
                    onTap: () => _openReading(d),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
