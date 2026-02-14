import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptic, Clipboard
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary
import 'package:share_plus/share_plus.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'user_prefs.dart';

import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

import 'premium_templates.dart';
import 'widgets/premium_export_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final DuaRepository _repo = DuaRepository();
  final Random _rand = Random();

  // État de l’écran
  Dua? _currentDua;                  // nullable: pas de late
  bool _isFavorite = false;

  // Filtres
  String _lengthFilter = "all";      // "all" | "short" | "long"
  String _categoryFilter = "normal"; // "normal" | "friday" | "ramadan"

  // Export Premium
  final GlobalKey _exportKey = GlobalKey();
  PremiumTemplate _selectedTemplate = PremiumTemplate.darkLuxe;
  static const String _exportFooter = "— من تطبيق أدعية لوالديَّ —";
  static const String _exportLogo   = "assets/premium/logo/app_logo_white.png";

  @override
  void initState() {
    super.initState();

    // Pré-charger les backgrounds premium pour éviter un flash noir à la 1ʳᵉ capture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final t in PremiumTemplate.values) {
        precacheImage(AssetImage(t.bgAsset), context);
      }
    });

    _loadInitial();
  }

  // ---------------------------------------------------------------------------
  // Chargement initial (avec fallbacks si nécessaire)
  // ---------------------------------------------------------------------------
  Future<void> _loadInitial() async {
    final prefs = UserPrefs.instance;

    // Charger la préférence de longueur
    _lengthFilter = await prefs.getLengthFilter();

    // 1) tentative avec la catégorie active
    Dua? dua = await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: _categoryFilter,
    );

    // 2) fallback: si rien, retenter sans contrainte de catégorie (on va chercher "quelque chose" au même length)
    dua ??= await _fallbackAnyByLength();

    if (dua != null) {
      _currentDua = dua;
      _isFavorite = await prefs.isFavorite(dua.id);
    }

    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Charger une autre dou‘a (avec fallbacks)
  // ---------------------------------------------------------------------------
  Future<void> _loadNextDua() async {
    HapticFeedback.lightImpact();

    final prefs = UserPrefs.instance;
    _lengthFilter = await prefs.getLengthFilter();

    // 1) tentative avec la catégorie active
    Dua? dua = await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: _categoryFilter,
    );

    // 2) fallback: si rien, retenter sans catégorie
    dua ??= await _fallbackAnyByLength();

    if (dua != null) {
      _currentDua = dua;
      _isFavorite = await prefs.isFavorite(dua.id);
    }

    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Fallback local: ignorer la catégorie et tenter "quelque chose" pour le length
  // ---------------------------------------------------------------------------
  Future<Dua?> _fallbackAnyByLength() async {
    final all = await _repo.getAllDuas();
    if (all.isEmpty) return null;

    List<Dua> pool;

    if (_lengthFilter == 'short') {
      pool = all.where((d) => d.length.trim() == 'قصيرة').toList();
    } else if (_lengthFilter == 'long') {
      pool = all.where((d) => d.length.trim() == 'طويلة').toList();
    } else {
      pool = all;
    }

    if (pool.isEmpty) {
      // En dernier recours: n'importe quelle entrée
      pool = all;
    }
    return pool[_rand.nextInt(pool.length)];
  }

  // ---------------------------------------------------------------------------
  // Toggle favoris (ID int)
  // ---------------------------------------------------------------------------
  Future<void> _toggleFavorite() async {
    final d = _currentDua;
    if (d == null) return;

    await UserPrefs.instance.toggleFavorite(d.id);
    HapticFeedback.mediumImpact();

    setState(() => _isFavorite = !_isFavorite);
  }

  // ---------------------------------------------------------------------------
  // Export premium: capture RepaintBoundary → PNG (pixelRatio 3.0)
  // ---------------------------------------------------------------------------
  Future<Uint8List?> _renderPremiumPng() async {
    await WidgetsBinding.instance.endOfFrame; // assure que tout est peint

    final boundary =
    _exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) return null;

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  Future<void> _sharePremiumImage() async {
    final pngBytes = await _renderPremiumPng();
    if (pngBytes == null) return;

    final file = XFile.fromData(
      pngBytes,
      name: "dua_premium.png",
      mimeType: "image/png",
    );

    await Share.shareXFiles([file]);
  }

  // ---------------------------------------------------------------------------
  // Copier / Partager le texte courant (dans la carte)
  // ---------------------------------------------------------------------------
  Future<void> _copyCurrentText() async {
    final txt = _currentDua?.text ?? '';
    if (txt.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: txt));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الدعاء')),
    );
  }

  Future<void> _shareCurrentText() async {
    final txt = _currentDua?.text ?? '';
    if (txt.isEmpty) return;
    await Share.share(txt, subject: 'دعاء');
  }

  // ---------------------------------------------------------------------------
  // Sélecteur de template (palette)
  // ---------------------------------------------------------------------------
  void _openTemplatePicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final items = PremiumTemplate.values;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (_, index) {
            final t = items[index];
            final selected = t == _selectedTemplate;

            return InkWell(
              onTap: () {
                setState(() => _selectedTemplate = t);
                Navigator.pop(context);
              },
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: AssetImage(t.thumbAsset),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        width: 2,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.all(8),
                    child: Text(
                      t.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sélecteur de catégorie (عام / الجمعة / رمضان)
  // ---------------------------------------------------------------------------
  Widget _categorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _catBtn("عام", "normal"),
        const SizedBox(width: 12),
        _catBtn("الجمعة", "friday"),
        const SizedBox(width: 12),
        _catBtn("رمضان", "ramadan"),
      ],
    );
  }

  Widget _catBtn(String label, String val) {
    final theme = Theme.of(context);
    final isSel = _categoryFilter == val;

    return GestureDetector(
      onTap: () {
        setState(() => _categoryFilter = val);
        _loadNextDua();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel
              ? theme.colorScheme.primary.withOpacity(0.9)
              : (theme.brightness == Brightness.dark
              ? Colors.white10
              : Colors.black12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : theme.colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: bouton Copier/Partager avec style inversé clair/sombre
  // ---------------------------------------------------------------------------
  Widget _themedActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("أدعية لوالديّ"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "اختيار القالب",
            icon: const Icon(Icons.palette_outlined),
            onPressed: _openTemplatePicker,
          ),
          IconButton(
            tooltip: "الإعدادات",
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          // Fond dégradé
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A4D2E), Color(0xFF26653E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Barre Catégories (عام / الجمعة / رمضان)
                  _categorySelector(),
                  const SizedBox(height: 16),

                  // Carte principale
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentDua == null
                          ? Column(
                        key: const ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('جارٍ التحميل...'),
                        ],
                      )
                          : _buildDuaCard(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bas d’écran : Image Premium / Favoris / Recherche
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sharePremiumImage,
                          icon: const Icon(Icons.photo),
                          label: const Text("صورة مميزة"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                            );
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text("المفضلة"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchScreen()),
                            );
                          },
                          icon: const Icon(Icons.search),
                          label: const Text("بحث"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Couche d’export invisible (RepaintBoundary)
          Offstage(
            offstage: true,
            child: RepaintBoundary(
              key: _exportKey,
              child: PremiumExportCard(
                template: _selectedTemplate,
                duaText: _currentDua?.text ?? "",
                footer: _exportFooter,
                logoAsset: _exportLogo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Carte dou‘a — ANCIENNE DISPOSITION :
  //  - "دعاء آخر" en haut à droite
  //  - ❤ en bas à gauche
  //  - Copier / Partager en bas à droite (style inversé clair/sombre)
  // ---------------------------------------------------------------------------
  Widget _buildDuaCard() {
    final theme = Theme.of(context);
    final d = _currentDua!;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      key: ValueKey(d.id),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Ligne du haut : "دعاء آخر" à droite
          Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: _loadNextDua,
                child: const Text("دعاء آخر"),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Zone texte
          Expanded(
            child: SingleChildScrollView(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  d.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lateef',
                    fontSize: 32,
                    height: 1.6,
                    color: onSurface,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Ligne du bas : ❤ à gauche + Copier/Partager à droite
          Row(
            children: [
              IconButton(
                tooltip: 'مفضلة',
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_outline,
                  color: _isFavorite ? Colors.red : onSurface,
                ),
                onPressed: _toggleFavorite,
              ),
              const Spacer(),
              _themedActionButton(
                context: context,
                label: 'نسخ',
                icon: Icons.copy,
                onPressed: _copyCurrentText,
              ),
              const SizedBox(width: 8),
              _themedActionButton(
                context: context,
                label: 'مشاركة',
                icon: Icons.share,
                onPressed: _shareCurrentText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}