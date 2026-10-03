import 'package:flutter/foundation.dart';

import '../user_prefs.dart';
import 'ads_free_status.dart';
import 'reward_effects.dart';
import 'reward_kind.dart';
import 'reward_service.dart';
import 'rewarded_ad_controller.dart';

/// Étape en cours, pour l'affichage du bouton de la feuille de partage.
enum ShareAsImagePhase {
  /// Rewarded en chargement / présentation.
  loadingAd,

  /// Rendu PNG puis remise au système de partage.
  preparingImage,
}

/// Issue du flux, du point de vue de la feuille de partage.
enum ShareAsImageResult {
  /// Image remise au système de partage.
  shared,

  /// L'utilisateur a renoncé (confirmation refusée, ou annonce fermée avant
  /// la récompense). Aucun partage, aucun message, feuille toujours
  /// utilisable.
  cancelled,

  /// Le rendu PNG a échoué : aucune autorisation consommée.
  renderFailed,

  /// L'invocation du système de partage a échoué : l'autorisation
  /// éventuellement consommée est restituée.
  shareFailed,
}

/// Porte Rewarded du Partage comme image (LOT 5.G.B). Pure orchestration,
/// sans widget : toutes les dépendances d'interface (confirmation, rendu,
/// partage) sont injectées par l'écran.
///
/// Décisions verrouillées :
/// - **B3** — heure sans publicité active : partage gratuit, aucun
///   Rewarded, aucune autorisation consommée ;
/// - **B2** — Rewarded indisponible ou en échec (hors ligne, consentement,
///   unité, chargement, délai…) : partage gratuit immédiat, sans message ;
/// - **B4** — 1 Rewarded = 1 partage. L'autorisation est accordée par
///   l'infrastructure au callback `onUserEarnedReward`, et consommée ICI,
///   uniquement au moment où l'image est remise au système de partage —
///   jamais au clic, au chargement, au début de l'annonce ni à la
///   récompense. Un rendu PNG échoué ne la consomme pas.
///
/// `share_plus` ne permet pas de distinguer de façon fiable, sur Android,
/// une annulation de l'utilisateur d'une remise effective : l'autorisation
/// est donc consommée à l'invocation du système de partage (B4).
///
/// Le partage TEXTE n'est jamais concerné.
class ShareAsImageFlow {
  ShareAsImageFlow({
    RewardService? rewardService,
    Future<bool> Function()? isAdFreeActive,
  })  : _rewardService = rewardService ?? RewardedAdController.instance,
        _isAdFreeActive = isAdFreeActive ?? _defaultIsAdFreeActive;

  static Future<bool> _defaultIsAdFreeActive() async =>
      AdsFreeStatus(await UserPrefs.instance.getAdsSuppressedUntil())
          .isActive();

  final RewardService _rewardService;
  final Future<bool> Function() _isAdFreeActive;

  bool _running = false;

  Future<ShareAsImageResult> run({
    required Future<bool> Function() confirm,
    required Future<Uint8List?> Function() render,
    required Future<void> Function(Uint8List png) share,
    VoidCallback? onRewardEarned,
    ValueChanged<ShareAsImagePhase>? onPhase,
  }) async {
    if (_running) return ShareAsImageResult.cancelled;
    _running = true;

    try {
      final useGrant = await _authorize(
        confirm: confirm,
        onRewardEarned: onRewardEarned,
        onPhase: onPhase,
      );
      if (useGrant == null) return ShareAsImageResult.cancelled;

      onPhase?.call(ShareAsImagePhase.preparingImage);

      // B4 : un rendu échoué ne consomme RIEN.
      final png = await render();
      if (png == null) return ShareAsImageResult.renderFailed;

      // B4 : consommation à l'invocation du système de partage.
      final consumed =
          useGrant && await RewardEffects.consumeShareAsImageUnlock();

      try {
        await share(png);
        return ShareAsImageResult.shared;
      } catch (e) {
        // L'invocation elle-même a échoué : rien n'a été remis au système,
        // l'autorisation est restituée.
        if (consumed) await RewardEffects.grantShareAsImageUnlock();
        if (kDebugMode) debugPrint('[Monetization] Partage image échoué: $e');
        return ShareAsImageResult.shareFailed;
      }
    } finally {
      _running = false;
    }
  }

  /// `true` : partage à consommer sur une autorisation gagnée ;
  /// `false` : partage gratuit ; `null` : l'utilisateur a renoncé.
  Future<bool?> _authorize({
    required Future<bool> Function() confirm,
    VoidCallback? onRewardEarned,
    ValueChanged<ShareAsImagePhase>? onPhase,
  }) async {
    // B3 — aucune publicité pendant l'heure sans publicité.
    if (await _safe(_isAdFreeActive)) return false;

    // Autorisation déjà gagnée (ex. rendu échoué précédemment) : utilisée
    // sans nouveau Rewarded.
    if (await _safe(RewardEffects.hasShareAsImageUnlock)) return true;

    // B2 — rien à proposer : partage gratuit, sans détour ni message.
    if (!await _safe(_rewardService.canOfferReward)) return false;

    if (!await confirm()) return null;

    onPhase?.call(ShareAsImagePhase.loadingAd);
    final outcome = await _rewardService
        .requestRewardOutcome(RewardKind.shareAsImageUnlock);

    switch (outcome) {
      case RewardOutcome.earned:
        onRewardEarned?.call();
        return true;
      case RewardOutcome.dismissedWithoutReward:
        // Choix de l'utilisateur : il a fermé l'annonce avant la
        // récompense. Retour à la feuille, sans message.
        return null;
      case RewardOutcome.unavailable:
      case RewardOutcome.failed:
        // B2 — échec technique : jamais bloquant, jamais affiché.
        return false;
    }
  }

  static Future<bool> _safe(Future<bool> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return false;
    }
  }
}
