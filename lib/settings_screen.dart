// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'theme_notifier.dart';
import 'user_prefs.dart';
import 'widgets/app_bar.dart';
import 'widgets/app_card.dart';

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
/// supprimé, تدعو لـ retiré de cet écran (déjà accessible ailleurs), soir et
/// vendredi à heure fixe non configurable. Enregistrement immédiat de
/// chaque changement — aucun bouton de sauvegarde.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Heures fixes, non configurables par l'utilisateur (LOT 3.G §3 et §4).
  static const _eveningTime = TimeOfDay(hour: 20, minute: 0);
  static const _fridayTime = TimeOfDay(hour: 9, minute: 0);

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
  bool _enableFriday = false;

  bool _loading = true;

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
  }

  Future<void> _loadPrefs() async {
    final prefs = UserPrefs();

    final th = await prefs.getThemeMode();
    final enM = await prefs.getMorningEnabled();
    final tmM = await prefs.getMorningTime();
    final enE = await prefs.getEveningEnabled();
    final enF = await prefs.getFridayEnabled();

    if (!mounted) return;
    setState(() {
      _selectedTheme = th;
      _enableMorning = enM;
      _morningTime = tmM;
      _enableEvening = enE;
      _enableFriday = enF;
      _loading = false;
    });

    await _syncBackgroundSchedules();
  }

  Future<void> _pickMorningTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _morningTime,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (res == null) return;
    setState(() => _morningTime = res);
    await UserPrefs().setMorningTime(res);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّرت برمجة أحد التذكيرات — أعد المحاولة لاحقًا')),
      );
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

  Future<void> _openAbout() async {
    final uri = Uri.parse(
      'https://rahmaapps.github.io/allahomairhamabi/',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح صفحة حول التطبيق')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح صفحة حول التطبيق')),
      );
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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const _SectionTitle('التذكير'),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      level: AppCardLevel.settingsGroup,
                      child: Column(
                        children: [
                          _MorningReminderRows(
                            enabled: _enableMorning,
                            time: _morningTime,
                            onToggle: _setMorningEnabled,
                            onPickTime: _pickMorningTime,
                          ),
                          const _RowDivider(),
                          _SettingsSwitchRow(
                            label: 'تذكير المساء',
                            value: _enableEvening,
                            onChanged: _setEveningEnabled,
                          ),
                          const _RowDivider(),
                          _SettingsSwitchRow(
                            label: 'تذكير الجمعة',
                            value: _enableFriday,
                            onChanged: _setFridayEnabled,
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

/// تذكير الصباح + الوقت — reprend strictement le pattern déjà validé de
/// `OnboardingScreen._buildReminderStep` (Switch puis ligne d'heure qui
/// disparaît, jamais grisée, si désactivé).
class _MorningReminderRows extends StatelessWidget {
  const _MorningReminderRows({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

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
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  'تذكير الصباح',
                  textDirection: TextDirection.rtl,
                  style: AppTypography.body.copyWith(color: cs.onSurface),
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: cs.primary,
                onChanged: onToggle,
              ),
            ],
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

/// Ligne de réglage à switch seul, sans heure — تذكير المساء / تذكير الجمعة
/// (LOT 3.G : heure fixe non configurable, aucune ligne supplémentaire).
class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

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
              label,
              textDirection: TextDirection.rtl,
              style: AppTypography.body.copyWith(color: cs.onSurface),
            ),
          ),
          Switch(value: value, activeThumbColor: cs.primary, onChanged: onChanged),
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
