import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'settings_screen.dart';
import 'notification_service.dart';
import 'theme/app_theme.dart';
import 'theme_notifier.dart';
import 'user_prefs.dart';

// Clé de navigation globale (pour naviguer depuis les callbacks)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Choisir l'écran initial en fonction d'un flag persistant — lu avant
  // d'initialiser les notifications (voir juste en dessous).
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool('settings_completed') ?? false;

  // Initialiser le service de notifications. La demande de permission
  // système ne doit jamais apparaître avant que l'utilisateur n'ait vu
  // l'Onboarding (LOT 3.E.1 correction — « aucun dialogue au premier
  // lancement ») : elle n'est déclenchée automatiquement ici que pour un
  // utilisateur ayant déjà terminé l'Onboarding lors d'une session
  // précédente (comportement au démarrage inchangé pour ce cas). Pour un
  // tout premier lancement, c'est `OnboardingScreen` qui la déclenche,
  // une seule fois, à l'écran « تذكير يومي؟ ».
  await NotificationService.ensureInitialized(requestPermission: completed);

  // V1.2 — migration vers les ids globaux uniques : les anciens favoris
  // (ambigus par nature, voir user_prefs.dart) sont effacés proprement une
  // seule fois. `favoritesWereReset` sert uniquement à informer l'utilisateur.
  final favoritesWereReset =
      await UserPrefs.migrateFavoritesToGlobalIdsIfNeeded();

  // LOT [reboot/exactAllowWhileIdle] — `workmanager` retiré du projet (plus
  // aucun rôle : les rappels sont désormais planifiés via
  // `NotificationService`/`zonedSchedule`, avec reprise après reboot gérée
  // nativement par le plugin `flutter_local_notifications` — voir
  // AndroidManifest.xml). Le nettoyage de compatibilité de l'ancienne tâche
  // WorkManager « بعد الظهر » (LOT 3.G) devient donc sans objet : sans le
  // plugin `workmanager`, l'app ne peut plus piloter ni annuler cette tâche
  // native pré-existante de toute façon ; elle avait déjà été nettoyée pour
  // les installations existantes par plusieurs lots précédents.

  // Premier lancement → Onboarding dédié (LOT 3.E.1), plus SettingsScreen
  // (toujours accessible ensuite depuis HOME → ⋮ → « الإعدادات », route
  // '/settings' conservée telle quelle pour cet accès).
  final initialRoute = completed ? '/home' : '/onboarding';

  // Handler UI (foreground) pour les actions de notification
  NotificationService.onAction = (String? actionId, String? payload) async {
    // Petit délai pour s'assurer que Navigator/Scaffold sont prêts
    await Future<void>.delayed(const Duration(milliseconds: 10));

    switch (actionId) {
      case 'open':
        navigatorKey.currentState?.pushNamed('/home');
        break;

      case 'skip':
      // 👉 Retour visuel clair côté UI
        _showGlobalSnack('تم تجاهل التذكير — نسأل الله أن يرحم والدك.');
        break;

      default: // Tap sur le corps de la notif
        navigatorKey.currentState?.pushNamed('/home');
    }
  };

  // 👉 On enveloppe l'app avec le provider du thème
  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(), // chargera le mode depuis UserPrefs
      child: MyApp(initialRoute: initialRoute),
    ),
  );

  // Consommer une éventuelle action cliquée en arrière-plan (stockée par le background handler)
  await _consumePendingNotificationAction();

  // Message ponctuel et honnête si les anciens favoris ont été réinitialisés
  // (mise à jour majeure du catalogue — voir UserPrefs.migrateFavoritesToGlobalIdsIfNeeded)
  if (favoritesWereReset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGlobalSnack(
        'تم تحديث كبير في قاعدة الأدعية — تمت إعادة تعيين المفضلة القديمة، برجاء إضافة أدعيتك المفضلة من جديد.',
      );
    });
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // ⬇️ Lit le ThemeMode depuis le provider
    final theme = context.watch<ThemeNotifier>();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingNotificationAction();
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      // ⬇️ Active clairement les thèmes clair/sombre
      themeMode: theme.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      initialRoute: initialRoute,
      routes: {
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
  }
}

// Helpers pour SnackBar depuis la racine
void _showGlobalSnack(String text) {
  final ctx = navigatorKey.currentContext;
  if (ctx != null) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }
}

/// Lit l'action/payload posés par le handler background et navigue en conséquence
Future<void> _consumePendingNotificationAction() async {
  final prefs = await SharedPreferences.getInstance();
  final action = prefs.getString('last_notification_action') ?? '';
  final payload = prefs.getString('last_notification_payload') ?? '';

  // ✅ Correction de la condition (OR logique)
  if (action.isNotEmpty || payload.isNotEmpty) {
    // Nettoyer pour éviter un retraitement
    await prefs.remove('last_notification_action');
    await prefs.remove('last_notification_payload');

    // Router comme en foreground
    switch (action) {
      case 'open':
        navigatorKey.currentState?.pushNamed('/home');
        break;
      case 'skip':
        _showGlobalSnack('نسأل الله أن يرحم والدك… سنذكّرك لاحقًا إن شاء الله.');
        break;
      default:
        navigatorKey.currentState?.pushNamed('/home');
    }
  }
}