// lib/settings_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart' as wm;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

import 'theme_notifier.dart';
import 'user_prefs.dart';
import 'notification_service.dart';

/// Identifiants uniques pour WorkManager
class WorkIds {
  static const morning = 'period_morning';
  static const afternoon = 'period_afternoon';
  static const evening = 'period_evening';
}

class WorkManagerService {
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await wm.Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    _initialized = true;
  }

  static Duration _initialDelayFor(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled.difference(now);
  }

  static Future<void> scheduleDaily({
    required String uniqueName,
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();
    final delay = _initialDelayFor(hour, minute);
    await wm.Workmanager().registerOneOffTask(
      uniqueName,
      uniqueName,
      initialDelay: delay,
      inputData: {
        'taskId': uniqueName,
        'hour': hour,
        'minute': minute,
      },
      existingWorkPolicy: wm.ExistingWorkPolicy.replace,
      constraints: wm.Constraints(networkType: wm.NetworkType.notRequired),
      backoffPolicy: wm.BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  static Future<void> cancel(String uniqueName) async {
    await _ensureInitialized();
    await wm.Workmanager().cancelByUniqueName(uniqueName);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  wm.Workmanager().executeTask((task, inputData) async {
    try {
      // ⚠️ Init service de notifications dans l’isolate
      await NotificationService.ensureInitialized();
      final id = (inputData?['taskId'] as String?) ?? task;
      final hour = inputData?['hour'] as int? ?? 7;
      final minute = inputData?['minute'] as int? ?? 0;

      // Afficher la notification planifiée
      await NotificationService().showPeriodReminder(
        periodId: id,
        hour: hour,
        minute: minute,
      );

      // Replanifier pour le lendemain
      final now = DateTime.now();
      final next = DateTime(now.year, now.month, now.day, hour, minute)
          .add(const Duration(days: 1));
      final nextDelay = next.difference(now);

      await wm.Workmanager().registerOneOffTask(
        id,
        id,
        initialDelay: nextDelay,
        inputData: {
          'taskId': id,
          'hour': hour,
          'minute': minute,
        },
        existingWorkPolicy: wm.ExistingWorkPolicy.replace,
        constraints: wm.Constraints(networkType: wm.NetworkType.notRequired),
      );

      return Future.value(true);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[WorkManager] Erreur tâche "$task": $e\n$st');
      }
      return Future.value(false);
    }
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---- Thème
  String _selectedTheme = "system"; // system | light | dark

  // ---- Longueur
  String _lengthFilter = "all"; // all | short | long

  // ---- Périodes
  bool _enableMorning = true;
  bool _enableAfternoon = true;
  bool _enableEvening = true;

  TimeOfDay _morningTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  bool _loading = true;

  //Person name
  final TextEditingController _personNameController = TextEditingController();
  String? _personName;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await NotificationService.ensureInitialized(); // UI isolate
    await _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = UserPrefs();

    final th = await prefs.getThemeMode();
    final lf = await prefs.getLengthFilter();

    final enM = await prefs.getEnableMorning();
    final enA = await prefs.getEnableAfternoon();
    final enE = await prefs.getEnableEvening();

    final tmM = await prefs.getMorningTime();
    final tmA = await prefs.getAfternoonTime();
    final tmE = await prefs.getEveningTime();

    final personName = await UserPrefs.getPersonName();

    if (!mounted) return;
    setState(() {
      _selectedTheme = th;
      _lengthFilter = lf;

      _enableMorning = enM;
      _enableAfternoon = enA;
      _enableEvening = enE;

      _morningTime = tmM;
      _afternoonTime = tmA;
      _eveningTime = tmE;

      _personName = personName;
      _personNameController.text = personName ?? '';

      _loading = false;
    });

    await _syncBackgroundSchedules();
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final res = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (res != null) onPicked(res);
  }

  Future<void> _syncBackgroundSchedules() async {
    if (_enableMorning) {
      await WorkManagerService.scheduleDaily(
        uniqueName: WorkIds.morning,
        hour: _morningTime.hour,
        minute: _morningTime.minute,
      );
    } else {
      await WorkManagerService.cancel(WorkIds.morning);
    }

    if (_enableAfternoon) {
      await WorkManagerService.scheduleDaily(
        uniqueName: WorkIds.afternoon,
        hour: _afternoonTime.hour,
        minute: _afternoonTime.minute,
      );
    } else {
      await WorkManagerService.cancel(WorkIds.afternoon);
    }

    if (_enableEvening) {
      await WorkManagerService.scheduleDaily(
        uniqueName: WorkIds.evening,
        hour: _eveningTime.hour,
        minute: _eveningTime.minute,
      );
    } else {
      await WorkManagerService.cancel(WorkIds.evening);
    }
  }

  /*Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      // Ouvre la popup native d'évaluation
      await inAppReview.requestReview();
    } else {
      // Ouvre la page Play Store (après publication officielle)
      await inAppReview.openStoreListing(
        appStoreId: '', // pas utilisé sur Android
      );
    }
  }*/

  Future<void> _saveAll() async {
    final prefs = UserPrefs();

    await prefs.setThemeMode(_selectedTheme);
    await prefs.setLengthFilter(_lengthFilter);

    await prefs.setEnableMorning(_enableMorning);
    await prefs.setEnableAfternoon(_enableAfternoon);
    await prefs.setEnableEvening(_enableEvening);

    await prefs.setMorningTime(_morningTime);
    await prefs.setAfternoonTime(_afternoonTime);
    await prefs.setEveningTime(_eveningTime);

    await _syncBackgroundSchedules();

    // ✅ Marquer les réglages comme complétés
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('settings_completed', true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ بنجاح')),
    );

    // ✅ Remplacer toute la pile par /home (pas de pop → pas d’écran noir)
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _openPrivacy() async {
    // ⚠️ Mets ici exactement l’URL qui répond (index.html ou privacy_ar.html)
    final uri = Uri.parse(
      'https://rahmaapps.github.io/allahomairhamabi/privacy_ar.html',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح صفحة سياسة الخصوصية'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء فتح الصفحة'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
        ),

        // ✅ Corps : seul le contenu défile
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: GestureDetector(
            // Fermer le clavier au tap
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: EdgeInsets.only(
                // Laisse de la place si le clavier est ouvert
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Le contenu qui scrolle
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: _buildSettingsList(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),

        // ✅ Bouton "حفظ" FIXÉ en bas (toujours visible)
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ',style: TextStyle(color: Colors.white,fontSize: 20),),
                onPressed: _saveAll,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit la liste scrollable : tout ton contenu existant,
  /// SANS le bouton "حفظ" (désormais fixé en bas).
  List<Widget> _buildSettingsList(BuildContext context) {
    return [

      const SizedBox(height: 32),
      const _SectionTitle('معلومات شخصية'),
      const SizedBox(height: 8),

      TextField(
        controller: _personNameController,

        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        autofocus: false,
        enableSuggestions: true,
        autocorrect: false,

        onChanged: (value) {
          UserPrefs.savePersonName(value);
        },

        decoration: const InputDecoration(

          labelText: 'اسم الشخص',
          hintText: 'مثال: أحمد، فاطمة...',

          border: OutlineInputBorder(),
        ),
      ),

      const SizedBox(height: 24), // ✅ ESPACE ENTRE LES BLOC

      // const _SectionTitle('الفترات (إشعارات)'),
      const SizedBox(height: 8),

      _PeriodTile(
        title: 'الصباح',
        enabled: _enableMorning,
        time: _morningTime,
        onToggle: (v) async {
          setState(() => _enableMorning = v);
          await UserPrefs().setEnableMorning(v);
          await _syncBackgroundSchedules();
        },
        onPickTime: () async {
          await _pickTime(
            initial: _morningTime,
            onPicked: (t) async {
              setState(() => _morningTime = t);
              await UserPrefs().setMorningTime(t);
              await _syncBackgroundSchedules();
            },
          );
        },
      ),
      _PeriodTile(
        title: 'بعد الظهر',
        enabled: _enableAfternoon,
        time: _afternoonTime,
        onToggle: (v) async {
          setState(() => _enableAfternoon = v);
          await UserPrefs().setEnableAfternoon(v);
          await _syncBackgroundSchedules();
        },
        onPickTime: () async {
          await _pickTime(
            initial: _afternoonTime,
            onPicked: (t) async {
              setState(() => _afternoonTime = t);
              await UserPrefs().setAfternoonTime(t);
              await _syncBackgroundSchedules();
            },
          );
        },
      ),
      _PeriodTile(
        title: 'المساء',
        enabled: _enableEvening,
        time: _eveningTime,
        onToggle: (v) async {
          setState(() => _enableEvening = v);
          await UserPrefs().setEnableEvening(v);
          await _syncBackgroundSchedules();
        },
        onPickTime: () async {
          await _pickTime(
            initial: _eveningTime,
            onPicked: (t) async {
              setState(() => _eveningTime = t);
              await UserPrefs().setEveningTime(t);
              await _syncBackgroundSchedules();
            },
          );
        },
      ),

      const SizedBox(height: 32),

      const _SectionTitle('الثيم'),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('الوضع', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedTheme,
            items: const [
              DropdownMenuItem(value: 'system', child: Text('حسب النظام')),
              DropdownMenuItem(value: 'light', child: Text('فاتح')),
              DropdownMenuItem(value: 'dark', child: Text('داكن')),
            ],
            onChanged: (v) async {
              if (v == null) return;
              setState(() => _selectedTheme = v);
              final notifier =
              Provider.of<ThemeNotifier>(context, listen: false);
              await notifier.setTheme(v);
            },
          ),
        ],
      ),
      const SizedBox(height: 24),

      /* Paramètre désactivé pour le moment
      const _SectionTitle('الطول المفضّل'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('الكل'),
            selected: _lengthFilter == 'all',
            onSelected: (s) async {
              if (!s) return;
              setState(() => _lengthFilter = 'all');
              await UserPrefs().setLengthFilter('all');
            },
          ),
          ChoiceChip(
            label: const Text('قصيرة'),
            selected: _lengthFilter == 'short',
            onSelected: (s) async {
              if (!s) return;
              setState(() => _lengthFilter = 'short');
              await UserPrefs().setLengthFilter('short');
            },
          ),
          ChoiceChip(
            label: const Text('طويلة'),
            selected: _lengthFilter == 'long',
            onSelected: (s) async {
              if (!s) return;
              setState(() => _lengthFilter = 'long');
              await UserPrefs().setLengthFilter('long');
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      */

      /* === تقييم التطبيق ===
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E8449), // أخضر جميل
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.star_rate_rounded, color: Colors.white),
          label: const Text(
            'تقييم التطبيق',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: _rateApp,
        ),
      ),*/

      const SizedBox(height: 32),

// ==== Bouton "حول التطبيق" ====
      ListTile(
        leading: const Icon(Icons.info, color: Colors.blueGrey),
        title: const Text(
          'حول التطبيق',
          style: TextStyle(fontSize: 18),
        ),
        onTap: () async {
          final uri = Uri.parse(
              'https://rahmaapps.github.io/allahomairhamabi/'
          );
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تعذّر فتح صفحة حول التطبيق')),
            );
          }
        },
      ),

      const SizedBox(height: 20),

      // === سياسة الخصوصية ===
      ListTile(
        leading: const Icon(Icons.privacy_tip),
        title: const Text(
          'سياسة الخصوصية',
          style: TextStyle(fontSize: 18),
        ),
        onTap: _openPrivacy,
      ),

      const SizedBox(height: 8),

      // ⚠️ Ne PAS remettre le bouton "حفظ" ici :
      // Il est maintenant fixé en bas via bottomNavigationBar.
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final String title;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  const _PeriodTile({
    required this.title,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text('الساعة: $timeLabel'),
        trailing: Switch(
          value: enabled,
          onChanged: onToggle,
        ),
        onTap: onPickTime,
      ),
    );
  }
}