// Carte N1 (`AppCard`, niveau hero) — rosace en filigrane.
//
// Décision post-QA : les cartes du douʿā du HOME et de `DuaReadScreen` ne
// peignent plus la rosace (`showPattern: false`) ; la valeur par défaut du
// composant partagé reste inchangée (rosace peinte).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_1/widgets/app_card.dart';
import 'package:test_1/widgets/islamic_pattern_painter.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 300, height: 400, child: child),
      ),
    );

Finder _rosace() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is IslamicGoldPatternPainter,
    );

void main() {
  testWidgets('N1 par défaut : rosace peinte', (tester) async {
    await tester.pumpWidget(_wrap(const AppCard(child: Text('دعاء'))));
    expect(_rosace(), findsOneWidget);
  });

  testWidgets('N1 avec showPattern: false : aucune rosace, contenu conservé',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const AppCard(showPattern: false, child: Text('دعاء'))),
    );
    expect(_rosace(), findsNothing);
    expect(find.text('دعاء'), findsOneWidget);
  });
}
