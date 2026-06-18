import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'settings_screen.dart';
import 'notification_service.dart';
import 'theme_notifier.dart';

// Clé de navigation globale (pour naviguer depuis les callbacks)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de notifications
  await NotificationService.ensureInitialized();

  // Choisir l'écran initial en fonction d'un flag persistant
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool('settings_completed') ?? false;
  final initialRoute = completed ? '/home' : '/settings';

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
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

      initialRoute: initialRoute,
      routes: {
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
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