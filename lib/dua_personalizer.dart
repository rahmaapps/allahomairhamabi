// lib/dua_personalizer.dart
//
// Logique PURE de personnalisation d'un texte de dou'a par le prénom d'une
// personne (aucune dépendance à l'arbre de widgets) — testable en isolation.
// Extraite de home_screen.dart lors de la correction V1.2 des bugs
// BUG-004/BUG-005 (voir docs/V1.2_PROGRESS.md).

class DuaPersonalizer {
  DuaPersonalizer._();

  /// Personnalise [baseText] pour [personKey] avec le prénom trouvé dans
  /// [personsData] (map personKey -> prénom saisi par l'utilisateur).
  ///
  /// [personKey] DOIT être la personne réelle d'origine du dou'a (jamais
  /// choisie au hasard parmi les personnes sélectionnées — c'est la cause
  /// racine de BUG-005). Si aucun prénom n'est enregistré pour cette
  /// personne, [baseText] est retourné inchangé.
  ///
  /// Un seul passage de remplacement est effectué sur le texte ORIGINAL
  /// (jamais sur un résultat déjà personnalisé) : cela empêche
  /// structurellement toute duplication du nom, même quand le texte de
  /// remplacement (ex. "أبي Youssef") contient lui-même le mot recherché
  /// (ex. "أبي").
  static String personalize(
    String baseText,
    String personKey,
    Map<String, String> personsData,
  ) {
    final name = personsData[personKey];
    if (name == null || name.isEmpty) return baseText;

    final variants = relationWordVariants(personKey);
    if (variants.isEmpty) return baseText;

    final word = variants.first;
    final personText = '$word $name';

    final pattern = RegExp(variants.map(RegExp.escape).join('|'));
    return baseText.replaceAll(pattern, personText);
  }

  /// Variantes du mot relationnel arabe réellement utilisées dans
  /// duas.json pour chaque personKey (ex. le père y est parfois "أبي",
  /// parfois "والدي"). La première variante sert de mot canonique affiché
  /// devant le prénom (ex. "أبي Youssef").
  static List<String> relationWordVariants(String personKey) {
    switch (personKey) {
      case 'father':
        return const ['أبي', 'والدي'];
      case 'mother':
        return const ['أمي', 'والدتي'];
      case 'parents':
        return const ['والديّ', 'والدي'];
      case 'grandfather':
        return const ['جدي'];
      case 'grandmother':
        return const ['جدتي'];
      case 'brother':
        return const ['أخي'];
      case 'sister':
        return const ['أختي'];
      case 'son':
        return const ['ابني'];
      case 'daughter':
        return const ['ابنتي'];
      case 'husband':
        return const ['زوجي'];
      case 'wife':
        return const ['زوجتي'];
      default:
        return const [];
    }
  }
}
