import 'dart:async';

import 'package:flutter/foundation.dart';

import '../user_prefs.dart';
import 'ads_free_status.dart';
import 'reward_kind.dart';
import 'reward_service.dart';
import 'rewarded_ad_controller.dart';
import 'rewarded_wording.dart';

/// État affiché par la ligne « une heure sans publicité » des Paramètres.
enum AdFreeHourEntryState {
  /// Invitation (B6) — Rewarded proposable.
  idle,

  /// Rewarded en chargement / présentation.
  loading,

  /// Heure sans publicité en cours : temps restant affiché (B5).
  active,
}

/// Issue d'une activation de la ligne.
enum AdFreeHourResult {
  /// Heure déjà active : aucun Rewarded lancé (B3/B5).
  alreadyActive,

  /// Confirmation refusée, ou autre demande déjà en cours.
  cancelled,

  /// Récompense obtenue : l'heure sans publicité a commencé.
  earned,

  /// Rewarded fermé avant la récompense, indisponible ou en échec :
  /// retour à l'état normal, sans message technique.
  notEarned,
}

/// Logique de la ligne « une heure sans publicité » (B1), sans widget.
///
/// - Ne calcule JAMAIS `adsSuppressedUntil` : la fenêtre est fixée par
///   l'infrastructure LOT 5.G.A à l'instant exact de `onUserEarnedReward`.
///   Ce contrôleur ne fait que la LIRE.
/// - Aucun second minuteur métier, aucun compteur persistant : le temps
///   restant est recalculé chaque seconde par `AdsFreeStatus.remaining()`
///   à partir de la valeur persistée. Le rafraîchissement n'existe que
///   pendant l'affichage de l'écran et d'une fenêtre active.
/// - À l'expiration : retour automatique à l'état normal.
class AdFreeHourEntry extends ChangeNotifier {
  AdFreeHourEntry({
    RewardService? rewardService,
    Future<DateTime?> Function()? readSuppressedUntil,
    DateTime Function()? clock,
    Duration tickInterval = const Duration(seconds: 1),
  })  : _rewardService = rewardService ?? RewardedAdController.instance,
        _readSuppressedUntil = readSuppressedUntil ??
            UserPrefs.instance.getAdsSuppressedUntil,
        _clock = clock ?? DateTime.now,
        _tickInterval = tickInterval;

  final RewardService _rewardService;
  final Future<DateTime?> Function() _readSuppressedUntil;
  final DateTime Function() _clock;
  final Duration _tickInterval;

  DateTime? _suppressedUntil;
  bool _loading = false;
  bool _disposed = false;
  Timer? _ticker;

  AdsFreeStatus get _status => AdsFreeStatus(_suppressedUntil);

  AdFreeHourEntryState get state {
    if (_loading) return AdFreeHourEntryState.loading;
    if (_status.isActive(now: _clock())) return AdFreeHourEntryState.active;
    return AdFreeHourEntryState.idle;
  }

  /// Temps restant réel, ou `null` hors fenêtre active.
  Duration? get remaining => _status.remaining(now: _clock());

  String get label {
    switch (state) {
      case AdFreeHourEntryState.loading:
        return RewardedWording.loading;
      case AdFreeHourEntryState.active:
        return RewardedWording.adFreeHourActive(
          formatRemaining(remaining ?? Duration.zero),
        );
      case AdFreeHourEntryState.idle:
        return RewardedWording.invitation;
    }
  }

  /// `mm:ss` — la fenêtre ne dépasse jamais une heure (B5 : « متبقٍ 42:17 »).
  static String formatRemaining(Duration remaining) {
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    // 1 h pile (juste après la récompense) s'affiche 60:00, pas 00:00.
    if (safe.inMinutes >= 60) return '60:00';
    return '$minutes:$seconds';
  }

  /// Relit l'état réel (`adsSuppressedUntil`). Ne lève jamais.
  ///
  /// La disponibilité du Rewarded n'est volontairement PAS consultée : la
  /// ligne est toujours visible (B1). Un Rewarded indisponible se traduit
  /// seulement, au tap, par un retour à l'invitation sans message.
  Future<void> refresh() async {
    try {
      _suppressedUntil = await _readSuppressedUntil();
    } catch (_) {
      _suppressedUntil = null;
    }
    if (_disposed) return;
    _syncTicker();
    notifyListeners();
  }

  /// Activation volontaire de la ligne.
  Future<AdFreeHourResult> activate({
    required Future<bool> Function() confirm,
  }) async {
    if (_loading) return AdFreeHourResult.cancelled;

    await refresh();
    // B3/B5 : heure déjà active → aucun Rewarded.
    if (state == AdFreeHourEntryState.active) {
      return AdFreeHourResult.alreadyActive;
    }

    if (!await confirm()) return AdFreeHourResult.cancelled;
    if (_disposed) return AdFreeHourResult.cancelled;

    _loading = true;
    notifyListeners();

    var earned = false;
    try {
      earned = await _rewardService.requestReward(RewardKind.adFreeHour);
    } catch (_) {
      earned = false;
    } finally {
      _loading = false;
    }

    // Rafraîchissement immédiat : l'état affiché provient toujours de la
    // valeur réellement persistée par l'infrastructure.
    await refresh();
    return earned ? AdFreeHourResult.earned : AdFreeHourResult.notEarned;
  }

  /// Recalcule l'affichage sans relire le stockage — exposé pour les tests.
  @visibleForTesting
  void tick() {
    if (_disposed) return;
    _syncTicker();
    notifyListeners();
  }

  void _syncTicker() {
    if (state == AdFreeHourEntryState.active) {
      _ticker ??= Timer.periodic(_tickInterval, (_) => tick());
    } else {
      _ticker?.cancel();
      _ticker = null;
      // Expiration constatée : retour à l'invitation.
      if (_suppressedUntil != null && !_status.isActive(now: _clock())) {
        _suppressedUntil = null;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}
