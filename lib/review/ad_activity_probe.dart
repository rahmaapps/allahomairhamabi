/// Sonde **en lecture seule** indiquant qu'une publicité plein écran est en
/// cours de présentation, ou vient de l'être.
///
/// Existe uniquement pour satisfaire D6 (« jamais pendant ou immédiatement
/// autour d'une publicité ») sans coupler le module d'évaluation à la
/// monétisation : `ReviewPromptController` reçoit cette fonction par
/// injection, `ReviewPolicy` n'en voit qu'un booléen, et aucun fichier de
/// `lib/monetization/` n'est modifié par le LOT 5.D.
///
/// Ne concerne que les formats **plein écran** (interstitiel, et tout futur
/// Rewarded). Les bannières en sont volontairement exclues : permanentes
/// sur HOME, Recherche et Favoris, les inclure rendrait toute sollicitation
/// structurellement impossible.
///
/// Ne doit jamais lever : une exception serait de toute façon interceptée
/// par le controller, qui refuserait alors la sollicitation.
typedef AdActivityProbe = Future<bool> Function();
