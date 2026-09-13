// lib/notification_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
  static const String channelEvening = 'channel_evening';
  static const String channelFriday = 'channel_friday';

  // IDs de notification des rappels planifiés (inchangés — voir
  // `showPeriodReminder` — exposés ici pour permettre l'annulation depuis
  // `SettingsScreen` sans dupliquer ces constantes).
  static const int notificationIdMorning = 101;
  static const int notificationIdEvening = 103;
  static const int notificationIdFriday = 104;

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

    // 🕐 Init du fuseau horaire — requis avant tout zonedSchedule().
    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

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

  /// Résout le fuseau IANA réel de l'appareil (ex. `Africa/Casablanca`) via
  /// `flutter_timezone` et le fixe comme `tz.local` — condition nécessaire
  /// pour que les rappels planifiés restent corrects à travers les
  /// transitions DST (notamment le motif inversé du Ramadan au Maroc, où
  /// `Africa/Casablanca` repasse temporairement à UTC+0).
  ///
  /// Repli sûr sur `tz.UTC` en cas d'échec (plateforme non supportée,
  /// identifiant renvoyé inconnu de la base IANA embarquée, etc.) — ne lève
  /// jamais d'exception. Ce repli n'est plus le cas nominal : c'est
  /// uniquement une sécurité si la détection native échoue. Aucun impact
  /// sur `_nextInstanceOfTime`/`_nextInstanceOfWeekday`, qui continuent de
  /// calculer l'instant absolu à partir de l'horloge locale réelle de
  /// l'appareil (`DateTime.now()`/`.toUtc()`) quel que soit le résultat ici
  /// — cette résolution ne fait qu'étiqueter correctement `tz.local` pour
  /// que le plugin natif (et tout futur usage direct de `tz.local`)
  /// reflète le vrai fuseau de l'utilisateur.
  Future<void> _configureLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[NotifDiag] _configureLocalTimezone() a échoué, repli sur UTC : $e');
      tz.setLocalLocation(tz.UTC);
    }
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
        channelEvening,
        'Rappels du soir',
        description: 'Notifications planifiées pour la période du soir',
        importance: Importance.defaultImportance,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        channelFriday,
        'Rappel du vendredi',
        description: 'Notification hebdomadaire planifiée le vendredi',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      ),
    ];

    for (final ch in channels) {
      await androidImpl.createNotificationChannel(ch);
    }
  }

  /// Vérifie si l'app est actuellement autorisée à planifier des alarmes
  /// exactes (Android 12+, `SCHEDULE_EXACT_ALARM`). `true` hors Android
  /// uniquement (aucune restriction sur cette plateforme). Dans tout cas
  /// d'incertitude — plugin non résolvable, API indisponible sur cette
  /// version, erreur quelconque — retourne `false` : mieux vaut se replier
  /// sur le mode inexact (qui ne peut pas planter, aucune permission
  /// requise) que de présumer le mode exact autorisé et risquer un échec
  /// silencieux de `zonedSchedule()` (voir [_scheduleZoned], qui retente de
  /// toute façon en inexact si le mode exact échoue réellement à
  /// l'exécution — cette méthode ne fait que fixer la préférence initiale).
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return false;
      return await androidImpl.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Demande à l'utilisateur d'accorder l'alarme exacte (Android 12+,
  /// `SCHEDULE_EXACT_ALARM`). Il n'existe pas de dialogue applicatif pour
  /// cette permission : l'API native ouvre l'écran système « Alarmes et
  /// rappels ». Depuis Android 14, elle n'est plus accordée
  /// automatiquement à une app hors catégorie horloge/agenda — sans cet
  /// appel, [canScheduleExactAlarms] reste `false` et [_scheduleZoned] se
  /// replie systématiquement sur `inexactAllowWhileIdle` (fenêtre de
  /// livraison d'environ 1 h côté AlarmManager).
  ///
  /// Ne lève jamais d'exception et ne modifie pas la planification : le
  /// repli exact → inexact reste inchangé. Retourne l'état **effectif**
  /// relu après la demande (`true` si l'alarme exacte est désormais
  /// autorisée), ce qui permet à l'écran Paramètres de réagir au résultat
  /// réel plutôt qu'à la valeur de retour de l'appel natif — l'utilisateur
  /// pouvant quitter l'écran système sans rien accorder.
  Future<bool> requestExactAlarmsPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return false;
      await androidImpl.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('[NotifDiag] requestExactAlarmsPermission() a ÉCHOUÉ : $e');
      return false;
    }
    return canScheduleExactAlarms();
  }

  /// Prochaine occurrence de `hour:minute` (aujourd'hui si pas encore
  /// passée, sinon demain). La récurrence quotidienne est ensuite déléguée
  /// nativement à `matchDateTimeComponents: DateTimeComponents.time` — pas
  /// de recalcul manuel après le premier déclenchement (contrairement à
  /// l'ancien mécanisme WorkManager).
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledLocal = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduledLocal.isAfter(now)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduledLocal.toUtc(), tz.UTC);
  }

  /// Même principe que [_nextInstanceOfTime], ancré sur le prochain jour de
  /// semaine [weekday] (`DateTime.friday`, etc.) à `hour:minute`. Récurrence
  /// hebdomadaire déléguée nativement à
  /// `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`.
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = DateTime.now();
    final daysUntil = (weekday - now.weekday) % 7;
    var scheduledLocal =
        DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: daysUntil));
    if (!scheduledLocal.isAfter(now)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 7));
    }
    return tz.TZDateTime.from(scheduledLocal.toUtc(), tz.UTC);
  }

  /// Contenu (canal/id/titre/corps) d'un rappel par période — mêmes valeurs
  /// que [showPeriodReminder], dupliquées volontairement ici (fonction
  /// interne dédiée aux rappels *planifiés*) plutôt que de modifier
  /// [showPeriodReminder], laissé inchangé.
  ({String channelId, int notificationId, String title, String body}) _reminderContentFor(
    String periodId,
  ) {
    switch (periodId) {
      case 'period_morning':
        return (
          channelId: channelMorning,
          notificationId: notificationIdMorning,
          title: '🌅 ابدأ يومك ببرّ والدك',
          body: '🤲 ﴿وَقُل رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا﴾',
        );
      case 'period_friday':
        return (
          channelId: channelFriday,
          notificationId: notificationIdFriday,
          title: '🕌 يوم الجمعة مبارك',
          body: '🤲 أكثر من الدعاء لوالدك في هذا اليوم المبارك',
        );
      case 'period_evening':
      default:
        return (
          channelId: channelEvening,
          notificationId: notificationIdEvening,
          title: '💛 اختم يومك بدعاء لوالدك',
          body: '✨ ﴿رَبَّنَا اغْفِرْ لَنَا وَلِوَالِدَيْنَا﴾',
        );
    }
  }

  /// Détails Android/iOS d'un rappel planifié — mêmes actions ("فتح"/
  /// "تجاهل") que [showPeriodReminder].
  NotificationDetails _reminderDetails(String channelId) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Notifications',
      channelDescription: null,
      priority: Priority.high,
      importance: Importance.high,
      actions: const [
        AndroidNotificationAction(
          'open',
          'فتح',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'skip',
          'تجاهل',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
      styleInformation: const DefaultStyleInformation(true, true),
    );

    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Planifie le rappel quotidien (`period_morning` / `period_evening`) à
  /// heure fixe. Récurrence quotidienne native
  /// (`matchDateTimeComponents: DateTimeComponents.time`) : pas de
  /// replanification manuelle après chaque déclenchement. Ne lève jamais
  /// d'exception — voir [_scheduleZoned]. Retourne `true` si le rappel a
  /// bien été programmé auprès de l'OS (mode exact ou repli inexact),
  /// `false` si la planification a réellement échoué (l'appelant ne doit
  /// alors pas considérer ce rappel comme activé).
  Future<bool> scheduleDailyReminder({
    required String periodId,
    required int hour,
    required int minute,
  }) async {
    return _scheduleZoned(
      content: _reminderContentFor(periodId),
      scheduledDate: _nextInstanceOfTime(hour, minute),
      matchDateTimeComponents: DateTimeComponents.time,
      periodId: periodId,
    );
  }

  /// Planifie le rappel hebdomadaire (vendredi) — même mécanisme que
  /// [scheduleDailyReminder], ancré sur [weekday] (`DateTime.friday`) +
  /// heure, récurrence hebdomadaire native
  /// (`matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`). Même
  /// garantie : jamais d'exception, `true`/`false` selon le succès réel.
  Future<bool> scheduleWeeklyReminder({
    required String periodId,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    return _scheduleZoned(
      content: _reminderContentFor(periodId),
      scheduledDate: _nextInstanceOfWeekday(weekday, hour, minute),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      periodId: periodId,
    );
  }

  /// Planifie effectivement un rappel via `zonedSchedule`, avec repli
  /// immédiat en mode inexact si le mode exact échoue réellement à
  /// l'exécution (pas seulement supposé indisponible par
  /// [canScheduleExactAlarms]) — jamais d'exception propagée à l'appelant,
  /// quel que soit le point d'échec (`cancel` ou `zonedSchedule`). Annule
  /// d'abord tout rappel déjà planifié pour ce même id — nécessaire
  /// notamment lors d'un changement d'heure, pour éviter un `PendingIntent`
  /// orphelin ; un échec de cette annulation (ex. rien à annuler) est
  /// journalisé mais n'empêche pas la tentative de planification.
  Future<bool> _scheduleZoned({
    required ({String channelId, int notificationId, String title, String body}) content,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents matchDateTimeComponents,
    required String periodId,
  }) async {
    // ⚠️ INSTRUMENTATION TEMPORAIRE DE DIAGNOSTIC (release) — à retirer une
    // fois la cause de l'échec de planification confirmée. Volontairement
    // NON gardée par `kDebugMode` : doit rester visible dans `adb logcat`
    // sur un build --release.
    debugPrint(
      '[NotifDiag] $periodId : notificationId=${content.notificationId}, '
      'channelId=${content.channelId}, scheduledDate=$scheduledDate, '
      'location=${scheduledDate.location.name}, tz.local=${tz.local.name}, '
      'matchDateTimeComponents=$matchDateTimeComponents',
    );

    try {
      await _plugin.cancel(content.notificationId);
      debugPrint('[NotifDiag] $periodId : cancel() OK');
    } catch (e, s) {
      debugPrint('[NotifDiag] $periodId : cancel() a ÉCHOUÉ : $e\n$s');
    }

    final details = _reminderDetails(content.channelId);

    final canExact = await canScheduleExactAlarms();
    debugPrint('[NotifDiag] $periodId : canScheduleExactNotifications() -> $canExact');

    Future<bool> attempt(AndroidScheduleMode mode) async {
      debugPrint('[NotifDiag] $periodId : tentative zonedSchedule() en mode $mode');
      try {
        await _plugin.zonedSchedule(
          content.notificationId,
          content.title,
          content.body,
          scheduledDate,
          details,
          payload: periodId,
          androidScheduleMode: mode,
          // `scheduledDate` est un instant absolu (converti via `.toUtc()`
          // dans `_nextInstanceOfTime`/`_nextInstanceOfWeekday`), pas une
          // heure murale à réinterpréter au moment du déclenchement —
          // `absoluteTime` est donc la valeur sémantiquement correcte ici.
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        debugPrint('[NotifDiag] $periodId : zonedSchedule() OK en mode $mode');
        return true;
      } catch (e, s) {
        debugPrint('[NotifDiag] $periodId : zonedSchedule() a ÉCHOUÉ en mode $mode : $e\n$s');
        return false;
      }
    }

    if (canExact) {
      debugPrint('[NotifDiag] $periodId : mode retenu = exactAllowWhileIdle');
      if (await attempt(AndroidScheduleMode.exactAllowWhileIdle)) return true;
      // Le mode exact était censé être autorisé mais a réellement échoué à
      // l'exécution (ex. permission révoquée entre la vérification et
      // l'appel) — repli immédiat en mode inexact plutôt qu'abandonner.
      debugPrint('[NotifDiag] $periodId : repli sur inexactAllowWhileIdle');
      return attempt(AndroidScheduleMode.inexactAllowWhileIdle);
    }

    debugPrint('[NotifDiag] $periodId : mode retenu = inexactAllowWhileIdle (exact indisponible)');
    return attempt(AndroidScheduleMode.inexactAllowWhileIdle);
  }

  /// Annule un rappel planifié (quotidien ou hebdomadaire) par son id de
  /// notification (voir `notificationIdMorning`/`notificationIdEvening`/
  /// `notificationIdFriday`). Ne lève jamais d'exception ; retourne `false`
  /// en cas d'erreur inattendue (journalisée), `true` sinon (y compris s'il
  /// n'y avait rien à annuler).
  Future<bool> cancelReminder(int notificationId) async {
    try {
      await _plugin.cancel(notificationId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[Notifications] cancel($notificationId) a échoué : $e');
      }
      return false;
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

  /// Helper : rappel par période (matin / soir / vendredi)
  Future<void> showPeriodReminder({
    required String periodId, // 'period_morning' | 'period_evening' | 'period_friday'
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

      case 'period_friday':
        channelId = channelFriday;
        notiId = 104;
        title = '🕌 يوم الجمعة مبارك';
        body  = '🤲 أكثر من الدعاء لوالدك في هذا اليوم المبارك';
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