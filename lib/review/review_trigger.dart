/// Transition de navigation susceptible de déclencher une demande
/// d'évaluation de l'application (LOT 5.D). Modélise une **arête** de
/// navigation (retour vers HOME), jamais un écran ni un emplacement
/// d'affichage — axe distinct de `AdSurface`/`InterstitialTrigger`, qui
/// appartiennent à la monétisation et n'ont aucun lien avec ce module.
///
/// Périmètre verrouillé produit (D1) : **uniquement** le retour
/// Favoris → HOME. L'enum ne comporte volontairement qu'une seule valeur —
/// aucune autre transition de l'app n'est représentable, et en particulier
/// pas le retour Recherche → HOME (exclu explicitement), ni la sortie de
/// DuaRead ou de Grave Visit, ni « دعاء آخر », ni le lancement/onboarding.
/// Ajouter une valeur ici ne suffirait d'ailleurs pas : `ReviewPolicy`
/// applique une liste d'autorisation explicite.
enum ReviewTrigger {
  /// Retour arrière depuis Favoris vers HOME.
  leavingFavorites,
}
