import 'package:flutter/foundation.dart';

/// Une annonce interstitielle chargée, prête à être présentée. À usage
/// unique : une fois présentée (ou sa présentation échouée), elle est
/// libérée et ne peut plus être réaffichée.
abstract class LoadedInterstitialAd {
  /// Présente l'annonce en plein écran.
  ///
  /// - [onShowed] : la présentation a **effectivement** eu lieu. C'est le
  ///   seul signal qui autorise la consommation du cooldown (§ LOT 5.C :
  ///   « le timestamp est enregistré uniquement après présentation
  ///   effective »). Il n'est jamais appelé si la présentation échoue.
  /// - [onFinished] : fin du cycle de vie, que la présentation ait réussi
  ///   (annonce fermée par l'utilisateur) ou échoué. L'annonce est déjà
  ///   libérée quand ce callback est appelé — l'appelant n'a rien à
  ///   disposer lui-même.
  void show({required VoidCallback onShowed, required VoidCallback onFinished});

  /// Libère une annonce chargée mais jamais présentée. Idempotent.
  void dispose();
}

/// Abstraction du chargement d'un interstitiel. La vraie implémentation
/// (`GoogleInterstitialAdLoader`) appelle un canal de plateforme natif non
/// mockable en `flutter_test` (même limitation déjà documentée pour
/// `ConsentService`/`BannerAdLoader`) — `InterstitialAdController` dépend
/// donc de cette interface, jamais directement du plugin, pour rester
/// testable via un fake, sans aucun compte AdMob réel.
abstract class InterstitialAdLoader {
  /// Retourne `null` en cas d'échec — ne lève jamais d'exception : un
  /// échec de chargement doit laisser l'app pleinement fonctionnelle, sans
  /// publicité et sans consommer le cooldown (§ LOT 5.C).
  Future<LoadedInterstitialAd?> load();
}
