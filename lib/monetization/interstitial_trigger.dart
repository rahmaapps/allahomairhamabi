/// Transitions de navigation susceptibles de déclencher un interstitiel
/// (LOT 5.C). Modélise une **arête** de navigation (sortie d'un écran vers
/// HOME), pas un emplacement d'affichage — c'est un axe distinct de
/// `AdSurface`, qui décrit où vit une bannière.
///
/// Périmètre verrouillé produit : uniquement les retours Recherche → HOME et
/// Favoris → HOME. Aucune autre transition de l'app n'est représentée ici —
/// en particulier ni l'entrée dans Recherche/Favoris, ni la sortie de
/// DuaRead ou de Grave Visit, ni « دعاء آخر », ni le lancement/onboarding,
/// ni la sortie de l'app.
enum InterstitialTrigger {
  /// Retour arrière depuis Recherche vers HOME.
  leavingSearch,

  /// Retour arrière depuis Favoris vers HOME.
  leavingFavorites,
}
