import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary
import 'package:flutter/services.dart';  // Clipboard + Haptics
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'user_prefs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Repository
  final DuaRepository _repo = DuaRepository();

  // Contenu courant (ton design utilisait un String + id)
  String _currentDuaText = '...';
  int? _currentId;
  bool _isFavorite = false;

  // Filtres
  String _activeCategory = 'normal'; // 'normal' | 'friday' | 'ramadan'
  String _lengthFilter  = 'all';     // 'all' | 'short' | 'long'

  // Deck anti-répétition
  final List<int> _deckIds = <int>[];
  int _deckCursor = 0;

  // Animations
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _heartCtrl;

  // Clé pour capture d’image (export “Option A” gradient inline)
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.7,
      upperBound: 1.2,
    );

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    _loadInitial();
  }

  @override
  void dispose() {
    _anim.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  // ============================================================================
  // CHARGEMENT INITIAL
  // ============================================================================
  Future<void> _loadInitial() async {
    await _refreshLengthFilter();

    // 1) Essai avec la catégorie active
    Dua? d = await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: _activeCategory,
    );

    // 2) Fallback si rien → ignorer catégorie
    d ??= await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: 'all',
    );

    if (d != null) {
      _currentId = d.id;
      _currentDuaText = d.text;
      _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
      if (mounted) setState(() {});
      _anim.forward(from: 0);
    }

    // Prépare déjà le deck (catégorie + longueur) en excluant l’id courant
    await _rebuildDeckFiltered(excludeId: _currentId);
  }

  Future<void> _refreshLengthFilter() async {
    _lengthFilter = await UserPrefs.instance.getLengthFilter();
  }

  // ============================================================================
  // RECONSTRUIRE LE DECK (catégorie active + longueur) avec fallback
  // ============================================================================
  Future<void> _rebuildDeckFiltered({int? excludeId}) async {
    await _refreshLengthFilter();

    // Liste filtrée length + category
    List<Dua> list = await _repo.loadFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: _activeCategory,
    );

    // Fallback si vide → ignorer la catégorie
    if (list.isEmpty) {
      list = await _repo.loadFiltered(
        lengthFilter: _lengthFilter,
        categoryFilter: 'all',
      );
    }

    _deckIds
      ..clear()
      ..addAll(list.map((d) => d.id));

    if (excludeId != null) {
      _deckIds.remove(excludeId);
    }

    _deckIds.shuffle();
    _deckCursor = 0;
  }

  // ============================================================================
  // AFFICHER PROCHAIN DANS LE DECK (anti-répétition)
  // ============================================================================
  Future<void> _showNextFromDeck() async {
    if (_deckIds.isEmpty || _deckCursor >= _deckIds.length) {
      await _rebuildDeckFiltered(excludeId: _currentId);
    }
    if (_deckIds.isEmpty) {
      await _loadRandomDua(ignoreCategory: true);
      return;
    }

    if (_deckCursor >= _deckIds.length) _deckCursor = 0;

    final id = _deckIds[_deckCursor];
    _deckCursor = (_deckCursor + 1) % _deckIds.length;

    final d = await _repo.getById(id);
    if (d != null) {
      _currentId = d.id;
      _currentDuaText = d.text;
      _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
      if (mounted) setState(() {});
      _anim.forward(from: 0);
    } else {
      await _loadRandomDua(ignoreCategory: true);
    }
  }

  // ============================================================================
  // TIRAGE ALÉATOIRE (respecte la cat, fallback “all”)
  // ============================================================================
  Future<void> _loadRandomDua({bool ignoreCategory = false}) async {
    await _refreshLengthFilter();

    Dua? d;
    if (!ignoreCategory) {
      d = await _repo.getRandomDuaFiltered(
        lengthFilter: _lengthFilter,
        categoryFilter: _activeCategory,
      );
    }
    d ??= await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: 'all',
    );

    if (d != null) {
      _currentId = d.id;
      _currentDuaText = d.text;
      _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
      if (mounted) setState(() {});
      _anim.forward(from: 0);
    } else {
      final all = await _repo.getAllDuas();
      if (all.isNotEmpty) {
        _currentId = all.first.id;
        _currentDuaText = all.first.text;
        _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
        if (mounted) setState(() {});
        _anim.forward(from: 0);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد أدعية متاحة. تحقق من ملف JSON.')),
        );
      }
    }
  }

  // ============================================================================
  // Sélection catégorie (boutons)
  // ============================================================================
  Future<void> _setCategory(String cat) async {
    if (_activeCategory == cat) {
      await _loadRandomDua(); // refresh simple
      return;
    }

    setState(() => _activeCategory = cat);

    // Reset deck
    _deckIds.clear();
    _deckCursor = 0;

    // Recrée deck filtré puis affiche
    await _rebuildDeckFiltered(excludeId: _currentId);
    if (_deckIds.isNotEmpty) {
      await _showNextFromDeck();
    } else {
      await _loadRandomDua(ignoreCategory: true);
    }
  }

  // ============================================================================
  // Copier / Partager (texte)
  // ============================================================================
  void _copyDua() {
    Clipboard.setData(ClipboardData(text: _currentDuaText));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ ✓', style: TextStyle(fontFamily: 'Lateef')),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareDuaText() {
    Share.share(_currentDuaText);
  }

  // ============================================================================
  // Partage image (Option A : gradient inline, comme ta version actuelle)
  // ============================================================================
  Future<Uint8List?> _captureImage() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final ctx = _imageKey.currentContext;
      if (ctx == null) return null;
      final ro = ctx.findRenderObject();
      if (ro is! RenderRepaintBoundary) return null;

      int tries = 0;
      while (ro.debugNeedsPaint && tries < 5) {
        await Future.delayed(const Duration(milliseconds: 16));
        await WidgetsBinding.instance.endOfFrame;
        tries++;
      }

      final ui.Image image = await ro.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('Erreur capture: $e\n$st');
      return null;
    }
  }

  Future<void> shareAsImage() async {
    final data = await _captureImage();
    if (data == null) return;
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/dua_share.png');
    await file.writeAsBytes(data);
    await Share.shareXFiles([XFile(file.path)],
        text: 'دعاء جميل من تطبيق أدعية لوالديَّ');
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          // -------------------------------------------------------------------
          // RepaintBoundary invisible (export image) — Option A (gradient inline)
          // -------------------------------------------------------------------
          IgnorePointer(
            child: Opacity(
              opacity: 0.01,
              child: Center(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: SizedBox(
                    width: 1080,
                    height: 1350,
                    child: Container(
                      padding: const EdgeInsets.all(50),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0A0F14), Color(0xFF1F4037)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          // Le texte sera mis à jour via _currentDuaText sur la carte principale
                          // (ici, l'image exportée peut être déclenchée après setState)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // UI principale (dégradé de fond + Scaffold)
          // -------------------------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF006A4E),
                  Color(0xFF009F6B),
                  Color(0xFF25C4A5),
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text(
                  'أدعية لوالديَّ',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Lateef',
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (v) {
                      if (v == 'search') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      } else if (v == 'favorites') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        );
                      } else if (v == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'search', child: Text('البحث')),
                      PopupMenuItem(value: 'favorites', child: Text('المفضلة')),
                      PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
                    ],
                  ),
                ],
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Boutons catégories
                      Row(
                        children: [
                          Expanded(
                            child: _buildCategoryButton(
                              keyCat: 'normal',
                              label: 'عام',
                              isDark: isDark,
                              cs: cs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCategoryButton(
                              keyCat: 'friday',
                              label: 'دعاء الجمعة',
                              isDark: isDark,
                              cs: cs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCategoryButton(
                              keyCat: 'ramadan',
                              label: 'دعاء رمضان',
                              isDark: isDark,
                              cs: cs,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Carte principale (ancienne disposition restaurée)
                      Expanded(
                        child: SlideTransition(
                          position: _slide,
                          child: FadeTransition(
                            opacity: _fade,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // ─── Ligne du haut : "دعاء آخر" à droite ───
                                  Row(
                                    children: [
                                      const Spacer(),
                                      OutlinedButton(
                                        onPressed: _showNextFromDeck,
                                        child: const Text(
                                          'دعاء آخر',
                                          style: TextStyle(fontFamily: 'Lateef', fontSize: 22),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // ─── Texte (scrollable) ───
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Text(
                                        _currentDuaText,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Lateef',
                                          fontSize: 32,
                                          height: 1.7,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ─── Ligne du bas : ❤ à gauche + Copier/Partager à droite ───
                                  Row(
                                    children: [
                                      // ❤ coin bas gauche
                                      ScaleTransition(
                                        scale: _heartCtrl,
                                        child: InkWell(
                                          onTap: () async {
                                            if (_currentId == null) return;
                                            HapticFeedback.selectionClick();
                                            _heartCtrl.forward().then((_) => _heartCtrl.reverse());
                                            await UserPrefs.instance.toggleFavorite(_currentId!);
                                            _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
                                            if (mounted) setState(() {});
                                          },
                                          borderRadius: BorderRadius.circular(30),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: theme.cardColor.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(30),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                                              color: _isFavorite
                                                  ? Colors.redAccent
                                                  : cs.onSurface.withOpacity(0.7),
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const Spacer(),

                                      // Copier & Partager (style inversé selon thème)
                                      if (!isDark) ...[
                                        OutlinedButton.icon(
                                          onPressed: _copyDua,
                                          icon: Icon(Icons.copy, color: cs.onSurface),
                                          label: Text(
                                            'نسخ',
                                            style: TextStyle(
                                              fontFamily: 'Lateef',
                                              fontSize: 20,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: cs.onSurface, width: 1.6),
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: _shareDuaText,
                                          icon: Icon(Icons.share, color: cs.onSurface),
                                          label: Text(
                                            'مشاركة',
                                            style: TextStyle(
                                              fontFamily: 'Lateef',
                                              fontSize: 20,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: cs.onSurface, width: 1.6),
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        ElevatedButton.icon(
                                          onPressed: _copyDua,
                                          icon: Icon(Icons.copy, color: cs.surface),
                                          label: Text(
                                            'نسخ',
                                            style: TextStyle(
                                              fontFamily: 'Lateef',
                                              fontSize: 20,
                                              color: cs.surface,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cs.onSurface,
                                            foregroundColor: cs.surface,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: _shareDuaText,
                                          icon: Icon(Icons.share, color: cs.surface),
                                          label: Text(
                                            'مشاركة',
                                            style: TextStyle(
                                              fontFamily: 'Lateef',
                                              fontSize: 20,
                                              color: cs.surface,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cs.onSurface,
                                            foregroundColor: cs.surface,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 1,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Bas d’écran : partage image (conserve ton CTA existant si tu veux)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: shareAsImage,
                          icon: const Icon(Icons.image, size: 24),
                          label: const Text('مشاركة كصورة',
                              style: TextStyle(fontFamily: 'Lateef', fontSize: 22)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Bouton de catégorie (عام / الجمعة / رمضان) — mêmes styles que ta version
  // ============================================================================
  Widget _buildCategoryButton({
    required String keyCat,
    required String label,
    required bool isDark,
    required ColorScheme cs,
  }) {
    final bool isActive = _activeCategory == keyCat;

    if (isActive) {
      return ElevatedButton(
        onPressed: () => _setCategory(keyCat),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white.withOpacity(0.22) : Colors.white,
          foregroundColor: isDark ? cs.onSurface : Colors.teal.shade800,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Lateef', fontSize: 22)),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _setCategory(keyCat),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.18),
          side: BorderSide(
            color: isDark ? Colors.black.withOpacity(0.60) : Colors.white,
            width: 2,
          ),
          foregroundColor: isDark ? cs.onSurface : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Lateef', fontSize: 22)),
      );
    }
  }
}