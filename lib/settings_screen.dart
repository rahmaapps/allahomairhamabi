// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'monetization/ad_free_hour_entry.dart';
import 'monetization/privacy_options_entry.dart';
import 'monetization/rewarded_wording.dart';
import 'notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'theme_notifier.dart';
import 'user_prefs.dart';
import 'widgets/app_bar.dart';
import 'widgets/app_card.dart';
import 'widgets/app_snackbar.dart';
import 'widgets/rewarded_confirmation_sheet.dart';

/// Conservée uniquement pour compatibilité avec
/// `test/settings_screen_lot3g_test.dart` (logique pure de replanification
/// du vendredi, sans dépendance à `workmanager`, retiré du projet — voir
/// [NotificationService.scheduleWeeklyReminder] pour la planification
/// réelle des rappels, qui n'a plus aucun rapport avec cette classe).
class WorkManagerService {
  /// Prochaine occurrence **calendaire** de vendredi à `hour:minute`.
  ///
  /// `now` est injectable uniquement pour les tests (`@visibleForTesting`) ;
  /// l'appel réel ne le fournit jamais et utilise `DateTime.now()`.
  @visibleForTesting
  static Duration initialDelayForNextFriday(int hour, int minute, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final daysUntilFriday = (DateTime.friday - n.weekday) % 7;
    var scheduled = DateTime(n.year, n.month, n.day, hour, minute)
        .add(Duration(days: daysUntilFriday));
    if (!scheduled.isAfter(n)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled.difference(n);
  }
}

/// Paramètres — spécification consolidée (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md,
/// §4) adaptée par les décisions verrouillées du LOT 3.G : بعد الظهر
/// supprimé, تدعو لـ retiré de cet écran (déjà accessible ailleurs). Les 3
/// rappels (صباح/مساء/جمعة) ont chacun une activation + une heure
/// configurable et persistée séparément (évolution post-LOT 3.G : صباح,
/// مساء et جمعة suivent désormais tous le même pattern). Enregistrement
/// immédiat de chaque changement — aucun bouton de sauvegarde.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Texte de partage validé (LOT 3.O — « مشاركة التطبيق »). Mécanisme natif
  /// uniquement (`Share.share`), aucune logique spécifique à une app tierce
  /// (remplace l'ancienne intégration WhatsApp de `home_screen.dart`,
  /// supprimée par ce lot).
  static const _shareAppText =
      'اللَّهُمَّ ارْحَمْ أَبِي\n'
      'تطبيق أدعية لوالدي الميت 🤍\n'
      '\n'
      'شارك الأجر مع من تحب:\n'
      'https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi';

  String _selectedTheme = 'system';

