// lib/app_branding.dart
//
// Identité globale de l'application (LOT RENAMING) — source unique du nom
// commercial affiché. À ne pas confondre avec la personnalisation par
// proche (`PersonType`, `DuaPersonalizer`) : le douʿā personnalisé pour le
// père, la mère, etc. reste produit dynamiquement dans le texte des douʿās.
//
// Le nom Android sous l'icône vit dans
// `android/app/src/main/res/values/strings.xml` (`app_name`) et doit rester
// identique à [AppBranding.appName] (vérifié par test/app_branding_test.dart).

class AppBranding {
  AppBranding._();

  /// Nom commercial officiel (forme canonique, shadda sur « بّ » uniquement).
  static const String appName = 'اللهم ارحم أحبّتي';

  /// Descripteur officiel du produit.
  static const String descriptor = 'دعاء للميت';

  /// Signature ajoutée aux textes de douʿā copiés ou partagés.
  static const String shareAttributionSuffix = '\n\n— من تطبيق $appName —';
}
