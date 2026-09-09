import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard + Haptics
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'user_prefs.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'screens/person_selection_screen.dart';
import 'screens/grave_visit_read_screen.dart';
import 'premium_templates.dart';
import 'widgets/premium_export_card.dart';
import 'dua_personalizer.dart';
import 'theme/app_colors.dart';
import 'theme/app_radii.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'widgets/app_bar.dart';
import 'widgets/app_button.dart';
import 'widgets/app_card.dart';
import 'widgets/app_chip.dart';
import 'widgets/app_empty_state.dart';

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

  //Suffixe des textes copiés ou partagés
  static const String _ATTR_SUFFIX_AR =
      '\n\n— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —';

  // Lien public de l'application (remplace par l'URL finale Play Store / AppGallery / site)
  static const String _APP_LINK =
      'https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi';

// Message court pour partager l'app (WhatsApp / autres)
  static const String _APP_SHARE_TEXT =
      'شارك الأجر – أرسل التطبيق لأهلك:\n$_APP_LINK';

  // ===== Filtres =====
  // زيارة القبر a son propre écran dédié (LOT 3.F) — plus jamais atteint via
  // _activeCategory (ancien pont supprimé).
  String _activeCategory = 'normal'; // 'normal' | 'friday'
  String _lengthFilter = 'all'; // 'all' | 'short' | 'long'

  // ===== Deck anti-répétition =====
  final List<int> _deckIds = <int>[];
  int _deckCursor = 0;

  // ===== Animations =====
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _heartCtrl;

  // ===== Export Premium (carte-image partageable du dou'a affiché) =====
  // Une seule clé : décision produit V1.2 — toujours EXACTEMENT une image
  // partagée, quelle que soit la longueur du dou'a. PremiumExportCard
  // restreint elle-même le rendu Dark Luxe paginé à sa première page.
  final GlobalKey _exportKey = GlobalKey();
  PremiumTemplate _selectedTemplate = PremiumTemplate.darkLuxe;

  // Espace réservé en bas de la carte pour le pied (♡ + « دعاء آخر ») :
  // hauteur de AppButton (48, fixe — §3) + un espacement de respiration.
  // La zone de texte défilant s'arrête au-dessus, jamais derrière.
  static const double _cardFooterReservedHeight = 56;

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
    _loadSelectedTemplate();
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

  // Mécanisme d'évaluation prévu au MVP — conservé pour une intégration
  // dédiée ultérieure (non supprimé, décision produit antérieure à ce lot).
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

  // Source de vérité unique pour appliquer le prénom personnalisé au texte
  // d'un dou'a (V1.2). CONTRAIREMENT à l'ancienne version, la personne n'est
  // JAMAIS choisie au hasard : elle est déterminée par le personKey réel du
  // Dua affiché (dua.personKey), qui vient lui-même de sa position dans le
  // JSON. Logique pure déportée dans DuaPersonalizer (testable en isolation,
  // voir test/dua_personalizer_test.dart).
  String _personalizeDuaText(String baseText, String personKey) {
    return DuaPersonalizer.personalize(baseText, personKey, personsData);
  }

  Future<void> _loadInitial() async {
    await _refreshLengthFilter();

    personsData = await UserPrefs.getPersonsData();


    // 1) Essai avec la catégorie active, scindé par personnes sélectionnées
    Dua? d = await _repo.getRandomDuaFilteredForPersons(
      personKeys: personsData.keys.toList(),
      lengthFilter: _lengthFilter,
      categoryFilter: _activeCategory,
    );

    // 2) Fallback : ignorer la catégorie si rien (toujours scindé par personnes)
    d ??= await _repo.getRandomDuaFilteredForPersons(
      personKeys: personsData.keys.toList(),
      lengthFilter: _lengthFilter,
      categoryFilter: 'all',
    );

    if (d != null) {
      _currentId = d.id;
      _currentDuaText = _personalizeDuaText(d.text, d.personKey);

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

  /// Charge le template Partage Premium choisi lors d'une session
  /// précédente (§4 Partage Premium : « Persistée (share_template) »).
  /// Dark Luxe reste la valeur par défaut si aucune préférence n'existe
  /// ou si la valeur stockée ne correspond plus à un template connu.
  Future<void> _loadSelectedTemplate() async {
    final saved = await UserPrefs.instance.getShareTemplate();
    if (!mounted) return;
    setState(() => _selectedTemplate = _templateFromName(saved));
  }

  PremiumTemplate _templateFromName(String? name) {
    if (name == null) return PremiumTemplate.darkLuxe;
    return PremiumTemplate.values.firstWhere(
      (t) => t.name == name,
      orElse: () => PremiumTemplate.darkLuxe,
    );
  }

  // ===========================================================================
  // TIRAGE ALÉATOIRE (respecte la cat ; fallback “all”)
  Future<void> _loadRandomDua({bool ignoreCategory = false}) async {
    await _refreshLengthFilter();

    try {
      // ✅ Charger le JSON complet
      final data = await _repo.getFullJson();

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
      final String text = random['text'] as String;

      // ✅ update UI — personnalisation via la source de vérité unique
      // (basée sur randomKey, qui EST la personne réelle de ce tirage,
      // jamais un choix aléatoire distinct du dou'a affiché).
      _currentDuaText = _personalizeDuaText(text, randomKey);
      // ✅ id réel du dou'a (V1.2) — jamais un timestamp : un favori créé
      // à partir de ce repli doit pointer vers une entrée existante du JSON.
      _currentId = random['id'] as int;

      if (mounted) setState(() {});
      _anim.forward(from: 0);

    } catch (e) {
      debugPrint("❌ ERREUR: $e");

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
  // Export Premium : capture du RepaintBoundary (_exportKey) → PNG → partage
  // Toujours EXACTEMENT une image (décision produit V1.2), quelle que soit
  // la longueur du dou'a.
  // ===========================================================================
  Future<Uint8List?> _renderPremiumPng() async {
    try {
      await WidgetsBinding.instance.endOfFrame; // assure que tout est peint

      final boundary = _exportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // La fermeture animée du bottom sheet peut laisser le repaint en
      // attente sur plusieurs frames : un seul endOfFrame ne suffit pas
      // toujours. Retry borné.
      int tries = 0;
      while (boundary.debugNeedsPaint && tries < 5) {
        await Future.delayed(const Duration(milliseconds: 16));
        await WidgetsBinding.instance.endOfFrame;
        tries++;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('Erreur export Premium: $e\n$st');
      return null;
    }
  }

  /// Retourne `true` si l'image a été générée et remise au mécanisme de
  /// partage natif avec succès, `false` sinon — plus jamais un échec
  /// silencieux (§4 Partage Premium : « ne plus échouer silencieusement »,
  /// voir l'état échec dans `_openTemplatePicker`). La génération (rendu
  /// PNG) et le partage lui-même peuvent chacun échouer ; les deux sont
  /// couverts ici.
  Future<bool> _sharePremiumImage() async {
    final png = await _renderPremiumPng();
    if (png == null) return false;

    try {
      await Share.shareXFiles([
        XFile.fromData(png, name: 'dua_premium.png', mimeType: 'image/png'),
      ]);
      return true;
    } catch (e, st) {
      debugPrint('Erreur partage Premium: $e\n$st');
      return false;
    }
  }

  // Bottom sheet Partage Premium — 3 vignettes 74×104, poids strictement
  // égal, ordre RTL Dark Luxe → Emerald → White (§4 Partage Premium).
  // Sélection = 3 signaux simultanés : anneau 2px, pastille ✓, libellé 600.
  //
  // Flux (§4, alignement littéral) : la sélection d'une vignette PERSISTE
  // le template mais ne déclenche plus le partage — un bouton d'action
  // unique en bas de la feuille (« مشاركة كصورة ») lance ensuite la
  // génération/partage. `StatefulBuilder` local à la feuille, aucun nouvel
  // écran/composant séparé. Le bouton garde toujours sa taille (largeur
  // `double.infinity` + hauteur fixe 48 d'`AppButton`) ; seul son contenu
  // change (« جارٍ التحضير… » après 400 ms). La feuille se ferme
  // uniquement après succès du partage natif ; en cas d'échec elle reste
  // ouverte, la ligne d'erreur apparaît AU-DESSUS du bouton (§4), et le
  // bouton reste disponible pour réessayer. `sheetContext.mounted` évite
  // tout `setState`/`Navigator.pop` après fermeture manuelle de la
  // feuille pendant une génération en cours.
  void _openTemplatePicker() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
      ),
      builder: (sheetContext) {
        // Déclarées ici (portée du builder de la feuille, exécuté une
        // seule fois à l'ouverture) — PAS dans le builder de
        // `StatefulBuilder` ci-dessous, qui se ré-exécute à chaque
        // `setSheetState` et réinitialiserait ces variables sinon.
        bool busy = false;
        bool showPreparingLabel = false;
        String? errorMessage;
        Timer? prepTimer;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Sélection seule : persiste le template (§4 : « Persistée
            // (share_template) »), ne lance rien. `setSheetState` fait
            // réapparaître l'anneau/pastille sur la bonne vignette — la
            // feuille n'est pas un descendant de `HomeScreen` dans
            // l'arbre (route séparée du `Navigator`), un `setState`
            // externe seul ne la reconstruirait pas.
            void selectTemplate(PremiumTemplate t) {
              if (busy) return;
              setState(() => _selectedTemplate = t);
              unawaited(UserPrefs.instance.setShareTemplate(t.name));
              setSheetState(() {});
            }

            Future<void> handleSharePressed() async {
              if (busy) return;

              setSheetState(() {
                busy = true;
                showPreparingLabel = false;
                errorMessage = null;
              });

              // « جارٍ التحضير… » affiché seulement au-delà de 400 ms
              // (§4) — jamais pour un rendu quasi instantané.
              prepTimer = Timer(const Duration(milliseconds: 400), () {
                if (sheetContext.mounted) {
                  setSheetState(() => showPreparingLabel = true);
                }
              });

              final success = await _sharePremiumImage();
              prepTimer?.cancel();

              if (!sheetContext.mounted) return;

              if (success) {
                Navigator.pop(sheetContext);
              } else {
                setSheetState(() {
                  busy = false;
                  showPreparingLabel = false;
                  errorMessage = 'تعذّر تحضير الصورة، حاول مرة أخرى';
                });
              }
            }

            // `MediaQuery.viewPaddingOf` (jamais réduit par un `SafeArea`
            // ancêtre, contrairement à `.padding`) : garantit que le bouton
            // « مشاركة كصورة » reste entièrement visible au-dessus de la
            // barre de navigation système, quel que soit le comportement
            // réel de `useSafeArea` sur l'appareil — même correctif déjà
            // appliqué à la feuille دعاء زيارة القبر
            // (`_openGraveVisitPersonPicker`) suite à la même anomalie
            // constatée en test manuel (LOT 3.L).
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxl + MediaQuery.viewPaddingOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    textDirection: TextDirection.rtl,
                    children: PremiumTemplate.values.map((t) {
                      final selected = t == _selectedTemplate;

                      return GestureDetector(
                        onTap: () => selectTemplate(t),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 74,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadii.cardRadius,
                                    image: DecorationImage(
                                      image: AssetImage(t.thumbAsset),
                                      fit: BoxFit.cover,
                                    ),
                                    border: Border.all(
                                      width: selected ? 2 : 1,
                                      color: selected ? cs.primary : cs.outline,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Icon(Icons.check_circle,
                                        color: cs.primary, size: 18),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              t.displayName,
                              textDirection: TextDirection.rtl,
                              style: AppTypography.label.copyWith(
                                color: cs.onSurface,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // État échec (§4 : « une ligne d'erreur au-dessus du
                  // bouton ») — inline, aucun SnackBar/dialogue ; la
                  // feuille reste utilisable, le bouton permet de
                  // réessayer.
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.label.copyWith(color: cs.error),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  // Bouton d'action unique — taille fixe (largeur pleine +
                  // hauteur 48 d'AppButton) quel que soit son contenu ;
                  // seul le contenu change, jamais la taille (§4).
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      role: AppButtonRole.primary,
                      icon: showPreparingLabel ? null : Icons.ios_share,
                      label: showPreparingLabel ? 'جارٍ التحضير…' : 'مشاركة كصورة',
                      onPressed: busy ? null : handleSharePressed,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Bottom sheet دعاء زيارة القبر — choix explicite de la personne avant la
  // lecture (LOT 3.F). Réutilise exactement le motif déjà en place pour
  // Partage Premium (_openTemplatePicker) : showModalBottomSheet +
  // useSafeArea + showDragHandle + coin haut r-hero. Options strictement
  // limitées aux personnes déjà configurées (`personsData.keys`), jamais
  // les 11 `PersonType.values`. Aucune persistance, aucun champ prénom,
  // aucune multi-sélection, aucun badge `الحالي`, aucune snackbar — un tap
  // ferme la feuille et ouvre directement l'écran de lecture.
  void _openGraveVisitPersonPicker() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
      ),
      builder: (sheetContext) {
        // Aucune personne configurée : gabarit d'état vide existant
        // (`AppEmptyState`), jamais un nouvel état inventé (§3 « Composants
        // communs »). Le bandeau HOME reste visible dans tous les cas —
        // seul le contenu de la feuille change.
        if (personsData.isEmpty) {
          return SizedBox(
            height: 340,
            child: AppEmptyState(
              message: 'اختر الشخص الذي تريد قراءة الدعاء عند زيارة قبره',
              helper: 'لم تختر شخصًا بعد',
              buttonLabel: 'اختيار شخص',
              onButtonPressed: () async {
                Navigator.pop(sheetContext);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonSelectionScreen()),
                );
                // Retour normal au HOME depuis Person Selection — aucune
                // ouverture automatique de l'écran de lecture (LOT 3.F).
                // Recharge personsData (même correctif que
                // `_openPersonSelection`) : sans cela, une réouverture
                // immédiate de دعاء زيارة القبر retrouvait l'ancien
                // `personsData` en mémoire et réaffichait l'état vide malgré
                // la personne qui vient d'être cochée (anomalie constatée
                // en test manuel).
                final newPersonsData = await UserPrefs.getPersonsData();
                if (!mounted) return;
                setState(() => personsData = newPersonsData);
              },
            ),
          );
        }

        // `MediaQuery.viewPaddingOf` (jamais réduit par un `SafeArea`
        // ancêtre, contrairement à `.padding`) : garantit que la dernière
        // chip reste entièrement visible au-dessus de la barre de
        // navigation système, quel que soit le comportement réel de
        // `useSafeArea` sur l'appareil (anomalie constatée en test manuel).
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: personsData.keys.map((key) {
              return AppChip(
                variant: AppChipVariant.person,
                label: _possessivePersonLabel(key),
                selected: false,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GraveVisitReadScreen(personKey: key),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _rebuildDeckFiltered({int? excludeId}) async {

    // ✅ DEBUG ICI (1ère ligne)
    debugPrint("INSIDE rebuild personsData: $personsData");

    await _refreshLengthFilter();

    // Pool scindé par personnes sélectionnées (repli interne sur 'general'
    // si personsData est vide) et par catégorie active réelle — voir
    // DuaRepository.loadFilteredForPersons().
    final list = await _repo.loadFilteredForPersons(
      personKeys: personsData.keys.toList(),
      lengthFilter: _lengthFilter,
      categoryFilter: _activeCategory,
    );

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
        '[DECK] cat=$_activeCategory len=$_lengthFilter persons=${personsData.keys.toList()} -> ids=${_deckIds.length}');
  }

  Future<void> _showNextFromDeck() async {

    if (personsData.isEmpty) {
      debugPrint("⚠️ force rebuild (no persons)");
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
      debugPrint("⚠️ Aucun douaa trouvé !");
      await _loadRandomDua(ignoreCategory: true);
      return;
    }

    _currentId = d.id;
    _currentDuaText = _personalizeDuaText(d.text, d.personKey);

    _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);

    if (mounted) setState(() {});
    _anim.forward(from: 0);
  }

  // ===========================================================================
  // Sélection des personnes — ligne compacte (§2 décision #2 : « une ligne
  // de 20 dp, pas un bouton »). Callback de retour préservé à l'identique :
  // recharge personsData, réinitialise le deck, le reconstruit, puis montre
  // un dou'a cohérent avec la nouvelle sélection.
  // ===========================================================================
  Future<void> _openPersonSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonSelectionScreen()),
    );
    final newPersonsData = await UserPrefs.getPersonsData();

    setState(() {
      personsData = newPersonsData;
      _deckIds.clear();
      _deckCursor = 0;
    });

    await _rebuildDeckFiltered(excludeId: _currentId);

    if (_deckIds.isNotEmpty) {
      await _showNextFromDeck();
    } else {
      await _loadRandomDua();
    }
  }

  // ---------------------------------------------------------------------
  // Favoris — au retour de l'écran Favoris, le douʿā affiché sur HOME n'a
  // pas forcément changé mais son état favori a pu être modifié depuis
  // Favoris (retrait via ♥). Relit l'état réel persisté pour CE douʿā
  // précis (UserPrefs.instance.isFavorite, déjà utilisé partout ailleurs
  // dans ce fichier) plutôt que de supposer que ♥ est resté vrai.
  // ---------------------------------------------------------------------
  Future<void> _openFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
    if (!mounted || _currentId == null) return;

    final isFav = await UserPrefs.instance.isFavorite(_currentId!);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  /// Libellés possessifs déjà établis (`أبي`, `أمي`...) — repris tels
  /// quels, identiques à ceux de Person Selection, non redécidés ici.
  String _possessivePersonLabel(String personKey) {
    switch (personKey) {
      case 'father':
        return 'أبي';
      case 'mother':
        return 'أمي';
      case 'parents':
        return 'والديّ';
      case 'grandfather':
        return 'جدي';
      case 'grandmother':
        return 'جدتي';
      case 'brother':
        return 'أخي';
      case 'sister':
        return 'أختي';
      case 'son':
        return 'ابني';
      case 'daughter':
        return 'ابنتي';
      case 'husband':
        return 'زوجي';
      case 'wife':
        return 'زوجتي';
      default:
        return personKey;
    }
  }

  Widget _buildPersonsLine(ColorScheme cs, bool isDark) {
    final hasPersons = personsData.isNotEmpty;
    final String summary = !hasPersons
        ? 'ادعُ لمن تحب'
        : personsData.length == 1
            ? 'تدعو لـ ${_possessivePersonLabel(personsData.keys.first)}'
            : 'تدعو لـ ${personsData.length} أشخاص';
    final String action = hasPersons ? 'تغيير' : 'اختيار';
    final goldText = isDark ? AppColorsDark.gold : AppColorsLight.goldText;

    // Pas de hauteur fixe (auparavant SizedBox(height: 20)) : la hauteur de
    // ligne réelle de AppTypography.body/bodyStrong à 15px (~22-26dp selon
    // le facteur `height`) dépasse 20dp et rognait verticalement le texte
    // arabe (glyphes déformés). La ligne se dimensionne désormais à son
    // contenu ; les espacements 12dp au-dessus/en dessous (déjà en place
    // dans build()) portent le rythme vertical, pas une hauteur imposée ici.
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          summary,
          textDirection: TextDirection.rtl,
          style: AppTypography.body.copyWith(color: cs.onSurface),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: _openPersonSelection,
          child: Text(
            action,
            textDirection: TextDirection.rtl,
            style: AppTypography.bodyStrong.copyWith(color: goldText),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(ColorScheme cs, bool isDark) {
    return ScaleTransition(
      scale: _heartCtrl,
      child: InkWell(
        borderRadius: AppRadii.pillRadius,
        onTap: () async {
          if (_currentId == null) return;
          HapticFeedback.selectionClick();
          _heartCtrl.forward().then((_) => _heartCtrl.reverse());

          await UserPrefs.instance.toggleFavorite(_currentId!);
          if (_isFavorite) {
            await UserPrefs.saveFavoriteText(_currentId!, _currentDuaText);
          }

          _isFavorite = await UserPrefs.instance.isFavorite(_currentId!);
          if (mounted) setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: isDark ? 0.85 : 0.92),
            borderRadius: AppRadii.pillRadius,
          ),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? cs.error : cs.onSurface.withValues(alpha: 0.7),
            size: 26,
          ),
        ),
      ),
    );
  }

  /// Douʿā défilant à l'intérieur de la carte HOME — LOT 3.I.B : plus aucun
  /// fondu d'opacité en haut/bas (l'ancien `ShaderMask` + `LinearGradient`
  /// réduisait l'alpha réelle du texte religieux, cause confirmée par audit
  /// dédié). Coupure nette naturelle aux limites du scroll ; texte toujours
  /// pleinement opaque, typographie et scroll inchangés.
  Widget _fadingDuaScroll(ColorScheme cs) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Text(
        _currentDuaText,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: AppTypography.duaBody.copyWith(color: cs.onSurface),
      ),
    );
  }

  // Chrome interne d'un AppButton (§ widgets/app_button.dart) : padding
  // horizontal AppSpacing.xl de chaque côté (40) + icône 20 px + espace
  // AppSpacing.sm (8) avant le libellé = 68 px ne portant jamais de texte.
  static const double _kActionButtonChrome = 68;

  /// نسخ / مشاركة — paire horizontale par défaut ; bascule verticale si la
  /// largeur par action passe sous 132 dp, si le texte est agrandi
  /// (`textScaler` ≥ 1,3), ou si un libellé risque d'être tronqué à la
  /// largeur réellement mesurée (§2 « Comportement des catégories et des
  /// actions »). Règle vérifiée par mesure réelle (`TextPainter`), jamais
  /// par un point de rupture inventé. Réutilise `AppButton` tel quel.
  Widget _buildCopyShareActions() {
    final copyButton = AppButton(
      role: AppButtonRole.action,
      icon: Icons.copy,
      label: 'نسخ',
      onPressed: _copyDua,
    );
    final shareButton = AppButton(
      role: AppButtonRole.action,
      icon: Icons.share,
      label: 'مشاركة',
      onPressed: _shareDuaText,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthPerAction = (constraints.maxWidth - AppSpacing.md) / 2;
        final textScaler = MediaQuery.textScalerOf(context);
        final scaledButtonFontSize = textScaler.scale(AppTypography.button.fontSize!);
        final textScalerTooLarge =
            scaledButtonFontSize >= AppTypography.button.fontSize! * 1.3;

        final availableTextWidth = widthPerAction - _kActionButtonChrome;
        bool wouldTruncate(String label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: AppTypography.button),
            textDirection: TextDirection.rtl,
            textScaler: textScaler,
            maxLines: 1,
          )..layout();
          return painter.width > availableTextWidth;
        }

        final needsVertical = widthPerAction < 132 ||
            textScalerTooLarge ||
            wouldTruncate('نسخ') ||
            wouldTruncate('مشاركة');

        if (needsVertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copyButton,
              const SizedBox(height: AppSpacing.md),
              shareButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: copyButton),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: shareButton),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Couleur du texte/icônes de l'AppBar — jamais `cs.onPrimary` (pensé
    // pour du texte sur l'accent `primary`, quasi noir en Dark Mode et donc
    // illisible sur le fond réel `appBar`, également quasi noir en Dark).
    // Même lecture que celle déjà retenue pour AppVisitBandeau : ivoire fixe
    // par mode, alignée sur les tokens `onPrimary`(Light)/`textPrimary`(Dark)
    // déjà utilisés par AppBarTheme lui-même (LOT 1A).
    final appBarForeground = isDark ? AppColorsDark.textPrimary : AppColorsLight.onPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppTopBar(
              title: 'اللَّهُمَّ ارْحَمْ أَبِي',
              height: 56,
              titleStyle:
                  AppTypography.display.copyWith(fontSize: 25, color: appBarForeground),
              actions: [
                IconButton(
                  tooltip: 'البحث',
                  icon: Icon(Icons.search, color: appBarForeground),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  icon: Icon(Icons.favorite_border, color: appBarForeground),
                  onPressed: _openFavorites,
                ),
                // ⤴ Partage Premium : rendue seulement si un douʿā est
                // réellement affiché (§4 Partage Premium — « si aucun douʿā
                // n'est affiché, l'icône n'est pas rendue — jamais grisée »).
                // Absente du tableau `actions`, pas seulement désactivée.
                if (_currentId != null)
                  IconButton(
                    tooltip: 'مشاركة كصورة',
                    icon: Icon(Icons.ios_share, color: appBarForeground),
                    onPressed: _openTemplatePicker,
                  ),
                // ⋮ → الإعدادات directement (§1 carte de navigation :
                // « ⋮ → الإعدادات → Personnes / heure / thème / عن التطبيق »).
                // Aucun menu intermédiaire : pas de destination inventée ici.
                IconButton(
                  tooltip: 'الإعدادات',
                  icon: Icon(Icons.more_vert, color: appBarForeground),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
              bandeau: AppVisitBandeau(
                label: 'دعاء زيارة القبر',
                subtitle: 'للقراءة عند الزيارة',
                onTap: _openGraveVisitPersonPicker,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Chips catégories (2, 50% chacune) ----
                    Row(
                      children: [
                        Expanded(
                          child: AppChip(
                            label: 'عام',
                            selected: _activeCategory == 'normal',
                            onTap: () => _setCategory('normal'),
                          ),
                        ),
                        // Gap chips : le document indique 10 (§3
                        // Espacements) mais l'échelle base-4 qu'il fixe au
                        // même paragraphe l'exclut explicitement (« aucune
                        // autre valeur ... pas de 6, 10, 14, 18 »).
                        // Contradiction interne au document — signalée dans
                        // le rapport, valeur d'échelle la plus proche
                        // retenue (8) plutôt qu'un 10 hors échelle.
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppChip(
                            label: 'دعاء الجمعة',
                            selected: _activeCategory == 'friday',
                            onTap: () => _setCategory('friday'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ---- Ligne « pour qui » (20dp, pas un bouton) ----
                    _buildPersonsLine(cs, isDark),
                    const SizedBox(height: AppSpacing.md),

                    // ---- Carte du douʿā (N1) ----
                    Expanded(
                      child: SlideTransition(
                        position: _slide,
                        child: FadeTransition(
                          opacity: _fade,
                          child: AppCard(
                            child: Stack(
                              children: [
                                // Zone de texte contrainte pour exclure
                                // structurellement la bande du pied de carte
                                // (♡ + « دعاء آخر ») : à largeur/hauteur
                                // réduites, un douʿā long ne peut plus
                                // passer derrière le bouton, quelle que soit
                                // sa longueur — plutôt qu'un simple
                                // chevauchement laissé au hasard du Center.
                                Positioned.fill(
                                  bottom: _cardFooterReservedHeight,
                                  child: Center(
                                    child: _fadingDuaScroll(cs),
                                  ),
                                ),

                                // Pied de carte : ♡ + « دعاء آخر » — RTL
                                // naturel (aucun TextDirection.ltr forcé).
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      _buildFavoriteButton(cs, isDark),
                                      const Spacer(),
                                      AppButton(
                                        role: AppButtonRole.secondary,
                                        icon: Icons.skip_next_rounded,
                                        label: 'دعاء آخر',
                                        onPressed: _showNextFromDeck,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ---- نسخ / مشاركة (paire, largeurs égales par défaut) ----
                    _buildCopyShareActions(),
                  ],
                ),
              ),
            ),
          ),

          // ---- Rendu hors écran pour l'export Premium (capture PNG) ----
          // Toujours EXACTEMENT une image (décision produit V1.2) :
          // PremiumExportCard restreint elle-même le rendu Dark Luxe paginé
          // à sa première page (voir widgets/premium_export_card.dart).
          //
          // IgnorePointer + Opacity quasi nulle — PAS Offstage (V1.2,
          // Phase 9) : contrairement à Offstage, dont paint() ne peint
          // JAMAIS son enfant quand offstage=true (empêchant
          // RenderRepaintBoundary d'avoir un layer composité valide pour
          // toImage(), d'où l'échec silencieux constaté sur appareil réel),
          // Opacity continue de peindre son enfant même à une valeur
          // proche de 0.
          //
          // OverflowBox (LOT 3.L) : ce sous-arbre est un enfant non-Positioned
          // du Stack racine, qui lui impose des contraintes loose bornées à
          // la taille de l'écran. Sans OverflowBox, le SizedBox interne de
          // PremiumExportCard (dimensionné à template.fixedTemplateSize, ex.
          // 1086×1448) est donc clampé à la taille de l'écran par
          // BoxConstraints.enforce(), et le RepaintBoundary capture une
          // image à la mauvaise taille/ratio (le dou'a déborde de
          // duaTextZone). OverflowBox retire cette contrainte max en
          // passant des contraintes non bornées à son enfant : le
          // RepaintBoundary est alors layouté exactement à
          // template.fixedTemplateSize, indépendamment de l'écran.
          IgnorePointer(
            child: Opacity(
              opacity: 0.01,
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: _exportKey,
                  child: PremiumExportCard(
                    template: _selectedTemplate,
                    duaText: _currentDuaText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
