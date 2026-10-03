import 'package:flutter/foundation.dart';

/// Un Rewarded chargé, prêt à être présenté. À usage unique : une fois
/// présenté (ou sa présentation échouée), il est libéré et ne peut plus
/// être réaffiché — même contrat que `LoadedInterstitialAd`.
abstract class LoadedRewardedAd {
  /// Présente l'annonce en plein écran.
  ///
  /// - [onShowed] : présentation **effective**. Jamais appelé si la
  ///   présentation échoue — c'est ce qui permet à l'appelant de distinguer
  ///   un échec de présentation d'une fermeture volontaire.
  /// - [onEarned] : callback Google `onUserEarnedReward`, et lui seul. C'est
  ///   l'unique signal autorisant une récompense.
  /// - [onFinished] : fin du cycle de vie (fermeture ou échec de
  ///   présentation). L'annonce est déjà libérée quand il est appelé.
  void show({
    required VoidCallback onShowed,
    required VoidCallback onEarned,
    required VoidCallback onFinished,
  });

  /// Libère une annonce chargée mais jamais présentée. Idempotent.
  void dispose();
}

/// Abstraction du chargement d'un Rewarded. La vraie implémentation
/// (`GoogleRewardedAdLoader`) passe par un canal de plateforme natif non
/// mockable en `flutter_test` : `RewardedAdController` ne dépend donc que
/// de cette interface, pour rester testable via un fake.
abstract class RewardedAdLoader {
  /// Retourne `null` en cas d'échec — ne lève jamais d'exception.
  Future<LoadedRewardedAd?> load();
}
