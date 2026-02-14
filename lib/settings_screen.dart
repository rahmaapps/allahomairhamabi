import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'user_prefs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---- Thème
  String _selectedTheme = "system"; // "system" | "light" | "dark"

  // ---- Longueur (hérite de ta logique existante)
  String _lengthFilter = "all"; // "all" | "short" | "long"

  // ---- Périodes (en cohérence avec tes méthodes existantes dans UserPrefs)
  bool _enableMorning = true;
  bool _enableAfternoon = false;
  bool _enableEvening = true;

  TimeOfDay _morningTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = UserPrefs();

    // Thème
    final th = await prefs.getThemeMode(); // "system" | "light" | "dark"

    // Longueur
    final lf = await prefs.getLengthFilter(); // "all" | "short" | "long"

    // Périodes
    final enM = await prefs.getEnableMorning();
    final enA = await prefs.getEnableAfternoon();
    final enE = await prefs.getEnableEvening();

    final tmM = await prefs.getMorningTime();
    final tmA = await prefs.getAfternoonTime();
    final tmE = await prefs.getEveningTime();

    setState(() {
      _selectedTheme = th;
      _lengthFilter = lf;

      _enableMorning = enM;
      _enableAfternoon = enA;
      _enableEvening = enE;

      _morningTime = tmM;
      _afternoonTime = tmA;
      _eveningTime = tmE;

      _loading = false;
    });
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
          textDirection: TextDirection.rtl, // RTL pour l'arabe
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (res != null) onPicked(res);
  }

  Future<void> _saveAll() async {
    final prefs = UserPrefs();

    // Thème
    await prefs.setThemeMode(_selectedTheme);

    // Longueur
    await prefs.setLengthFilter(_lengthFilter);

    // Périodes
    await prefs.setEnableMorning(_enableMorning);
    await prefs.setEnableAfternoon(_enableAfternoon);
    await prefs.setEnableEvening(_enableEvening);

    await prefs.setMorningTime(_morningTime);
    await prefs.setAfternoonTime(_afternoonTime);
    await prefs.setEveningTime(_eveningTime);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ بنجاح')),
    );
    Navigator.of(context).pop(); // revenir à l'écran précédent
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // -----------------------------
            // ثيم التطبيق
            // -----------------------------
            _SectionTitle('الثيم'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('الوضع', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedTheme,
                  items: const [
                    DropdownMenuItem(
                        value: 'system', child: Text('حسب النظام')),
                    DropdownMenuItem(
                        value: 'light', child: Text('فاتح')),
                    DropdownMenuItem(
                        value: 'dark', child: Text('داكن')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _selectedTheme = v);

                    final notifier = Provider.of<ThemeNotifier>(context, listen: false);
                    await notifier.setTheme(v);
                  }
                  ,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // -----------------------------
            // فلترة الطول
            // -----------------------------
            _SectionTitle('الطول المفضّل'),
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

            // -----------------------------
            // الفترات
            // -----------------------------
            _SectionTitle('الفترات (إشعارات)'),
            const SizedBox(height: 8),

            // صباح
            _PeriodTile(
              title: 'الصباح',
              enabled: _enableMorning,
              time: _morningTime,
              onToggle: (v) async {
                setState(() => _enableMorning = v);
                await UserPrefs().setEnableMorning(v);
              },
              onPickTime: () async {
                await _pickTime(
                  initial: _morningTime,
                  onPicked: (t) async {
                    setState(() => _morningTime = t);
                    await UserPrefs().setMorningTime(t);
                  },
                );
              },
            ),

            // بعد الظهر
            _PeriodTile(
              title: 'بعد الظهر',
              enabled: _enableAfternoon,
              time: _afternoonTime,
              onToggle: (v) async {
                setState(() => _enableAfternoon = v);
                await UserPrefs().setEnableAfternoon(v);
              },
              onPickTime: () async {
                await _pickTime(
                  initial: _afternoonTime,
                  onPicked: (t) async {
                    setState(() => _afternoonTime = t);
                    await UserPrefs().setAfternoonTime(t);
                  },
                );
              },
            ),

            // المساء
            _PeriodTile(
              title: 'المساء',
              enabled: _enableEvening,
              time: _eveningTime,
              onToggle: (v) async {
                setState(() => _enableEvening = v);
                await UserPrefs().setEnableEvening(v);
              },
              onPickTime: () async {
                await _pickTime(
                  initial: _eveningTime,
                  onPicked: (t) async {
                    setState(() => _eveningTime = t);
                    await UserPrefs().setEveningTime(t);
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // -----------------------------
            // حفظ
            // -----------------------------
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ'),
                onPressed: _saveAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// Widgets d'aide (privés)
// =========================

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