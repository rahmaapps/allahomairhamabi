class Dua {
  final int id;
  final String text;       // text_ar
  final String category;   // normal | friday | ramadan
  final String length;     // "قصيرة" ou "طويلة"

  Dua({
    required this.id,
    required this.text,
    required this.category,
    required this.length,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      text: json['text_ar']?.toString() ?? '',
      category: json['category']?.toString() ?? 'normal',
      length: json['length']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text_ar': text,
      'category': category,
      'length': length,
    };
  }
}