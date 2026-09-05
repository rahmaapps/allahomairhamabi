// lib/notification_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un callback UI (foreground) appelé quand l’utilisateur clique la notification
typedef NotificationActionHandler = void Function(String? actionId, String? payload);

/// Service singleton pour gérer les notifications natives
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  /// 🔔 Hook assigné depuis main.dart pour router les actions en FOREGROUND
  static NotificationActionHandler? onAction;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // IDs des canaux
  static const String channelMorning = 'channel_morning';
  static const String channelAfternoon = 'channel_afternoon';
  static const String channelEvening = 'channel_evening';

  /// Initialisation (à appeler très tôt, ex: dans `main()`).
  ///
  /// `requestPermission` (`true` par défaut — comportement historique
  /// inchangé pour tout appelant existant, ex. `SettingsScreen`) sépare
  /// l'amorçage du plugin — toujours effectué, silencieux, création des
  /// canaux Android — de la demande de permission runtime elle-même, seul
  /// déclencheur possible d'un dialogue système. `main()` passe `false`
  /// pour un tout premier lancement (LOT 3.E.1 correction — « aucun
  /// dialogue au premier lancement ») ; c'est alors `OnboardingScreen` qui
  /// déclenche la demande lui-même, une seule fois, via
  /// [requestPermissionIfNeeded].
  Future<void> initialize({bool requestPermission = true}) async {
    if (_initialized) {
      if (requestPermission && Platform.isAndroid) {
        await _requestAndroidNotificationsPermissionIfNeeded();
      }
      return;
    }

    // ✅ Icône par défaut (évite d’avoir à la redéfinir sur chaque notification)
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

    await _plugin.initialize(
      initSettings,
      // Foreground / quand l’UI est prête
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (kDebugMode) {
          // Affiche 'actionId' quand on clique un bouton; 'null' si tap sur le corps
          print('[Notifications] Tap: payload=${response.payload}, action=${response.actionId}');
        }

        // Appel direct du hook UI si disponible
        NotificationService.onAction?.call(response.actionId, response.payload);

        // On mémorise également, pour un éventuel traitement ultérieur
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_notification_action', response.actionId ?? '');
        await prefs.setString('last_notification_payload', response.payload ?? '');
      },

      // Background / app en arrière-plan ou tuée
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 🔐 Android 13+ : demander la permission runtime (si demandée) puis
    // créer les canaux.
    if (Platform.isAndroid) {
      if (requestPermission) {
        await _requestAndroidNotificationsPermissionIfNeeded();
      }
      await _createAndroidChannels();
    }

    _initialized = true;
  }

  static Future<void> ensureInitialized({bool requestPermission = true}) async {
    await instance.initialize(requestPermission: requestPermission);
  }

  /// Déclenche seul la demande de permission runtime (Android), sans
  /// jamais toucher à l'amorçage du plugin (`initialize()` a déjà dû être
  /// appelé avant, depuis `main()`) — pensé pour être appelé sans risque
  /// depuis un écran (`OnboardingScreen`) sans relancer `_plugin.initialize()`.
  /// No-op si déjà accordée ou déjà tranchée par l'OS ; no-op hors Android.
  Future<void> requestPermissionIfNeeded() async {
    if (!Platform.isAndroid) return;
    await _requestAndroidNotificationsPermissionIfNeeded();
  }

  /// Demande la permission d'afficher des notifications (Android 13+)
  Future<void> _requestAndroidNotificationsPermissionIfNeeded() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    final enabledBefore = await androidImpl.areNotificationsEnabled() ?? false;
    if (!enabledBefore) {
      final granted = await androidImpl.requestNotificationsPermission() ?? false;
      if (kDebugMode) {
        final enabledAfter = await androidImpl.areNotificationsEnabled() ?? false;
        print('[Notifications][Android] requested=$granted, enabled=$enabledAfter');
      }
    } else if (kDebugMode) {
      print('[Notifications][Android] already enabled');
    }
  }

  /// Lecture seule du statut actuel de la permission de notifications
  /// (Android) — ne redemande jamais, `initialize()` l'a déjà fait au
  /// démarrage (LOT 3.E.1 : ligne d'info si refusée à l'Onboarding, §4
  /// Onboarding : « permission refusée → une seule ligne d'information,
  /// aucun dialogue, aucune relance »). `true` par défaut hors Android ou
  /// si le plugin n'est pas résolvable (ex. `flutter_test` sans mock de
  /// plateforme) — mieux vaut ne pas afficher la ligne que bloquer l'écran.
  Future<bool> notificationsPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return true;
      return await androidImpl.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Crée les canaux Android (Android 8+)
  Future<void> _createAndroidChannels() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

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
      await androidImpl.createNotificationChannel(ch);
    }
  }

  /// Affiche une notification (Android/iOS)
  Future<void> show({
    required String channelId,
    required int notificationId,
    required String title,
    required String body,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    // ✅ Ne PAS remettre `icon:` ici (elle est déjà définie à l’initialisation)
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Notifications', // Sur Android < 8 : utilisé ; sur 8+ le nom vient du canal
      channelDescription: null,
      priority: Priority.high,
      importance: Importance.high,
      actions: actions,
      styleInformation: const DefaultStyleInformation(true, true),
      // autoCancel par défaut, modifiable si besoin
    );

    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(notificationId, title, body, details, payload: payload);
  }

  /// Helper : rappel par période (matin / après‑midi / soir)
  Future<void> showPeriodReminder({
    required String periodId, // 'period_morning' | 'period_afternoon' | 'period_evening'
    required int hour,
    required int minute,
  }) async {
    String channelId;
    String title;
    String body;
    int notiId;

    switch (periodId) {
      case 'period_morning':
        channelId = channelMorning;
        notiId = 101;
        title = '🌅 ابدأ يومك ببرّ والدك';
        body  = '🤲 ﴿وَقُل رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا﴾';
        break;

      case 'period_afternoon':
        channelId = channelAfternoon;
        notiId = 102;
        title = '🕊️ اذكر والدك بدعوة صادقة';
        body  = '📿 «أو ولدٌ صالحٌ يدعو له»';
        break;

      case 'period_evening':
      default:
        channelId = channelEvening;
        notiId = 103;
        title = '💛 اختم يومك بدعاء لوالدك';
        body  = '✨ ﴿رَبَّنَا اغْفِرْ لَنَا وَلِوَالِدَيْنَا﴾';
        break;
    }

    await show(
      channelId: channelId,
      notificationId: notiId,
      title: title,
      body: body,
      payload: periodId,
      actions: const [
        AndroidNotificationAction('open', 'فتح',
          showsUserInterface: true,   // <— ramène l’app en avant-plan
          cancelNotification: true,   // <— optionnel : ferme la notif
        ),
        AndroidNotificationAction('skip', 'تجاهل',
          showsUserInterface: true,  // <— ignorer en silence
          cancelNotification: true,
        ),
      ],
    );
  }
}

/// ---- HANDLER BACKGROUND (top-level, hors classe) ----
/// Appelé quand l’utilisateur clique depuis l’arrière-plan / app tuée.
/// ⚠️ Pas de navigation ici : on mémorise pour l’UI.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_notification_action', response.actionId ?? '');
  await prefs.setString('last_notification_payload', response.payload ?? '');
}