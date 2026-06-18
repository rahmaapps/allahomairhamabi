import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard + Haptics
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'models/person_type.dart';
import 'user_prefs.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'screens/person_selection_screen.dart';
import 'widgets/islamic_pattern_painter.dart';
import 'widgets/islamic_bg_motif_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ===== Données courantes =====
  Map<String, String> personsData = {};
  final DuaRepository _repo = DuaRepository();
  String _currentDuaText = '...';
  int? _currentId;
  bool _isFavorite = false;

  bool get isGraveVisit => _activeCategory == 'grave_visit';

  String _getPersonWord() {
    switch (selectedPerson) {
      case PersonType.father:
        return 'أبي';
      case PersonType.mother:
        return 'أمي';
      case PersonType.parents:
        return 'والديّ';
      case PersonType.grandfather:
        return 'جدي';
      case PersonType.grandmother:
        return 'جدتي';
      case PersonType.brother:
        return 'أخي';
      case PersonType.sister:
        return 'أختي';
      case PersonType.son:
        return 'ابني';
      case PersonType.daughter:
        return 'ابنتي';
      case PersonType.husband:
        return 'زوجي';
      case PersonType.wife:
        return 'زوجتي';
    }
  }

  //Suffixe des textes copiés ou partagés
  static const String _ATTR_SUFFIX_AR =
      '\n\n— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —';

  // Lien public de l'application (remplace par l'URL finale Play Store / AppGallery / site)
  static const String _APP_LINK =
      'https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi';

