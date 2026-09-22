/// Libellés utilisateur du Rewarded (LOT 5.G.B) — SOURCE UNIQUE.
///
/// Les cinq premiers sont verrouillés produit (B6) et ne doivent jamais être
/// reformulés. Aucune formulation culpabilisante ni incitative agressive.
class RewardedWording {
  const RewardedWording._();

  // --- B6 — verrouillés -----------------------------------------------

  /// Invitation (ligne Paramètres, état normal).
  static const String invitation =
      'شاهد إعلانًا قصيرًا لإيقاف الإعلانات لمدة ساعة';

  /// Confirmation, affichée avant toute publicité.
  static const String confirmation = 'سيتم عرض إعلان قصير الآن';

  /// Chargement de l'annonce.
  static const String loading = 'جارٍ تحميل الإعلان…';

  /// Récompense « une heure sans publicité » obtenue.
  static const String adFreeHourEarned = 'تم تفعيل ساعة بدون إعلانات';

  /// Récompense « partage comme image » obtenue.
  static const String shareAsImageEarned = 'تم تفعيل المشاركة كصورة';

  /// Heure sans publicité en cours (B5) — `mm:ss` réellement restant.
  static String adFreeHourActive(String remaining) =>
      'لا إعلانات لمدة ساعة — متبقٍ $remaining';

  // --- Actions de la feuille de confirmation --------------------------
  // Non fixées par B6 : libellés neutres et minimaux, indispensables pour
  // que la confirmation reste un choix réel de l'utilisateur.

  static const String confirmAction = 'متابعة';
  static const String cancelAction = 'إلغاء';
}