  bool _enableMorning = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 9, minute: 0);
  bool _enableEvening = true;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);
  bool _enableFriday = false;
  TimeOfDay _fridayTime = const TimeOfDay(hour: 9, minute: 0);

  bool _loading = true;

  /// LOT 5.E — entrée « خيارات الخصوصية ». Le statut est réinterrogé à
  /// chaque ouverture de cet écran (une nouvelle instance d'état est créée
  /// à chaque navigation) : il n'est jamais déduit d'un état UMP mis en
  /// cache au démarrage, qui peut ne pas être encore exploitable.
  final PrivacyOptionsEntry _privacyOptions = PrivacyOptionsEntry();
  bool _privacyOptionsRequired = false;

  /// LOT 5.G.B — ligne « une heure sans publicité » (B1). État relu à
  /// chaque ouverture de l'écran, jamais mis en cache.
  final AdFreeHourEntry _adFreeHour = AdFreeHourEntry();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await NotificationService.ensureInitialized(); // UI isolate
    await _loadPrefs();
    // Le nettoyage de l'ancienne tâche `period_afternoon` (compatibilité
    // utilisateurs existants) vit désormais dans `main()` — exécuté au
    // démarrage réel de l'app, indépendamment de l'ouverture de cet écran.

    // LOT 5.E — après `_loadPrefs()` : l'affichage des réglages ne doit
    // jamais attendre une réponse du SDK de consentement.
    await _refreshPrivacyOptionsRequirement();

    // LOT 5.G.B — même principe : l'affichage des réglages n'attend jamais
    // l'état publicitaire.
    await _adFreeHour.refresh();
  }

  @override
  void dispose() {
    _adFreeHour.dispose();
    super.dispose();
  }

  /// Ne lève jamais (garantie de [PrivacyOptionsEntry]) : au pire la ligne
  /// reste absente.
  Future<void> _refreshPrivacyOptionsRequirement() async {
    final required = await _privacyOptions.isRequired();
    if (!mounted) return;
    if (required == _privacyOptionsRequired) return;
    setState(() => _privacyOptionsRequired = required);
  }

  Future<void> _loadPrefs() async {
    final prefs = UserPrefs();

    final th = await prefs.getThemeMode();
    final enM = await prefs.getMorningEnabled();
    final tmM = await prefs.getMorningTime();
    final enE = await prefs.getEveningEnabled();
    final tmE = await prefs.getEveningTime();
    final enF = await prefs.getFridayEnabled();
    final tmF = await prefs.getFridayTime();

    if (!mounted) return;
    setState(() {
      _selectedTheme = th;
      _enableMorning = enM;
      _morningTime = tmM;
      _enableEvening = enE;
      _eveningTime = tmE;
      _enableFriday = enF;
      _fridayTime = tmF;
      _loading = false;
    });

    await _syncBackgroundSchedules();
  }

  Future<TimeOfDay?> _showRtlTimePicker(TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  Future<void> _pickMorningTime() async {
    final res = await _showRtlTimePicker(_morningTime);
    if (res == null) return;
    setState(() => _morningTime = res);
    await UserPrefs().setMorningTime(res);
    await _syncBackgroundSchedules();
  }

  Future<void> _pickEveningTime() async {
    final res = await _showRtlTimePicker(_eveningTime);
    if (res == null) return;
    setState(() => _eveningTime = res);
    await UserPrefs().setEveningTime(res);
    await _syncBackgroundSchedules();
  }

  Future<void> _pickFridayTime() async {
    final res = await _showRtlTimePicker(_fridayTime);
    if (res == null) return;
    setState(() => _fridayTime = res);
    await UserPrefs().setFridayTime(res);
    await _syncBackgroundSchedules();
  }

  /// À l'activation d'un rappel (jamais au changement d'heure d'un rappel
  /// déjà actif), propose l'alarme exacte si elle n'est pas déjà accordée
  /// — ouvre l'écran système « Alarmes et rappels »
  /// (`NotificationService.requestExactAlarmsPermission`). N'a aucun effet
  /// bloquant : que l'utilisateur accorde ou non, l'activation se poursuit
  /// normalement ensuite via `_syncBackgroundSchedules` — qui choisira
  /// `exactAllowWhileIdle` si accordée, ou le repli `inexactAllowWhileIdle`
  /// déjà en place sinon (logique inchangée, entièrement dans
  /// `NotificationService._scheduleZoned`).
  Future<void> _requestExactAlarmIfNeeded() async {
    final notifications = NotificationService();
    if (!await notifications.canScheduleExactAlarms()) {
      await notifications.requestExactAlarmsPermission();
    }
  }

  Future<void> _setMorningEnabled(bool v) async {
    if (v) {
      await _requestExactAlarmIfNeeded();
    }
    setState(() => _enableMorning = v);
    await UserPrefs().setMorningEnabled(v);
    await _syncBackgroundSchedules();
  }

  Future<void> _setEveningEnabled(bool v) async {
    if (v) {
      await _requestExactAlarmIfNeeded();
    }
    setState(() => _enableEvening = v);
    await UserPrefs().setEveningEnabled(v);
    await _syncBackgroundSchedules();
  }

  Future<void> _setFridayEnabled(bool v) async {
    if (v) {
      await _requestExactAlarmIfNeeded();
    }
    setState(() => _enableFriday = v);
    await UserPrefs().setFridayEnabled(v);
    await _syncBackgroundSchedules();
  }

  /// Applique aux rappels natifs l'état actuel de [_enableMorning] /
  /// [_enableEvening] / [_enableFriday] (+ heures). `NotificationService`
  /// ne lève jamais d'exception : chaque planification retourne `true`/
  /// `false` selon le succès réel. En cas d'échec, le rappel concerné est
  /// explicitement repassé à désactivé (état + préférence persistée) —
  /// jamais laissé « activé » dans l'UI alors qu'aucune notification n'est
  /// réellement programmée auprès de l'OS — et l'utilisateur en est informé.
  Future<void> _syncBackgroundSchedules() async {
    final notifications = NotificationService();
    var scheduleFailed = false;

    if (_enableMorning) {
      final ok = await notifications.scheduleDailyReminder(
        periodId: 'period_morning',
        hour: _morningTime.hour,
        minute: _morningTime.minute,
      );
      if (!ok) {
        scheduleFailed = true;
        _enableMorning = false;
        await UserPrefs().setMorningEnabled(false);
      }
    } else {
      await notifications.cancelReminder(NotificationService.notificationIdMorning);
    }

    if (_enableEvening) {
      final ok = await notifications.scheduleDailyReminder(
        periodId: 'period_evening',
        hour: _eveningTime.hour,
        minute: _eveningTime.minute,
      );
      if (!ok) {
        scheduleFailed = true;
        _enableEvening = false;
        await UserPrefs().setEveningEnabled(false);
      }
    } else {
      await notifications.cancelReminder(NotificationService.notificationIdEvening);
    }

    if (_enableFriday) {
      final ok = await notifications.scheduleWeeklyReminder(
        periodId: 'period_friday',
        weekday: DateTime.friday,
        hour: _fridayTime.hour,
        minute: _fridayTime.minute,
      );
      if (!ok) {
        scheduleFailed = true;
        _enableFriday = false;
        await UserPrefs().setFridayEnabled(false);
      }
    } else {
      await notifications.cancelReminder(NotificationService.notificationIdFriday);
    }

    if (scheduleFailed && mounted) {
      setState(() {}); // reflète l'état corrigé (rappel repassé à désactivé)
      showAppToast(context, 'تعذّرت برمجة أحد التذكيرات — أعد المحاولة لاحقًا');
    }
  }

  /// « مشاركة التطبيق » (LOT 3.O) — distincte du Partage Premium
  /// (`مشاركة كصورة`, image d'un dou'a). Mécanisme natif de la plateforme
  /// uniquement (`Share.share`, déjà utilisé ailleurs dans le projet pour le
  /// dou'a — `home_screen.dart`, `dua_read_screen.dart`), aucune dépendance
  /// nouvelle, aucune logique propre à une app tierce.
  Future<void> _shareApp() async {
    await Share.share(_shareAppText);
  }

  /// « خيارات الخصوصية » (LOT 5.E) — ouvre le formulaire UMP d'options de
  /// confidentialité, seul moyen pour l'utilisateur de revenir sur son
  /// consentement publicitaire. Même traitement d'erreur que
  /// [_openAbout] : un toast arabe déjà existant (`showAppToast`), jamais
  /// un crash, jamais un blocage de l'écran.
  Future<void> _openPrivacyOptions() async {
    final opened = await _privacyOptions.open();
    if (!mounted) return;

    if (!opened) {
      showAppToast(context, 'تعذّر فتح خيارات الخصوصية');
      return;
    }

    // Le statut a pu changer pendant l'affichage du formulaire.
    await _refreshPrivacyOptionsRequirement();
  }

  Future<void> _openAbout() async {
    final uri = Uri.parse(
      'https://rahmaapps.github.io/allahomairhamabi/',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showAppToast(context, 'تعذّر فتح صفحة حول التطبيق');
      }
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'تعذّر فتح صفحة حول التطبيق');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Même lecture que Favoris/Recherche (LOT 2.2) : ivoire fixe par mode,
    // jamais `ColorScheme.onPrimary` (illisible sur le fond `appBar` Dark).
    final appBarForeground =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.onPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'الإعدادات',
          height: 52,
          titleStyle: AppTypography.sectionTitle.copyWith(color: appBarForeground),
        ),
        // Lecture locale (§P2-B) — même traitement que Recherche/
        // DuaReadScreen/Favoris/Visite : aucun indicateur de chargement.
        body: _loading
            ? const SizedBox.shrink()
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    const _SectionTitle('التذكير'),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      level: AppCardLevel.settingsGroup,
                      child: Column(
                        children: [
                          _ReminderRow(
                            label: 'تذكير الصباح',
                            enabled: _enableMorning,
                            time: _morningTime,
                            onToggle: _setMorningEnabled,
                            onPickTime: _pickMorningTime,
                          ),
                          const _RowDivider(),
                          _ReminderRow(
                            label: 'تذكير المساء',
                            enabled: _enableEvening,
                            time: _eveningTime,
                            onToggle: _setEveningEnabled,
                            onPickTime: _pickEveningTime,
                          ),
                          const _RowDivider(),
                          _ReminderRow(
                            label: 'تذكير الجمعة',
                            enabled: _enableFriday,
                            time: _fridayTime,
                            onToggle: _setFridayEnabled,
                            onPickTime: _pickFridayTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    const _SectionTitle('التطبيق'),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      level: AppCardLevel.settingsGroup,
                      child: Column(
                        children: [
                          _ThemeRow(
                            value: _selectedTheme,
                            onChanged: (v) async {
                              setState(() => _selectedTheme = v);
                              await context.read<ThemeNotifier>().setTheme(v);
                            },
                          ),
                          const _RowDivider(),
                          _SettingsLinkRow(label: 'عن التطبيق', onTap: _openAbout),
                          // LOT 5.G.B — B1 : exactement entre « عن التطبيق »
                          // et « خيارات الخصوصية ». Porte elle-même son
                          // séparateur : absente, elle ne laisse aucune trace.
                          AdFreeHourSettingsRow(entry: _adFreeHour),
                          // LOT 5.E — présente UNIQUEMENT quand Google
                          // exige un point d'entrée « Options de
                          // confidentialité » (`isPrivacyOptionsRequired`).
                          // Absente sinon : jamais une ligne grisée, même
                          // traitement que la ligne d'heure d'un rappel
                          // désactivé.
                          if (_privacyOptionsRequired) ...[
                            const _RowDivider(),
                            _SettingsLinkRow(
                              label: 'خيارات الخصوصية',
                              onTap: _openPrivacyOptions,
                            ),
                          ],
                          const _RowDivider(),
                          _SettingsLinkRow(label: 'مشاركة التطبيق', onTap: _shareApp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      textDirection: TextDirection.rtl,
      style: AppTypography.sectionTitle.copyWith(color: cs.onSurface),
    );
  }
}

/// Séparateur 1 px pleine largeur entre deux lignes d'un même groupe de
/// réglages (§4 : « absents sur la dernière ligne » — c'est l'appelant qui
/// n'en insère pas après la dernière ligne, ce widget ne le décide pas).
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Theme.of(context).colorScheme.outline);
  }
}

