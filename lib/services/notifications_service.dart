// lib/notification_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service singleton pour gérer les notifications natives
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // IDs des canaux
  static const String channelMorning = 'channel_morning';
  static const String channelAfternoon = 'channel_afternoon';
  static const String channelEvening = 'channel_evening';

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notification');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Routage par action/payload si tu veux
          if (kDebugMode) {
            print('[Notifications] Tap sur notification: ${response.payload} action=${response.actionId}');
          }
        });

    // Android 13+ : permission runtime
    /*final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestPermission();
    }*/

    // Créer les canaux Android
    await _createAndroidChannels();

    _initialized = true;
  }

  static Future<void> ensureInitialized() async {
    await instance.initialize();
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channels = <AndroidNotificationChannel>[
      const AndroidNotificationChannel(
        channelMorning,
        'Rappels du matin',
        description: 'Notifications planifiées pour la période du matin',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        channelAfternoon,
        'Rappels de l\'après‑midi',
        description: 'Notifications planifiées pour la période de l\'après‑midi',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        channelEvening,
        'Rappels du soir',
        description: 'Notifications planifiées pour la période du soir',
        importance: Importance.defaultImportance,
        playSound: true,
        showBadge: true,
      ),
    ];

    for (final ch in channels) {
      await android.createNotificationChannel(ch);
    }
  }

  /// Affiche une notification sur le canal correspondant à [channelId].
  Future<void> show({
    required String channelId,
    required int notificationId,
    required String title,
    required String body,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      '', // ignoré depuis Android 8+ (défini par le canal)
      channelDescription: null,
      priority: Priority.high,
      importance: Importance.high,
      icon: '@drawable/ic_stat_notification',
      actions: actions,
      styleInformation: const DefaultStyleInformation(true, true),
    );

    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(notificationId, title, body, details, payload: payload);
  }

  /// Helper pour afficher selon période
  Future<void> showPeriodReminder({
    required String periodId, // 'period_morning' | 'period_afternoon' | 'period_evening'
    required int hour,
    required int minute,
  }) async {
    String channelId;
    String prettyPeriod;
    int notiId;
    switch (periodId) {
      case 'period_morning':
        channelId = channelMorning;
        prettyPeriod = 'الصباح';
        notiId = 101;
        break;
      case 'period_afternoon':
        channelId = channelAfternoon;
        prettyPeriod = 'بعد الظهر';
        notiId = 102;
        break;
      case 'period_evening':
      default:
        channelId = channelEvening;
        prettyPeriod = 'المساء';
        notiId = 103;
        break;
    }

    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');

    await show(
      channelId: channelId,
      notificationId: notiId,
      title: 'تذكير — $prettyPeriod',
      body: 'حان وقت تذكيرك — $hh:$mm',
      payload: periodId,
      actions: const [
        AndroidNotificationAction('open', 'فتح'),
        AndroidNotificationAction('skip', 'تجاهل'),
      ],
    );
  }
}