// Message court pour partager l'app (WhatsApp / autres)
  static const String _APP_SHARE_TEXT =
      'شارك الأجر – أرسل التطبيق لأهلك:\n$_APP_LINK';

  // ===== Filtres =====
  String _activeCategory = 'normal'; // 'normal' | 'friday' | 'grave_visit'
  String _lengthFilter = 'all'; // 'all' | 'short' | 'long'

  PersonType selectedPerson =
      PersonType.father; //variables dédié à la selection des personnes

  // ===== Deck anti-répétition =====
  final List<int> _deckIds = <int>[];
  int _deckCursor = 0;

  // ===== Animations =====
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _heartCtrl;

  // ===== Capture image (Option A – gradient inline, désactivée côté bouton) =====
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
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
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

  // ===========================================================================
  // CHARGEMENT INITIAL
  // ===========================================================================

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      // Ouvre la popup native d'évaluation
      await inAppReview.requestReview();
      return;
    } else {
      // Ouvre la page Play Store (après publication officielle)
      await inAppReview.openStoreListing(
        appStoreId: null, // pas utilisé sur Android
      );
    }
  }

  Future<String> _applyNameToDua(String text) async {
    final name = await UserPrefs.getPersonName();

    if (name == null || name.isEmpty) {
      return text;
    }

    final personWord = _getPersonWord();

    // remplace uniquement le mot (ex: أمي → أمي فاطمة)
    return text.replaceAll(personWord, '$personWord $name');
  }

  String _getPersonWithName(PersonType person) {
    final name = personsData[person.name];

    String word;

    switch (person) {
      case PersonType.father:
        word = 'أبي';
        break;
      case PersonType.mother:
        word = 'أمي';
        break;
      case PersonType.parents:
        word = 'والديّ';
        break;
      case PersonType.grandfather:
        word = 'جدي';
        break;
      case PersonType.grandmother:
        word = 'جدتي';
        break;
      case PersonType.brother:
        word = 'أخي';
        break;
      case PersonType.sister:
        word = 'أختي';
        break;
      case PersonType.son:
        word = 'ابني';
        break;
      case PersonType.daughter:
        word = 'ابنتي';
        break;
      case PersonType.husband:
        word = 'زوجي';
        break;
      case PersonType.wife:
        word = 'زوجتي';
        break;
    }

    if (name != null && name.isNotEmpty) {
      return '$word $name';
    }

    return word;
  }

  Future<String> _generateDuaForSelectedPersons(Dua baseDua) async {
    final persons = personsData.keys.toList();

    // ✅ aucun choix → fallback normal
    if (persons.isEmpty) {
      return baseDua.text;
    }

    // ✅ choisir une personne aléatoire
    final randomPersonKey = persons[math.Random().nextInt(persons.length)];

    final personEnum = PersonType.values.firstWhere(
      (p) => p.name == randomPersonKey,
    );

    final personWithName = _getPersonWithName(personEnum);

    String text = baseDua.text;

    // ✅ remplacement intelligent
    text = text
        .replaceAll('والدي', personWithName)
        .replaceAll('أبي', personWithName);

    return text;
  }

  Future<String> _generateDua(Dua d) async {
    if (personsData.isEmpty) {
      return d.text;
    }

    final persons = personsData.keys.toList();

    // choisir une personne aléatoire
    final randomKey = persons[math.Random().nextInt(persons.length)];

    final personEnum = PersonType.values.firstWhere(
      (p) => p.name == randomKey,
    );

    final name = personsData[randomKey];

    String word;

    switch (personEnum) {
      case PersonType.father:
        word = 'أبي';
        break;
      case PersonType.mother:
        word = 'أمي';
        break;
      case PersonType.parents:
        word = 'والديّ';
        break;
      case PersonType.grandfather:
        word = 'جدي';
        break;
      case PersonType.grandmother:
        word = 'جدتي';
        break;
      case PersonType.brother:
        word = 'أخي';
        break;
      case PersonType.sister:
        word = 'أختي';
        break;
      case PersonType.son:
        word = 'ابني';
        break;
      case PersonType.daughter:
        word = 'ابنتي';
        break;
      case PersonType.husband:
        word = 'زوجي';
        break;
      case PersonType.wife:
        word = 'زوجتي';
        break;
    }

    final full = name != null && name.isNotEmpty ? '$word $name' : word;

    String text = d.text;

    // remplacement principal
    text = text.replaceAll('والدي', full);

    return text;
  }

  Future<void> _loadInitial() async {
    await _refreshLengthFilter();

    // ✅ définir catégorie par défaut
    _activeCategory ??= 'normal';
    personsData = await UserPrefs.getPersonsData();


    // 1) Essai avec la catégorie active
    Dua? d = await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: _activeCategory,
    );

    // 2) Fallback : ignorer la catégorie si rien
    d ??= await _repo.getRandomDuaFiltered(
      lengthFilter: _lengthFilter,
      categoryFilter: 'all',
    );

    if (d != null) {
      _currentId = d.id;

      final persons = personsData.keys.toList();

      if (persons.isEmpty) {
        _currentDuaText = d.text;
      } else {
        final randomPerson = persons[math.Random().nextInt(persons.length)];

        final personEnum = PersonType.values.firstWhere(
          (p) => p.name == randomPerson,
        );

        final personText = _getPersonWithName(personEnum);

        if (personsData.isEmpty) {
          _currentDuaText = d.text;
        } else {
          final persons = personsData.keys.toList();

          final randomKey = persons[math.Random().nextInt(persons.length)];

          final name = personsData[randomKey];

          String word;

          switch (randomKey) {
            case 'father':
              word = 'أبي';
              break;
            case 'mother':
              word = 'أمي';
              break;
            case 'parents':
              word = 'والديّ';
              break;
            case 'grandfather':
              word = 'جدي';
              break;
            case 'grandmother':
              word = 'جدتي';
              break;
            case 'brother':
              word = 'أخي';
              break;
            case 'sister':
              word = 'أختي';
              break;
            case 'son':
              word = 'ابني';
              break;
            case 'daughter':
              word = 'ابنتي';
              break;
            case 'husband':
              word = 'زوجي';
              break;
            case 'wife':
              word = 'زوجتي';
              break;
            default:
              word = 'أبي';
          }

          final personText =
              (name != null && name.isNotEmpty) ? '$word $name' : word;

          _currentDuaText = d.text
              .replaceAll('والدي', personText)
              .replaceAll('أبي', personText);
        }
      }

      _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
      if (mounted) setState(() {});
      _anim.forward(from: 0);
    }

    // Préparer le deck filtré (en évitant de répéter le dou‘a courant)
    await _rebuildDeckFiltered(excludeId: _currentId);
  }

  Future<void> _refreshLengthFilter() async {
    _lengthFilter =
        await UserPrefs.instance.getLengthFilter(); // 'all' | 'short' | 'long'
  }

  // ===========================================================================
  // RECONSTRUIRE LE DECK (longueur + catégorie) AVEC FALLBACK “all”
  // ===========================================================================

  // ===========================================================================
  // TIRAGE ALÉATOIRE (respecte la cat ; fallback “all”)
  Future<void> _loadRandomDua({bool ignoreCategory = false}) async {
    await _refreshLengthFilter();

    try {
      // ✅ Charger le JSON complet
      final data = await _repo.getFullJson();
      // ⚠️ (si tu n’as pas cette méthode encore, on l’ajoutera après)

      // ✅ choisir une personne d'abord

      final persons = personsData.isEmpty
          ? ['general']   // ✅ FORCER GENERAL
          : personsData.keys.toList();

      final randomKey = persons[math.Random().nextInt(persons.length)];

    // ✅ récupérer les douaa de CETTE personne uniquement
      final list = data[randomKey]?[_activeCategory] ?? [];

    // fallback
      final finalList = list.isNotEmpty
          ? list
          : data[randomKey]?['normal'] ?? [];

    // sécurité
      if (finalList.isEmpty) {
        _currentDuaText = "لا يوجد دعاء حالياً";
        if (mounted) setState(() {});
        return;
      }

      // ✅ tirage correct
      final random = finalList[math.Random().nextInt(finalList.length)];
      String text = random['text'];

      // ✅ appliquer nom + personne
      final name = personsData[randomKey];

      if (name != null && name.isNotEmpty) {

        String baseWord;

        switch (randomKey) {
          case 'father': baseWord = 'أبي'; break;
          case 'mother': baseWord = 'أمي'; break;
          case 'brother': baseWord = 'أخي'; break;
          case 'sister': baseWord = 'أختي'; break;
          case 'son': baseWord = 'ابني'; break;
          case 'daughter': baseWord = 'ابنتي'; break;
          case 'husband': baseWord = 'زوجي'; break;
          case 'wife': baseWord = 'زوجتي'; break;
          default: baseWord = 'أبي';
        }

        final personText = '$baseWord $name';

        // ✅ normalisation
        text = text
            .replaceAll('والدي', 'أبي')
            .replaceAll('لأخي', 'أخي')
            .replaceAll('لأبي', 'أبي')
            .replaceAll('عن أخي', 'أخي');

        // ✅ إزالة أي اسم قديم
        text = text.replaceAll(RegExp('$baseWord\\s+\\w+'), baseWord);

        // ✅ إضافة الاسم
        text = text.replaceFirst(baseWord, personText);
      }

      // ✅ update UI
      _currentDuaText = text;
      _currentId = DateTime.now().millisecondsSinceEpoch;

      if (mounted) setState(() {});
      _anim.forward(from: 0);

    } catch (e) {
      print("❌ ERREUR: $e");

      _currentDuaText = "حدث خطأ أثناء تحميل الدعاء";
      if (mounted) setState(() {});
    }
  }

  Future<void> _setCategory(String cat) async {
    // si on reclique sur la même catégorie → juste rafraîchir
    if (_activeCategory == cat) {
      await _loadRandomDua();
      return;
    }

    // passer à la nouvelle catégorie
    setState(() => _activeCategory = cat);

    // vider l’ancien deck
    _deckIds.clear();
    _deckCursor = 0;

    // reconstruire le deck (length + cat) puis afficher
    await _rebuildDeckFiltered(excludeId: _currentId);

    if (_deckIds.isNotEmpty) {
      await _showNextFromDeck();
    } else {
      // fallback si la cat ne renvoie rien (on ignore la catégorie)
      await _loadRandomDua(ignoreCategory: true);
    }
  }

  // ===========================================================================
  // Copier / Partager (texte)
  // ===========================================================================

  void _copyDua() {
    if (_currentDuaText.isEmpty) return;

    final textToCopy = '$_currentDuaText$_ATTR_SUFFIX_AR';

    Clipboard.setData(ClipboardData(text: textToCopy));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ ✓'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareDuaText() {
    if (_currentDuaText.isEmpty) return;
    final textToShare = '$_currentDuaText$_ATTR_SUFFIX_AR';

    Share.share(
      textToShare,
      subject: 'دعاء', // objet utilisé par certaines apps (ex: email)
    );
  }

  Future<void> _shareAppOnWhatsApp() async {
    final text = _APP_SHARE_TEXT;

    // Encodage URL pour WhatsApp
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');

    // Si WhatsApp n'est pas installé, on propose un fallback (lien web)
    if (!await canLaunchUrl(uri)) {
      // Fallback: partage générique via le ShareSheet (optionnel) ou simple Snack
      // Ici, on affiche un message amical.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'يبدو أن واتساب غير مُثبت. يمكنك مشاركة هذا الرابط يدويًا.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ===========================================================================
  // Partage en image : désactivé pour cette version (message “bientôt”)
  // ===========================================================================
  void _shareImageSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('ميزة مشاركة الدعاء كصورة ستكون جاهزة قريباً إن شاء الله'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // (si tu veux garder la capture prête)
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

  Future<void> _rebuildDeckFiltered({int? excludeId}) async {

    // ✅ DEBUG ICI (1ère ligne)
    print("INSIDE rebuild personsData: $personsData");

    await _refreshLengthFilter();

    // 1) strict : longueur + catégorie
    List<Dua> list = [];

    if (personsData.isEmpty || personsData.keys.isEmpty) {

      print("✅ USING GENERAL ONLY");

      final data = await _repo.getFullJson();

      final generalList =
          data['general']?[_activeCategory] ??
              data['general']?['normal'] ??
              [];

      list = generalList.map<Dua>((e) {
        return Dua.fromJson(Map<String, dynamic>.from(e));
      }).toList();

      // ✅ TRÈS IMPORTANT : STOP ICI
      _deckIds
        ..clear()
        ..addAll(list.map((d) => d.id));

      _deckCursor = 0;

      debugPrint('[DECK] GENERAL ONLY -> ids=${_deckIds.length}');

      return; // 🚨 BLOQUE TOUTE AUTRE LOGIQUE
    }

    // 2) fallback : ignorer la catégorie si liste vide
    if (list.isEmpty) {
      list = await _repo.loadFiltered(
        lengthFilter: _lengthFilter,
        categoryFilter: 'all',
      );
    }

    _deckIds
      ..clear()
      ..addAll(list.map((d) => d.id));

    // éviter répétition immédiate
    if (excludeId != null && _deckIds.length > 1) {
      _deckIds.remove(excludeId);
    }

    _deckIds.shuffle();
    _deckCursor = 0;

    debugPrint(
        '[DECK] cat=$_activeCategory len=$_lengthFilter -> ids=${_deckIds.length}');
  }

  Future<void> _showNextFromDeck() async {

    if (personsData.isEmpty) {
      print("⚠️ force rebuild (no persons)");
      _deckIds.clear();
    }
    // recréer deck si vide
    if (_deckIds.isEmpty ||
        _deckCursor >= _deckIds.length ||
        personsData.isEmpty)   // ✅ AJOUT CRITIQUE
    {
      await _rebuildDeckFiltered(excludeId: _currentId);
    }

    // encore vide ? fallback
    if (_deckIds.isEmpty) {
      await _loadRandomDua(ignoreCategory: true);
      return;
    }

    if (_deckCursor >= _deckIds.length) _deckCursor = 0;

    final id = _deckIds[_deckCursor];
    _deckCursor = (_deckCursor + 1) % _deckIds.length;

    final d = await _repo.getById(id);
    if (d == null) {
      print("⚠️ Aucun douaa trouvé !");
      await _loadRandomDua(ignoreCategory: true);
      return;
    }

    _currentId = d.id;

    final persons = personsData.keys.toList();

    if (persons.isEmpty) {
      _currentDuaText = d.text;
    } else {
      final randomPerson = persons[math.Random().nextInt(persons.length)];

      final personEnum = PersonType.values.firstWhere(
        (p) => p.name == randomPerson,
      );

      final personText = _getPersonWithName(personEnum);

      if (personsData.isEmpty) {
        _currentDuaText = d.text;
      } else {
        final persons = personsData.keys.toList();

        final randomKey = persons[math.Random().nextInt(persons.length)];

        final name = personsData[randomKey];

        String word;

        switch (randomKey) {
          case 'father':
            word = 'أبي';
            break;
          case 'mother':
            word = 'أمي';
            break;
          case 'parents':
            word = 'والديّ';
            break;
          case 'grandfather':
            word = 'جدي';
            break;
          case 'grandmother':
            word = 'جدتي';
            break;
          case 'brother':
            word = 'أخي';
            break;
          case 'sister':
            word = 'أختي';
            break;
          case 'son':
            word = 'ابني';
            break;
          case 'daughter':
            word = 'ابنتي';
            break;
          case 'husband':
            word = 'زوجي';
            break;
          case 'wife':
            word = 'زوجتي';
            break;
          default:
            word = 'أبي';
        }

        final personText =
            (name != null && name.isNotEmpty) ? '$word $name' : word;

        _currentDuaText = d.text
            .replaceAll('والدي', personText)
            .replaceAll('أبي', personText);
      }
    }

    _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);

    if (mounted) setState(() {});
    _anim.forward(from: 0);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          // ---- RepaintBoundary invisible (image export) - Option A ----
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
                        children: [
                          Text(
                            _currentDuaText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lateef',
                              fontSize: 58,
                              color: Colors.white,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 50),
                          const Text(
                            '— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

// === ARRIÈRE‑PLAN GLOBAL : Dégradé vert + Motif islamique + Scaffold ===

              // 1) Ton fond dégradé existant (inchangé)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF006A4E), // vert profond
                      Color(0xFF009F6B), // vert moyen
                      Color(0xFF25C4A5), // vert clair
                    ],
                  ),
                ),
              ),

              // 2) Le motif islamique en filigrane (au-dessus du dégradé)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: IslamicBgMotifPainter(
// Valeurs “or un peu plus visible”
                      // Tu peux affiner ensuite sans redémarrer (Hot Reload OK pour ces params)
                      grid: 104,
                      starRadius: 24,
                      strokeOpacity: 0.2,
                      fillOpacity: 0.07,
                      strokeWidth: 1.1,
                      phase: const Offset(28, 14),
                      // ink: Color(0xFFB8860B), // (optionnel, déjà par défaut
                    ),
                  ),
                ),
              ),

              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: const Text(
                    'اللَّهُمَّ ارْحَمْ أَمْوَاتَنَا',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
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
                          MaterialPageRoute(
                              builder: (_) => const FavoritesScreen()),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (v) {
                        if (v == 'search') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SearchScreen()));
                        } else if (v == 'favorites') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen()));
                        } else if (v == 'settings') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'search', child: Text('البحث')),
                        PopupMenuItem(
                            value: 'favorites', child: Text('المفضلة')),
                        PopupMenuItem(
                            value: 'settings', child: Text('الإعدادات')),
                      ],
                    ),
                  ],
                ),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ---- Boutons catégories ----
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
                                keyCat: 'grave_visit',
                                label: 'دعاء زيارة القبر',
                                isDark: isDark,
                                cs: cs,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PersonSelectionScreen(),
                                ),
                              ).then((_) async {
                                final newPersonsData = await UserPrefs.getPersonsData();

                                // ✅ DEBUG
                                print("personsData: $newPersonsData");

                                // ✅ TRÈS IMPORTANT : mettre à jour le state + reset deck
                                setState(() {
                                  personsData = newPersonsData;

                                  // 🔥 CRITIQUE : reset du deck
                                  _deckIds.clear();
                                  _deckCursor = 0;
                                });

                                // ✅ rebuild avec NOUVEAU state
                                await _rebuildDeckFiltered(excludeId: _currentId);

                                if (_deckIds.isNotEmpty) {
                                  await _showNextFromDeck();
                                } else {
                                  await _loadRandomDua();
                                }
                              });
                            },
                            icon: const Icon(Icons.people_alt_rounded, size: 18),
                            label: const Text(
                              'اختيار الأشخاص الذين تريد الدعاء لهم',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Lateef',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.18),
                              foregroundColor: Colors.white,

                              side: BorderSide(
                                color: const Color(0xFFD4AF37).withOpacity(0.7),
                                width: 1.5,
                              ),

                              minimumSize: const Size(double.infinity, 36), // ✅ hauteur
                              padding: const EdgeInsets.symmetric(vertical: 6),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),

                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
