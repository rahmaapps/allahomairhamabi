// Tests ciblés de DuaPersonalizer — corrige BUG-005 (V1.2).
// Couvre explicitement les 11 relations + le cas de duplication historique.
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/dua_personalizer.dart';

void main() {
  group('DuaPersonalizer — 11 relations', () {
    const cases = <String, Map<String, String>>{
      // personKey : {texte source (mot canonique), nom, attendu}
      'father': {
        'text': 'اللهم اجعل أبي من أهل النعيم.',
        'name': 'Youssef',
        'expected': 'اللهم اجعل أبي Youssef من أهل النعيم.',
      },
      'mother': {
        'text': 'اللهم اجعل أمي من أهل النعيم.',
        'name': 'Amina',
        'expected': 'اللهم اجعل أمي Amina من أهل النعيم.',
      },
      'parents': {
        'text': 'اللهم اجعل والديّ من أهل النعيم.',
        'name': 'Fatima et Ahmed',
        'expected': 'اللهم اجعل والديّ Fatima et Ahmed من أهل النعيم.',
      },
      'grandfather': {
        'text': 'اللهم اجعل جدي من أهل النعيم.',
        'name': 'Omar',
        'expected': 'اللهم اجعل جدي Omar من أهل النعيم.',
      },
      'grandmother': {
        'text': 'اللهم اجعل جدتي من أهل النعيم.',
        'name': 'Khadija',
        'expected': 'اللهم اجعل جدتي Khadija من أهل النعيم.',
      },
      'brother': {
        'text': 'اللهم اجعل أخي من أهل النعيم.',
        'name': 'Ahmed',
        'expected': 'اللهم اجعل أخي Ahmed من أهل النعيم.',
      },
      'sister': {
        'text': 'اللهم اجعل أختي من أهل النعيم.',
        'name': 'Sara',
        'expected': 'اللهم اجعل أختي Sara من أهل النعيم.',
      },
      'son': {
        'text': 'اللهم اجعل ابني من أهل النعيم.',
        'name': 'Yassine',
        'expected': 'اللهم اجعل ابني Yassine من أهل النعيم.',
      },
      'daughter': {
        'text': 'اللهم اجعل ابنتي من أهل النعيم.',
        'name': 'Lina',
        'expected': 'اللهم اجعل ابنتي Lina من أهل النعيم.',
      },
      'husband': {
        'text': 'اللهم اجعل زوجي من أهل النعيم.',
        'name': 'Karim',
        'expected': 'اللهم اجعل زوجي Karim من أهل النعيم.',
      },
      'wife': {
        'text': 'اللهم اجعل زوجتي من أهل النعيم.',
        'name': 'Nadia',
        'expected': 'اللهم اجعل زوجتي Nadia من أهل النعيم.',
      },
    };

    cases.forEach((personKey, data) {
      test('$personKey : nom injecté correctement, une seule fois', () {
        final result = DuaPersonalizer.personalize(
          data['text']!,
          personKey,
          {personKey: data['name']!},
        );
        expect(result, data['expected']);
        // Le nom ne doit jamais apparaître deux fois.
        final occurrences = data['name']!.allMatches(result).length;
        expect(occurrences, 1, reason: 'le prénom ne doit apparaître qu\'une fois');
      });
    });
  });

  group('DuaPersonalizer — régression BUG-005 (duplication via "والدي")', () {
    test('père : texte source utilisant "والدي" (pas "أبي") — pas de duplication', () {
      final result = DuaPersonalizer.personalize(
        'اللهم اجعل والدي من أهل النعيم.',
        'father',
        {'father': 'Youssef'},
      );
      expect(result, 'اللهم اجعل أبي Youssef من أهل النعيم.');
      expect('Youssef'.allMatches(result).length, 1);
    });

    test('mère : texte source utilisant "والدتي" (pas "أمي") — nom bien injecté', () {
      final result = DuaPersonalizer.personalize(
        'اللهم اجعل والدتي من المرحومات المغفور لهم.',
        'mother',
        {'mother': 'Amina'},
      );
      expect(result, contains('Amina'));
      expect(result, isNot(contains('والدتي')));
      expect('Amina'.allMatches(result).length, 1);
    });
  });

  group('DuaPersonalizer — cas limites', () {
    test('personne sans nom enregistré : texte inchangé', () {
      final result = DuaPersonalizer.personalize(
        'اللهم اجعل أبي من أهل النعيم.',
        'father',
        {}, // aucun nom pour father
      );
      expect(result, 'اللهم اجعل أبي من أهل النعيم.');
    });

    test('personKey "general" : jamais personnalisé', () {
      final result = DuaPersonalizer.personalize(
        'اللهم ارحم أمواتنا.',
        'general',
        {'general': 'Quelqu\'un'},
      );
      expect(result, 'اللهم ارحم أمواتنا.');
    });

    test('personKey inconnu : texte inchangé, pas d\'exception', () {
      final result = DuaPersonalizer.personalize(
        'اللهم ارحم أمواتنا.',
        'unknown_key',
        {'unknown_key': 'X'},
      );
      expect(result, 'اللهم ارحم أمواتنا.');
    });

    test('aucun mot relationnel présent dans le texte : rien injecté', () {
      final result = DuaPersonalizer.personalize(
        'نص عام لا يحتوي على كلمة علاقة.',
        'father',
        {'father': 'Youssef'},
      );
      expect(result, 'نص عام لا يحتوي على كلمة علاقة.');
      expect(result, isNot(contains('Youssef')));
    });
  });
}
