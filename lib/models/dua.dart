class Dua {
  final int id;             // id global unique (V1.2 — voir docs/duas_id_migration_manifest.json)
  final String text;        // text_ar
  final String category;    // normal | friday | ramadan | grave_visit
  final String length;      // "قصيرة" ou "طويلة"
  final String personKey;   // clé de la personne d'origine (father, mother, ..., general)
                             // — dérivée de la position dans l'arbre du JSON, jamais choisie
                             // au hasard : c'est la clé de correction de BUG-004/005/006.

  Dua({
    required this.id,
    required this.text,
    required this.category,
    required this.length,
    required this.personKey,
  });

  factory Dua.fromJson(Map<String, dynamic> json, {required String personKey}) {
    return Dua(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? 'normal',
      length: json['length']?.toString() ?? '',
      personKey: personKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'length': length,
    };
  }

}