// lib/services/notifications_service.dart
//
// Version 2026 optimisée pour ton projet.
// - Compatible avec ton DuaRepository (length + category obligatoires)
// - JSON arabe (length = "قصيرة" / "طويلة")
// - Notifications immédiates OK
// - Notifications planifiées encore gelées (problème Samsung)
// - TZ locale sans flutter_native_timezone
//
// Dépendances nécessaires :
// flutter_local_notifications, timezone

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../dua_repository.dart';
import '../user_prefs.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  static NotificationService get I => _instance;
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // IDs stables
  static const int kTestId = 999;

  static const String _channelId = 'daily_channel_id';
  static const String _channelName = 'Daily Notifications';
  static const String _channelDesc = 'Dou‘ā من التطبيق';

  static const AndroidNotificationDetails _androidDetails =
  AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    if (_initialized) return;

    // Timezones
    try {
      tz.initializeTimeZones();
      debugPrint("[NOTIF] Timezones initialisées.");
    } catch (e) {
      debugPrint("[NOTIF][ERR] init timezones: $e");
    }

    // Init plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Android 13+ : POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        final granted = await androidImpl?.requestNotificationsPermission();
        debugPrint("[NOTIF] Permission POST_NOTIFICATIONS = $granted");
      } catch (e) {
        debugPrint("[NOTIF][WARN] requestNotificationsPermission: $e");
      }
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATION — IMMEDIATE
  //
  // showNow() utilise :
  // - lengthFilter : UserPrefs si non fourni
  // - categoryFilter : "normal" par défaut (aligné HomeScreen)
  //
  // ---------------------------------------------------------------------------
  Future<void> showNow({
    String? title,
    String? body,
    String? lengthFilter,
    String? categoryFilter,
  }) async {
    await init();

    final effectiveTitle = title ?? 'دعاء اليوم';

    // 1) Si body fourni → on l’utilise
    // 2) Sinon → on choisit un Doua via ton Repository
    String finalBody;
    if (body != null) {
      finalBody = body;
    } else {
      final prefs = UserPrefs.instance;
      final lf = lengthFilter ?? await prefs.getLengthFilter();
      final cf = categoryFilter ?? "normal"; // fallback propre

      final dua = await DuaRepository().getRandomDuaFiltered(
        lengthFilter: lf,
        categoryFilter: cf,
      );

      finalBody = dua?.text ?? '...';
    }

    await _plugin.show(
      777, // ID ponctuel
      effectiveTitle,
      finalBody,
      const NotificationDetails(android: _androidDetails),
    );
  }

  // ---------------------------------------------------------------------------
  // NOTIFS PLANIFIÉES GELÉES
  //
  // Tu as choisi (à juste titre) de ne pas les activer tant que le problème
  // Samsung A53 n’est pas géré (deep doze + exact alarms).
  //
  // Je laisse ici une version stable mais *non utilisée* pour plus tard.
  // ---------------------------------------------------------------------------

  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay timeOfDay,
    String? lengthFilter,
    String? categoryFilter,
  }) async {
    await init();

    final prefs = UserPrefs.instance;

    // Préparation des filtres
    final lf = lengthFilter ?? await prefs.getLengthFilter();
    final cf = categoryFilter ?? "normal";

    final dua = await DuaRepository().getRandomDuaFiltered(
      lengthFilter: lf,
      categoryFilter: cf,
    );

    final body = dua?.text ?? "...";

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // Si l'heure d'aujourd'hui est déjà passée → demain
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint("[SCHED] id=$id → ${scheduled.toLocal()}");

    await _plugin.zonedSchedule(
      id,
      'دعاء اليوم',
      body,
      scheduled,
      const NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ---------------------------------------------------------------------------
  // RESCHEDULE (non utilisée tant que Samsung A53 bloque)
  // ---------------------------------------------------------------------------
  Future<void> rescheduleFromPrefs() async {
    await init();

    debugPrint("[NOTIF] rescheduleFromPrefs() ignoré pour Samsung.");

    // On désactive volontairement tous les schedules
    await _plugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // TEST : notification dans 1 minute (utile debug Pixel)
  // ---------------------------------------------------------------------------
  Future<DateTime> scheduleInOneMinuteTest() async {
    await init();

    final prefs = UserPrefs.instance;
    final lf = await prefs.getLengthFilter();
    final cf = "normal";

    final dua = await DuaRepository().getRandomDuaFiltered(
      lengthFilter: lf,
      categoryFilter: cf,
    );

    final body = dua?.text ?? "...";

    final nowTz = tz.TZDateTime.now(tz.local);
    final scheduled = nowTz.add(const Duration(minutes: 1));

    await _plugin.zonedSchedule(
      kTestId,
      "اختبار الإشعار",
      body,
      scheduled,
      const NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint("[NOTIF][TEST] id=$kTestId → ${scheduled.toLocal()}");

    return scheduled.toLocal();
  }
}