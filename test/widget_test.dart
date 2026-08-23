// Test smoke minimal, adapté au point d'entrée réel de l'application
// (MyApp requiert `initialRoute`, fourni ici via la route '/home' qui ne
// dépend d'aucun plugin natif — contrairement à '/settings', qui initialise
// les notifications/Workmanager et n'est pas mockable dans un simple
// flutter_test sans mocking de plateforme).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/main.dart';
import 'package:test_1/theme_notifier.dart';

void main() {
  testWidgets('MyApp se construit sans exception sur la route /home',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => ThemeNotifier(),
        child: const MyApp(initialRoute: '/home'),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
