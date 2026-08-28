// Tests V1.2 Phase 11 — PremiumDuaPaginator.fitSinglePage() : garantie
// mathématique d'une seule page, sans jamais perdre de contenu, quelle que
// soit la longueur du dou'a ni le template (zones réelles des 3 templates).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/premium_templates.dart';
import 'package:test_1/widgets/premium_dua_paginator.dart';

// Mesure indépendante (même méthode que le paginateur) pour vérifier après
// coup qu'une taille de police calculée respecte réellement la zone —
// détecte tout "BOTTOM OVERFLOWED" silencieux.
double measureHeight(String text, double fontSize, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Lateef', fontSize: fontSize, height: 1.6),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.rtl,
    maxLines: null,
  )..layout(maxWidth: maxWidth);
  return painter.height;
}

void main() {
  const short = 'اللهم ارزق أبي نوراً في قبره.'; // ~29 caractères — cas réel le plus court
  const medium =
      'اللهم اغفر لأبي وارحمه، وأكرم نزله، ووسع مدخله، واغسله بالماء والثلج '
      'والبرد، ونقه من الخطايا كما ينقى الثوب الأبيض من الدنس.'; // ~150 car.
  const long =
      'اللهم ارحم أبي رحمة واسعة، واغفر له، وتقبله قبولاً حسناً، اللهم أنزله '
      'منازل الصديقين والصالحين، وأكرم مثواه، ووسع قبره، ونوره له كما نورت '
      'الأرض بنورك، واجعل قبره روضة من رياض الجنة ولا تجعله حفرة من حفر '
      'النار، اللهم ارحمه رحمة تغنيه بها عن رحمة من سواك.'; // ~330 car.
  const veryLong =
      'السَّلَامُ عَلَيْكَ يَا وَالِدِي، السَّلَامُ عَلَيْكَ فِي دَارِ '
      'قَوْمٍ مُؤْمِنِينَ، وَإِنَّا إِنْ شَاءَ اللَّهُ بِكَ لَلَاحِقُونَ. '
      'اللَّهُمَّ ارْحَمْ أَبِي رَحْمَةً وَاسِعَةً، وَاغْفِرْ لَهُ، '
      'وَتَقَبَّلْهُ قَبُولًا حَسَنًا، اللَّهُمَّ أَنْزِلْهُ مَنَازِلَ '
      'الصِّدِّيقِينَ وَالصَّالِحِينَ، وَأَكْرِمْ مَثْوَاهُ، وَوَسِّعْ '
      'قَبْرَهُ، وَنَوِّرْهُ لَهُ كَمَا نَوَّرْتَ الْأَرْضَ بِنُورِكَ. '
      'اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ، وَعَافِهِ وَاعْفُ عَنْهُ، '
      'وَاغْسِلْهُ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ، وَنَقِّهِ مِنَ '
      'الذُّنُوبِ وَالْخَطَايَا كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ '
      'الدَّنَسِ. اللَّهُمَّ وَسِّعْ عَلَى أَبِي فِي قَبْرِهِ، وَآنِسْ '
      'وَحْشَتَهُ، وَارْحَمْ غُرْبَتَهُ، وَثَبِّتْهُ عِنْدَ السُّؤَال، '
      'وَاجْعَلْ عَمَلَهُ الصَّالِحَ نُورًا لَهُ فِي قَبْرِهِ وَيَوْمَ '
      'يَلْقَاكَ. اللَّهُمَّ إِنْ كَانَ مُحْسِنًا فَزِدْ فِي إِحْسَانِهِ، '
      'وَإِنْ كَانَ مُسِيئًا فَتَجَاوَزْ عَنْ سَيِّئَاتِهِ، وَاجْعَلْهُ '
      'مِمَّنْ تَلَقَّاهُمُ الْمَلَائِكَةُ وَقَالُوا لَهُمْ سَلَامٌ '
      'عَلَيْكُمُ ادْخُلُوا الْجَنَّةَ بِمَا كُنتُمْ تَعْمَلُونَ. '
      'اللَّهُمَّ لَا تَحْرِمْنِي أَجْرَ الدُّعَاءِ لَهُ، وَلَا تَحْرِمْهُ '
      'أَجْرَ وِلَايَتِي بِهِ، وَاجْعَلْ دُعَائِي لَهُ نُورًا يَصِلُ إِلَى '
      'قَبْرِهِ فِي كُلِّ وَقْتٍ وَكُلِّ حِينٍ. اللَّهُمَّ اجْمَعْنِي '
      'بِوَالِدِي فِي جَنَّاتِ النَّعِيم، مَعَ النَّبِيِّينَ '
      'وَالصِّدِّيقِينَ وَالشُّهَدَاءِ وَالصَّالِحِينَ، وَحَسُنَ أُولَئِكَ '
      'رَفِيقًا، بِرَحْمَتِكَ يَا أَرْحَمَ الرَّاحِمِينَ.'; // 1848 caractères, avec tashkīl — cas réel le plus long du catalogue (id=260)

  group('fitSinglePage — toujours une seule page, jamais de perte de contenu', () {
    for (final template in PremiumTemplate.values) {
      final zone = template.duaTextZone;
      final size = template.fixedTemplateSize;
      final maxWidth = zone.width * size.width;
      final maxHeight = zone.height * size.height;

      group('template ${template.name} (zone ${maxWidth.toStringAsFixed(0)}x${maxHeight.toStringAsFixed(0)})', () {
        test('dou\'a courte : texte inchangé, taille confortable', () {
          final page = PremiumDuaPaginator.fitSinglePage(
              duaText: short, maxWidth: maxWidth, maxHeight: maxHeight);
          expect(page.text, short); // aucune altération
          expect(page.fontSize, greaterThanOrEqualTo(PremiumDuaPaginator.minFontSize));
        });

        test('dou\'a moyenne : texte inchangé, tient dans la zone', () {
          final page = PremiumDuaPaginator.fitSinglePage(
              duaText: medium, maxWidth: maxWidth, maxHeight: maxHeight);
          expect(page.text, medium);
          expect(measureHeight(page.text, page.fontSize, maxWidth),
              lessThanOrEqualTo(maxHeight));
        });

        test('dou\'a longue : texte inchangé, tient dans la zone (aucun overflow)', () {
          final page = PremiumDuaPaginator.fitSinglePage(
              duaText: long, maxWidth: maxWidth, maxHeight: maxHeight);
          expect(page.text, long);
          expect(measureHeight(page.text, page.fontSize, maxWidth),
              lessThanOrEqualTo(maxHeight));
        });

        test('dou\'a très longue (1848 car., tashkīl) : texte ET diacritiques intégralement préservés, tient dans la zone', () {
          final page = PremiumDuaPaginator.fitSinglePage(
              duaText: veryLong, maxWidth: maxWidth, maxHeight: maxHeight);
          // Jamais de perte de contenu : la page contient l'INTÉGRALITÉ du
          // texte source, caractère pour caractère (tashkīl inclus).
          expect(page.text, veryLong);
          expect(page.text.length, veryLong.length);
          expect(measureHeight(page.text, page.fontSize, maxWidth),
              lessThanOrEqualTo(maxHeight),
              reason: 'BOTTOM OVERFLOWED : le texte ne tient pas à la taille calculée');
          expect(page.fontSize, greaterThanOrEqualTo(1),
              reason: 'taille de police invalide');
        });
      });
    }
  });

  test('champ vide : ne plante pas, taille par défaut', () {
    final page = PremiumDuaPaginator.fitSinglePage(
        duaText: '', maxWidth: 700, maxHeight: 500);
    expect(page.text, '');
  });
}