// 🧾 CARTE PRINCIPALE — Doré Luxe (motif islamique + dégradé satiné)
// -----------------------------------------------------
                        Expanded(
                          child: SlideTransition(
                            position: _slide,
                            child: FadeTransition(
                              opacity: _fade,
                              child: Container(
                                // Ombre externe (relief de la carte)
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 12,
                                        offset: Offset(0, 4)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: CustomPaint(
                                    // Motif doré AU-DESSUS du contenu (toujours visible)

                                    foregroundPainter:
                                        IslamicGoldPatternPainter(
                                      isDark: isDark,
                                      onSurface: cs.onSurface,

                                      // Moins visible
                                      strokeOpacity: 0.10,
                                      // ↓ trait
                                      fillOpacity: 0.035,
                                      // ↓ aplat

                                      // Un peu plus espacé (moins dense)
                                      cell: 104,
                                      // 98–104 pour ton écran ; monte à 106 si tu veux encore plus d’air
                                      starRadius: 20,

                                      // Décalage (stagger)
                                      phaseX: 22,
                                      phaseY: 12,
                                      rowStagger:
                                          0.5, // 0.5 = décale d’une demi-cellule 1 ligne sur 2
                                    ),

                                    child: Container(
                                      // Dégradé de fond : ivoire (clair) / verre dépoli (sombre)
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isDark
                                              ? [
                                                  Colors.white
                                                      .withOpacity(0.07),
                                                  Colors.white
                                                      .withOpacity(0.05),
                                                ]
                                              : [
                                                  const Color(0xFFFFFBF1)
                                                      .withOpacity(
                                                          0.98), // ivoire doux
                                                  const Color(0xFFFFF6E7)
                                                      .withOpacity(
                                                          0.92), // ivoire satiné
                                                ],
                                        ),
                                        // Liseré doré ultra discret
                                        border: Border.all(
                                          color: const Color(0xFFB8860B)
                                              .withOpacity(
                                                  isDark ? 0.20 : 0.15),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Stack(
                                          children: [
                                            // --- Texte centré ---
                                            Center(
                                              child: isGraveVisit
                                                  ? SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.6,
                                                      child:
                                                          SingleChildScrollView(
                                                        physics:
                                                            const BouncingScrollPhysics(),
                                                        child: Text(
                                                          _currentDuaText,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Lateef',
                                                            fontSize: 32,
                                                            height: 1.7,
                                                            color: cs.onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : SingleChildScrollView(
                                                      physics:
                                                          const BouncingScrollPhysics(),
                                                      child: Text(
                                                        _currentDuaText,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: 'Lateef',
                                                          fontSize: 32,
                                                          height: 1.7,
                                                          color: cs.onSurface,
                                                        ),
                                                      ),
                                                    ),
                                            ),

                                            // --- Barre d’actions en bas (❤️ gauche, دعاء آخر droite) ---
                                            if (!isGraveVisit)
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 4,
                                                child: Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Row(
                                                    children: [
                                                      // ❤️ → gauche
                                                      ScaleTransition(
                                                        scale: _heartCtrl,
                                                        child: InkWell(
                                                          onTap: () async {
                                                            if (_currentId ==
                                                                null) return;
                                                            HapticFeedback
                                                                .selectionClick();
                                                            _heartCtrl
                                                                .forward()
                                                                .then((_) =>
                                                                    _heartCtrl
                                                                        .reverse());

                                                            await UserPrefs
                                                                .instance
                                                                .toggleFavorite(
                                                                    _currentId!);
                                                            if (_isFavorite) {
                                                              await UserPrefs
                                                                  .saveFavoriteText(
                                                                      _currentId!,
                                                                      _currentDuaText);
                                                            }

                                                            _isFavorite =
                                                                await UserPrefs
                                                                    .instance
                                                                    .isFavorite(
                                                                        _currentId!);
                                                            if (mounted)
                                                              setState(() {});
                                                          },
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              // pastille semi-transparente pour la lisibilité
                                                              color: Theme.of(
                                                                      context)
                                                                  .cardColor
                                                                  .withOpacity(
                                                                      isDark
                                                                          ? 0.85
                                                                          : 0.92),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black12,
                                                                  blurRadius: 6,
                                                                  offset:
                                                                      Offset(
                                                                          0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Icon(
                                                              _isFavorite
                                                                  ? Icons
                                                                      .favorite
                                                                  : Icons
                                                                      .favorite_border,
                                                              color: _isFavorite
                                                                  ? Colors
                                                                      .redAccent
                                                                  : cs.onSurface
                                                                      .withOpacity(
                                                                          0.7),
                                                              size: 26,
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      const Spacer(),

                                                      // "دعاء آخر" → droite (texte à gauche, icône à droite)
                                                      OutlinedButton(
                                                        onPressed:
                                                            _showNextFromDeck,
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          side: BorderSide(
                                                            color: const Color(
                                                                    0xFFB8860B)
                                                                .withOpacity(
                                                                    isDark
                                                                        ? 0.45
                                                                        : 0.35),
                                                            // doré discret
                                                            width: 1.8,
                                                          ),
                                                          backgroundColor: isDark
                                                              ? cs.surface
                                                                  .withOpacity(
                                                                      0.06)
                                                              : const Color(
                                                                      0xFFFFF6E7)
                                                                  .withOpacity(
                                                                      0.60),
                                                          foregroundColor:
                                                              cs.onSurface,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 8,
                                                                  horizontal:
                                                                      24),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: const [
                                                            Text('دعاء آخر',
                                                                style: TextStyle(
                                                                    fontFamily:
                                                                        'Lateef',
                                                                    fontSize:
                                                                        24)),
                                                            SizedBox(width: 8),
                                                            Icon(Icons
                                                                .skip_next_rounded),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // -----------------------------------------------------
// RANGÉE COPIER / PARTAGER (texte) — même visuel que les boutons catégories
// -----------------------------------------------------
                        if (!isGraveVisit)
                          Row(
                            children: [
                              // === COPIER ===
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: _copyDua,
                                  // ⚠️ on garde l'action active
                                  icon: Icon(
                                    Icons.copy,
                                    size: 18,
                                    // même teinte que les catégories inactives
                                    color: isDark ? cs.onSurface : Colors.white,
                                  ),
                                  label: const Text(
                                    'نسخ',
                                    style: TextStyle(
                                        fontFamily: 'Lateef', fontSize: 20),
                                  ),
                                  style: TextButton.styleFrom(
                                    // Visuel "non actif" (identique à tes catégories inactives)
                                    backgroundColor: isDark
                                        ? Colors.black.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.18),
                                    foregroundColor:
                                        isDark ? cs.onSurface : Colors.white,
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.60)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

// === PARTAGER (visuel non actif, mais onPressed actif) ===
                              if (!isGraveVisit)
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _shareDuaText,
                                    // ⚠️ on garde l'action active
                                    icon: Icon(
                                      Icons.share,
                                      size: 18,
                                      color:
                                          isDark ? cs.onSurface : Colors.white,
                                    ),
                                    label: const Text(
                                      'مشاركة',
                                      style: TextStyle(
                                          fontFamily: 'Lateef', fontSize: 18),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: isDark
                                          ? Colors.black.withOpacity(0.25)
                                          : Colors.white.withOpacity(0.18),
                                      foregroundColor:
                                          isDark ? cs.onSurface : Colors.white,
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.60)
                                            : Colors.white,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                        const SizedBox(height: 2),

                        // === Bouton WhatsApp : "شارك الأجر – أرسل التطبيق لأهلك" ===
                        if (!isGraveVisit)
                          Row(
                            children: [
                              // ✅ WhatsApp
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareAppOnWhatsApp,
                                  icon: FaIcon(FontAwesomeIcons.whatsapp,
                                      color: Colors.white, size: 18),
                                  label: const Text(
                                    'أرسل التطبيق لأهلك',
                                    style: TextStyle(
                                        fontFamily: 'Lateef', fontSize: 18),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E8449),
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // ✅ تقييم التطبيق
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _rateApp,
                                  icon: const Icon(Icons.star_rate_rounded,
                                      color: Colors.white, size: 20),
                                  label: const Text(
                                    'تقييم التطبيق',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E8449),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
              ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Boutons de catégorie (عام / الجمعة / رمضان)
  // ===========================================================================
  Widget _buildCategoryButton({
    required String keyCat,
    required String label,
    required bool isDark,
    required ColorScheme cs,
  }) {
    final bool isActive = _activeCategory == keyCat;

    final onPressed = () => _setCategory(keyCat); // ← IMPORTANT

    if (isActive) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? Colors.white.withOpacity(0.22) : Colors.white,
          foregroundColor: isDark ? cs.onSurface : Colors.teal.shade800,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontFamily: 'Lateef', fontSize: 20)),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? Colors.black.withOpacity(0.25)
              : Colors.white.withOpacity(0.18),
          side: BorderSide(
              color: isDark ? Colors.black.withOpacity(0.60) : Colors.white,
              width: 2),
          foregroundColor: isDark ? cs.onSurface : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontFamily: 'Lateef', fontSize: 20)),
      );
    }
  }
}

// (Option déco — conservée si tu la réutilises)
class IslamicHeaderPainter extends CustomPainter {
  const IslamicHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const double cellW = 90;
    const double cellH = 90;

    for (double y = 0; y < size.height; y += cellH) {
      for (double x = 0; x < size.width; x += cellW) {
        _drawStar(canvas, Offset(x + 40, y + 20), 28, stroke, fill);
      }
    }
  }

  void _drawStar(
      Canvas canvas, Offset center, double r, Paint stroke, Paint fill) {
    final path = Path();
    const int points = 16;
    final double step = (2 * math.pi) / points;
    final double start = math.pi / 8;

    for (int i = 0; i < points; i++) {
      final radius = (i % 2 == 0) ? r : r * .45;
      final double angle = start + i * step;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
