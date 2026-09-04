import 'dart:async';

import 'package:flutter/material.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'screens/dua_read_screen.dart';
import 'theme/app_radii.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'widgets/app_dua_result_card.dart';

/// Recherche — spécification close (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §4).
/// Le champ remplace l'AppBar (pas de titre `البحث`). Résultats en
/// `AppDuaResultCard` (identique à Favoris, sans ♥), surlignage du terme
/// uniquement ici (jamais transmis à `DuaReadScreen`).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = DuaRepository();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<Dua> _all = [];
  List<Dua> _results = [];
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _initData();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final all = await _repo.getAllDuas();
    if (!mounted) return;
    setState(() {
      _all = all;
      _results = all;
    });
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    // Debounce 250 ms (§4 Recherche).
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final q = _controller.text.trim();
      setState(() {
        _query = q;
        _results = q.isEmpty ? _all : _all.where((d) => d.text.contains(q)).toList();
      });
    });
  }

  Future<void> _openReading(Dua dua) async {
    // Fermer le clavier avant la transition (navigation verrouillée).
    _focusNode.unfocus();

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DuaReadScreen(duaId: dua.id, origin: DuaReadOrigin.search),
        transitionDuration: Duration(milliseconds: reduceMotion ? 150 : 300),
        reverseTransitionDuration: Duration(milliseconds: reduceMotion ? 150 : 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          // S1 : glissement RTL 300ms easeInOutCubic — le nouvel écran
          // entre par la gauche (sens RTL), comme B2 (§2 HOME).
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          );
        },
      ),
    );
    // Recherche restaurée nativement par Flutter (le State de cet écran
    // n'est pas détruit par un push) : terme, résultats et défilement
    // inchangés. Aucun ♥ affiché sur les résultats (§4) → rien à
    // resynchroniser ici, contrairement à Favoris (LOT 3.C.2).
  }

  /// ٠١٢٣... — chiffres arabes-indiens, comme l'exemple du document (§4 :
  /// `ابحث في ٢٢١٥ دعاءً`).
  String _easternDigits(int n) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    return n.toString().split('').map((c) {
      final i = western.indexOf(c);
      return i == -1 ? c : eastern[i];
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Le champ remplace l'AppBar — aucun Scaffold.appBar (§4).
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTypography.body.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    constraints: const BoxConstraints(minHeight: 44),
                    prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                    hintText: 'ابحث عن دعاء...',
                    hintStyle: AppTypography.body.copyWith(color: cs.onSurfaceVariant),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح',
                            icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                            onPressed: () {
                              // Vide le champ en conservant le focus (§4).
                              _controller.clear();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.buttonRadius,
                      borderSide: BorderSide(color: cs.outline, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.buttonRadius,
                      borderSide: BorderSide(color: cs.outline, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.buttonRadius,
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollStartNotification>(
                  // Le clavier se ferme au premier défilement (§4).
                  onNotification: (_) {
                    _focusNode.unfocus();
                    return false;
                  },
                  child: _buildResults(cs),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ColorScheme cs) {
    if (_query.isEmpty) {
      // État initial : glyphe ⌕ + compteur, aucun historique/suggestion.
      return Center(
        child: Text(
          'ابحث في ${_easternDigits(_all.length)} دعاءً',
          textDirection: TextDirection.rtl,
          style: AppTypography.body.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    if (_results.isEmpty) {
      // Aucun résultat : deux lignes, AUCUNE illustration (§4) — `AppEmptyState`
      // rend toujours un filigrane, il ne convient donc pas ici (c'est le
      // gabarit générique à 4 couches du §3, différent de ce cas précis) ;
      // état dédié minimal à la place. Le document ne fixe pas le libellé
      // exact — texte minimal factuel retenu ici, à valider si besoin.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'لا توجد نتائج',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTypography.body.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'جرّب كلمة أخرى',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTypography.label.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final d = _results[index];
        return AppDuaResultCard(
          text: d.text,
          highlightQuery: _query,
          onTap: () => _openReading(d),
        );
      },
    );
  }
}
