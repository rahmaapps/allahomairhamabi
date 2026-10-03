import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_screen.dart';
import '../models/person_type.dart';
import '../notification_service.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../user_prefs.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_chip.dart';

/// Onboarding — 2 écrans (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §4 Onboarding).
///
/// LOT 3.H — ordre corrigé pour se conformer à la décision verrouillée :
/// `لمن تدعو؟` (personnes) puis `تذكير يومي؟` (rappel). Remplace l'ordre
/// inverse retenu par LOT 3.E.1. Comportement de chaque étape inchangé —
/// seul l'ordre d'exécution change : la demande de permission notifications
/// (fire-and-forget, jamais à l'ouverture, jamais via « تخطّي ») se déclenche
/// désormais en quittant l'étape رappel via « التالي » (voir
/// `_finishFromReminderStep`), puisque cette étape est désormais la
/// dernière plutôt que la première.
///
/// `e0` uniquement (`AppCard(level: content)`), aucun or, aucun élément du
/// « privilège sacré » (§6.8-9). Aucun dialogue, aucune notation, aucune
/// promotion Premium (§6.12). Remplace le flux `settings_completed = false
/// → SettingsScreen` : `SettingsScreen` reste inchangé, toujours accessible
/// depuis HOME → ⋮ → « الإعدادات ».
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  // ---- Étape 1 — رappel : réutilise le rappel « الصباح » existant (mêmes
  // clés `UserPrefs`, même planification WorkManager `WorkIds.morning` côté
  // Paramètres) — c'est le seul des trois rappels existants qui correspond
  // à un rappel quotidien unique. بعد الظهر/المساء restent du ressort des
  // Paramètres (hors périmètre de ce lot).
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notificationsDenied = false;
  // Une seule tentative de demande pour toute la durée de vie de cet écran
  // (§4 : « aucune relance ») — même si l'utilisateur revient à l'étape 1
  // puis repart plusieurs fois vers l'étape 2.
  bool _permissionRequestAttempted = false;

  // ---- Étape 2 — personnes : même persistance que `PersonSelectionScreen`
  // (`UserPrefs.getPersonsData`/`savePersonsData`), même debounce 400 ms
  // pour le prénom, prénom toujours facultatif et conservé après décochage.
  final Set<PersonType> _selectedPersons = {};
  final Map<PersonType, TextEditingController> _controllers = {};
  final Map<PersonType, Timer?> _debounce = {};

  @override
  void initState() {
    super.initState();
    for (final p in PersonType.values) {
      _controllers[p] = TextEditingController();
    }
    _loadReminder();
    _loadPersons();
    // Lecture seule, aucune demande ici (LOT 3.E.1 — « aucun dialogue
    // automatique à l'ouverture ») : juste de quoi afficher la ligne
    // d'info si la permission a déjà été refusée par ailleurs (ex.
    // désactivée manuellement dans les réglages système entre deux
    // lancements). La demande elle-même n'a lieu qu'au passage explicite
    // hors de l'étape rappel, voir `_finishFromReminderStep`.
    _refreshNotificationStatus();
  }

  @override
  void dispose() {
    for (final t in _debounce.values) {
      t?.cancel();
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReminder() async {
    final prefs = UserPrefs();
    final enabled = await prefs.getMorningEnabled();
    final time = await prefs.getMorningTime();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = time;
    });
  }

  Future<void> _loadPersons() async {
    final data = await UserPrefs.getPersonsData();
    if (!mounted) return;
    setState(() {
      for (final p in PersonType.values) {
        _controllers[p]!.text = data[p.name] ?? '';
      }
      _selectedPersons
        ..clear()
        ..addAll(data.keys.map((k) => PersonType.values.firstWhere((p) => p.name == k)));
    });
  }

  /// `main()` saute délibérément la demande de permission au tout premier
  /// lancement, et cet écran ne la déclenche jamais tout seul à
  /// l'ouverture (LOT 3.E.1 — « aucun dialogue automatique à l'ouverture »).
  /// `requestIfNeeded` n'est passé à `true` que depuis
  /// `_finishFromReminderStep`, en réponse à l'action explicite de
  /// l'utilisateur (« التالي » sur l'étape finale `تذكير يومي؟`) quand le
  /// rappel est actif — jamais depuis `initState`. Sans demande
  /// (`requestIfNeeded: false`), c'est une lecture seule, sûre à appeler à
  /// tout moment (`requestPermissionIfNeeded` ne touche jamais
  /// `_plugin.initialize()`, déjà fait par `main()`).
  Future<void> _refreshNotificationStatus({bool requestIfNeeded = false}) async {
    if (requestIfNeeded) {
      await NotificationService.instance.requestPermissionIfNeeded();
    }
    final granted = await NotificationService.instance.notificationsPermissionGranted();
    if (!mounted) return;
    setState(() => _notificationsDenied = !granted);
  }

  Future<void> _setReminderEnabled(bool v) async {
    // Enregistrement immédiat (§4 : « la sélection est toujours enregistrée
    // avant toute sortie ») — même logique que Paramètres/Person Selection.
    setState(() => _reminderEnabled = v);
    await UserPrefs().setMorningEnabled(v);
  }

  Future<void> _pickReminderTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (res == null) return;
    setState(() => _reminderTime = res);
    await UserPrefs().setMorningTime(res);
  }

  /// Décocher une personne ne vide jamais son champ (§4 Onboarding : « le
  /// prénom est toujours facultatif, conservé même après décochage ») — le
  /// contrôleur garde son texte, invisible tant que la ligne n'est pas
  /// recochée, où il réapparaît tel quel. La persistance `persons_data`
  /// reste par construction limitée aux personnes cochées (même modèle que
  /// `PersonSelectionScreen` : la présence d'une clé EST la sélection) — la
  /// conservation porte donc sur le champ affiché, pas sur un stockage
  /// disque distinct pour une personne décochée, que le modèle existant ne
  /// permet pas de distinguer d'« jamais renseignée ».
  void _togglePerson(PersonType p) {
    setState(() {
      if (_selectedPersons.contains(p)) {
        _selectedPersons.remove(p);
      } else {
        _selectedPersons.add(p);
      }
    });
    _persistPersons();
  }

  void _onNameChanged(PersonType p) {
    _debounce[p]?.cancel();
    _debounce[p] = Timer(const Duration(milliseconds: 400), _persistPersons);
  }

  Future<void> _persistPersons() async {
    final data = <String, String>{
      for (final p in _selectedPersons) p.name: _controllers[p]!.text,
    };
    await UserPrefs.savePersonsData(data);
  }

  /// Avance de l'étape « لمن تدعو؟ » vers l'étape رappel — simple
  /// transition, aucune logique de permission ici (elle est déclenchée en
  /// quittant l'étape رappel, désormais la dernière — voir
  /// `_finishFromReminderStep`).
  Future<void> _goToStep2() async {
    setState(() => _step = 1);
    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _backToStep1() async {
    setState(() => _step = 0);
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  /// « التالي » sur l'étape رappel (désormais la dernière) : action
  /// explicite de l'utilisateur liée au rappel (rappel actif — activé par
  /// défaut, ou remis actif par l'utilisateur) — seul point de
  /// déclenchement de la demande de permission (LOT 3.E.1 — jamais à
  /// l'ouverture, jamais via « تخطّي »). Fire-and-forget : ne retarde jamais
  /// la sortie de l'onboarding.
  Future<void> _finishFromReminderStep() async {
    if (_reminderEnabled && !_permissionRequestAttempted) {
      _permissionRequestAttempted = true;
      _refreshNotificationStatus(requestIfNeeded: true);
    }
    await _finish();
  }

  /// Sortie (« التالي » à l'étape 2, ou « تخطّي » à tout moment) — tout est
  /// déjà enregistré au fil de l'eau, il ne reste qu'à marquer l'onboarding
  /// complété et router vers HOME (§4 : fondu 300 ms, sans glissement).
  Future<void> _finish() async {
    for (final t in _debounce.values) {
      t?.cancel();
    }
    await _persistPersons();

    final sp = await SharedPreferences.getInstance();
    await sp.setBool('settings_completed', true);

    if (!mounted) return;

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionDuration: Duration(milliseconds: reduceMotion ? 150 : 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  /// Libellés possessifs — copie exacte de `PersonSelectionScreen` pour que
  /// les deux écrans se lisent de façon identique (`أبي`, pas `الأب`),
  /// dupliquée localement (même motif que `dua_read_screen.dart::_attrSuffix`,
  /// aucune constante partagée existante).
  String _possessiveLabel(PersonType person) {
    switch (person) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Zone de retour — hauteur réservée sur les deux étapes pour
                // que le titre ne saute pas verticalement (visible seulement
                // à l'étape 2, § « retour arrière conserve les sélections »).
                SizedBox(
                  height: 40,
                  child: _step == 1
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.arrow_forward, color: cs.onSurface),
                            onPressed: _backToStep1,
                          ),
                        )
                      : null,
                ),
                // Indicateur qui se remplit, ne glisse pas (§4 Onboarding).
                _ProgressIndicator(step: _step, count: 2, color: cs.primary, track: cs.outline),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  _step == 0 ? 'لمن تدعو؟' : 'تذكير يومي؟',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle
                      .copyWith(fontSize: 22, color: cs.onSurface),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonsStep(cs),
                      _buildReminderStep(cs),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: AppButton(
                        role: AppButtonRole.secondary,
                        label: 'تخطّي',
                        onPressed: _finish,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        role: AppButtonRole.primary,
                        label: 'التالي',
                        onPressed: _step == 0 ? _goToStep2 : _finishFromReminderStep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderStep(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sous-titre dynamique reprenant la première personne cochée à
          // l'étape précédente (§4 Onboarding) — n'a de sens que depuis le
          // réalignement de l'ordre (LOT 3.K) : au moins une personne peut
          // désormais déjà être sélectionnée en arrivant sur cette étape.
          // `_selectedPersons` est un `LinkedHashSet` (littéral `{}`) : son
          // ordre d'itération suit l'ordre de coche, donc `.first` est
          // bien « la première personne cochée » et se met à jour si elle
          // est décochée. Même idiome que la ligne « pour qui » du HOME
          // (`_possessivePersonLabel`), réutilise `_possessiveLabel` déjà
          // défini dans ce fichier — aucun nouveau composant.
          if (_selectedPersons.isNotEmpty) ...[
            Text(
              'تدعو لـ ${_possessiveLabel(_selectedPersons.first)}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTypography.label.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppCard(
            level: AppCardLevel.content,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        'تذكير يومي بالدعاء',
                        textDirection: TextDirection.rtl,
                        style: AppTypography.body.copyWith(color: cs.onSurface),
                      ),
                    ),
                    Switch(
                      value: _reminderEnabled,
                      activeThumbColor: cs.primary,
                      onChanged: _setReminderEnabled,
                    ),
                  ],
                ),
                // La ligne « الوقت » disparaît complètement si désactivé —
                // jamais grisée (§4 Onboarding).
                if (_reminderEnabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          'الوقت',
                          textDirection: TextDirection.rtl,
                          style: AppTypography.body.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickReminderTime,
                        child: Text(
                          // Chiffres occidentaux (décision UX — remplace les
                          // chiffres arabes-indiens initialement prévus par
                          // §3 pour ce cas précis).
                          '${_reminderTime.hour.toString().padLeft(2, '0')}:'
                          '${_reminderTime.minute.toString().padLeft(2, '0')}',
                          textDirection: TextDirection.rtl,
                          // Seule exception à Plex dans l'onboarding : l'heure
                          // en Lateef 26 (§4 Onboarding).
                          style: AppTypography.display
                              .copyWith(fontSize: 26, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Permission refusée → une seule ligne d'information, aucun
          // dialogue, aucune relance (§4 Onboarding). N'a de sens que si le
          // rappel est demandé — inutile si l'utilisateur vient de le
          // désactiver lui-même.
          if (_reminderEnabled && _notificationsDenied) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'تم رفض إذن الإشعارات — يمكن تفعيله لاحقًا من إعدادات الجهاز.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonsStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'يُحفظ اختيارك تلقائيًا',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTypography.label.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView.separated(
            itemCount: PersonType.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final person = PersonType.values[index];
              final isSelected = _selectedPersons.contains(person);

              return Row(
                textDirection: TextDirection.rtl,
                children: [
                  AppChip(
                    variant: AppChipVariant.person,
                    label: _possessiveLabel(person),
                    selected: isSelected,
                    onTap: () => _togglePerson(person),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _controllers[person],
                        textDirection: TextDirection.rtl,
                        style: AppTypography.body.copyWith(color: cs.onSurface),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'الاسم (اختياري)',
                          border: OutlineInputBorder(borderRadius: AppRadii.fieldRadius),
                        ),
                        onChanged: (_) => _onNameChanged(person),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Indicateur de progression — se remplit, ne glisse jamais (§4 Onboarding).
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.step,
    required this.count,
    required this.color,
    required this.track,
  });

  final int step;
  final int count;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final filled = i <= step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == count - 1 ? 0 : AppSpacing.xs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: filled ? color : track,
                borderRadius: AppRadii.pillRadius,
              ),
            ),
          ),
        );
      }),
    );
  }
}