/// Rappel (صباح/مساء/جمعة) + الوقت — reprend strictement le pattern déjà
/// validé de `OnboardingScreen._buildReminderStep` (Switch puis ligne
/// d'heure qui disparaît, jamais grisée, si désactivé). Les 3 rappels
/// partagent ce même composant : chacun a sa propre heure configurable.
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.label,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  final String label;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toute la ligne est cliquable (§P1-J), pas seulement l'interrupteur
          // — même comportement d'activation/désactivation qu'avant
          // (`onToggle(!enabled)` reproduit exactement ce que `Switch.onChanged`
          // recevait déjà pour un tap simple). `IgnorePointer` sur le `Switch`
          // évite un double-basculement : un seul gestionnaire de tap (cet
          // `InkWell`) gouverne toute la zone, y compris visuellement
          // au-dessus de l'interrupteur.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onToggle(!enabled),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.body.copyWith(color: cs.onSurface),
                    ),
                  ),
                  IgnorePointer(
                    child: Switch(
                      value: enabled,
                      activeThumbColor: cs.primary,
                      onChanged: onToggle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // La ligne « الوقت » disparaît complètement si désactivé — jamais
          // grisée (§4).
          if (enabled) ...[
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
                  onTap: onPickTime,
                  child: Text(
                    '${time.hour.toString().padLeft(2, '0')}:'
                    '${time.minute.toString().padLeft(2, '0')}',
                    textDirection: TextDirection.rtl,
                    style: AppTypography.display.copyWith(fontSize: 26, color: cs.primary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// المظهر (تلقائي/فاتح/داكن) — aucun composant de sélection à 3 options
/// n'existe dans le Design System ; `DropdownButton` conservé (comportement
/// inchangé, branché sur `ThemeNotifier`) mais reskiné avec les tokens
/// typographiques/couleur du projet plutôt que le style Material par défaut.
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              'المظهر',
              textDirection: TextDirection.rtl,
              style: AppTypography.body.copyWith(color: cs.onSurface),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            dropdownColor: cs.surface,
            style: AppTypography.body.copyWith(color: cs.onSurface),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('تلقائي')),
              DropdownMenuItem(value: 'light', child: Text('فاتح')),
              DropdownMenuItem(value: 'dark', child: Text('داكن')),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// LOT 5.G.B — ligne « une heure sans publicité » (B1/B3/B5/B6).
///
/// Publique pour être testée seule : `SettingsScreen` n'est pas testable en
/// widget (`_bootstrap()` attend un canal de plateforme natif), limitation
/// déjà documentée dans ce projet. Réutilise strictement `_SettingsLinkRow`
/// et `_RowDivider` — aucun nouveau style.
///
/// - Heure active : jamais masquée ni désactivée (B5), temps restant réel.
/// - Hors fenêtre : présente seulement si un Rewarded peut réellement être
///   proposé ; absente sinon, séparateur compris.
/// - Tap : confirmation → Rewarded → toast de succès (B6). Un échec ou une
///   fermeture anticipée ramène simplement à l'invitation, sans message.
class AdFreeHourSettingsRow extends StatefulWidget {
  const AdFreeHourSettingsRow({
    super.key,
    required this.entry,
    this.confirm = showRewardedConfirmation,
  });

  final AdFreeHourEntry entry;

  /// Injection réservée aux tests ; confirmation réelle par défaut.
  final Future<bool> Function(BuildContext context) confirm;

  @override
  State<AdFreeHourSettingsRow> createState() => _AdFreeHourSettingsRowState();
}

class _AdFreeHourSettingsRowState extends State<AdFreeHourSettingsRow> {
  @override
  void initState() {
    super.initState();
    widget.entry.addListener(_onEntryChanged);
  }

  @override
  void didUpdateWidget(AdFreeHourSettingsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      oldWidget.entry.removeListener(_onEntryChanged);
      widget.entry.addListener(_onEntryChanged);
    }
  }

  @override
  void dispose() {
    widget.entry.removeListener(_onEntryChanged);
    super.dispose();
  }

  void _onEntryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onTap() async {
    final entry = widget.entry;
    if (entry.state == AdFreeHourEntryState.loading) return;

    final result = await entry.activate(confirm: () => widget.confirm(context));
    if (!mounted) return;

    switch (result) {
      case AdFreeHourResult.earned:
        showAppToast(context, RewardedWording.adFreeHourEarned);
      case AdFreeHourResult.alreadyActive:
        // B3/B5 : aucun Rewarded, le temps restant est rappelé.
        showAppToast(context, entry.label);
      case AdFreeHourResult.cancelled:
      case AdFreeHourResult.notEarned:
        // Aucun message : la ligne revient simplement à l'invitation.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    if (!entry.isVisible) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _RowDivider(),
        _SettingsLinkRow(label: entry.label, onTap: _onTap),
      ],
    );
  }
}

/// عن التطبيق — ligne cliquable pleine largeur, chevron RTL (`‹`, cohérent
/// avec `AppVisitBandeau`), pas de `ListTile` Material brut.
class _SettingsLinkRow extends StatelessWidget {
  const _SettingsLinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.body.copyWith(color: cs.onSurface),
                ),
              ),
              Icon(Icons.chevron_left, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
