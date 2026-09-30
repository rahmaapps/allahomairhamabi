// LOT RENAMING — garde-fous du nom commercial « اللهم ارحم أحبّتي ».
//
// Détecte les oublis futurs sur les surfaces de branding (Home, signature
// de partage, texte « مشاركة التطبيق », nom Android) sans toucher à la
// personnalisation par proche, qui doit continuer à produire
// « اللهم ارحم أبي / أمي … » dans le texte des douʿās.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/app_branding.dart';
import 'package:test_1/dua_personalizer.dart';
import 'package:test_1/home_screen.dart';
import 'package:test_1/settings_screen.dart';
import 'package:test_1/widgets/app_bar.dart';

/// Retire le tashkīl et le tatweel pour comparer sans tenir compte des
/// diacritiques (« اللَّهُمَّ ارْحَمْ أَبِي » == « اللهم ارحم أبي »).
String _stripDiacritics(String s) =>
    s.replaceAll(RegExp('[ً-ْٰـ]'), '');

final _oldBrand = RegExp(r'ارحم\s+[أاإ]بي');

void main() {
  group('AppBranding', () {
    test('nom, descripteur et signature officiels', () {
      expect(AppBranding.appName, 'اللهم ارحم أحبّتي');
      expect(AppBranding.descriptor, 'دعاء للميت');
      expect(AppBranding.shareAttributionSuffix,
          '\n\n— من تطبيق اللهم ارحم أحبّتي —');
    });

    test('« مشاركة التطبيق » : nouveau nom, descripteur, lien Play inchangé',
        () {
      const text = SettingsScreen.shareAppText;
      expect(text, startsWith('${AppBranding.appName}\n'));
      expect(text, contains(AppBranding.descriptor));
      expect(text, isNot(contains('لوالدي')));
      expect(
        text,
        contains(
            'https://play.google.com/store/apps/details?id=com.joumane.allahomairhamabi'),
      );
    });
  });

  testWidgets('titre du Home = nom commercial', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppTopBar>(find.byType(AppTopBar));
    expect(appBar.title, AppBranding.appName);
  });

  group('Android', () {
    test('app_name = nom commercial, référencé par le manifeste', () {
      final strings =
          File('android/app/src/main/res/values/strings.xml').readAsStringSync();
      expect(
        strings,
        contains('<string name="app_name">${AppBranding.appName}</string>'),
      );

      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:label="@string/app_name"'));
      // Identifiant technique historique : inchangé par le rebranding.
      expect(manifest, contains('package="com.joumane.allahomairhamabi"'));
    });
  });

  test('ancien nom absent du code applicatif (hors douʿās personnalisées)', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..add(File('android/app/src/main/res/values/strings.xml'));

    final offenders = <String>[
      for (final f in sources)
        if (_oldBrand.hasMatch(_stripDiacritics(f.readAsStringSync()))) f.path,
    ];
    expect(offenders, isEmpty);
  });

  group('personnalisation préservée', () {
    test('père et mère restent personnalisés', () {
      expect(
        DuaPersonalizer.personalize(
            'اللهم ارحم أبي', 'father', {'father': 'Youssef'}),
        'اللهم ارحم أبي Youssef',
      );
      expect(
        DuaPersonalizer.personalize(
            'اللهم ارحم أمي', 'mother', {'mother': 'Fatima'}),
        'اللهم ارحم أمي Fatima',
      );
    });

    test('la signature n\'est jamais réécrite par la personnalisation', () {
      const keys = [
        'father', 'mother', 'parents', 'grandfather', 'grandmother',
        'brother', 'sister', 'son', 'daughter', 'husband', 'wife',
      ];
      for (final k in keys) {
        expect(
          DuaPersonalizer.personalize(
              AppBranding.shareAttributionSuffix, k, {k: 'X'}),
          AppBranding.shareAttributionSuffix,
          reason: k,
        );
      }
    });
  });
}
