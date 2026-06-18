enum PersonType {
  father,
  mother,
  parents,
  grandfather,
  grandmother,
  brother,
  sister,
  son,
  daughter,
  husband,
  wife,
}

extension PersonTypeExtension on PersonType {
  String get label {
    switch (this) {
      case PersonType.father: return 'الأب';
      case PersonType.mother: return 'الأم';
      case PersonType.parents: return 'الوالدين';
      case PersonType.grandfather: return 'الجد';
      case PersonType.grandmother: return 'الجدة';
      case PersonType.brother: return 'الأخ';
      case PersonType.sister: return 'الأخت';
      case PersonType.son: return 'الابن';
      case PersonType.daughter: return 'الابنة';
      case PersonType.husband: return 'الزوج';
      case PersonType.wife: return 'الزوجة';
    }
  }

  String get key => name;
}
