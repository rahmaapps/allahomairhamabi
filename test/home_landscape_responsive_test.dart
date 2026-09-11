// Tests LOT HOME LANDSCAPE — rail latéral paysage (décision UX validée).
//
// En paysage, les chips catégories et la ligne « pour qui » quittent la
// colonne verticale pour un rail latéral gauche de 108dp, à côté de
// `Expanded(AppCard)` au lieu d'empiler au-dessus d'elle — cause unique de
// l'effondrement du viewport du douʿā, confirmée par audit dédié (captures
// à l'appui). Le portrait reste une simple `Column`, strictement identique
// à avant ce lot.
//
// Portée couverte :
// - portrait : structure `Column` inchangée, aucun rail, valeurs
//   historiques (padding/gaps `lg`/`md`, footer réservé 56, interligne
//   normal de la ligne personne, pas de `textHeightBehavior`) ;
// - paysage : structure `Row` avec rail 108dp contenant, dans l'ordre,
//   chip « عام », chip « دعاء الجمعة », ligne « pour qui » compactée
//   verticalement — et `Expanded(AppCard)` dans le reste de la largeur ;
// - comportements préservés : sélection de catégorie (tap chip) et accès à
//   la sélection des personnes (tap تغيير/اختيار), y compris dans le rail ;
// - `textHeightBehavior` du douʿā (LOT précédent) toujours actif en
//   paysage, inchangé par cette restructuration.
//
// Vérification par lecture directe des widgets construits (jamais par
// mesure de taille rendue), en localisant `AppCard`/les textes par contenu
// ou par type plutôt que par index de `Column`, pour rester robuste au
// changement de structure (Column en portrait, Row en paysage).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/screens/person_selection_screen.dart';
import 'package:test_1/theme/app_spacing.dart';
import 'package:test_1/widgets/app_card.dart';
import 'package:test_1/widgets/app_chip.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, Size physicalSize) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
  }

  // Seed `persons_data` avec [count] personnes (clés arbitraires, seul le
  // nombre compte pour le cas pluriel « تدعو لـ N أشخاص »).
  Future<void> pumpHomeWithPersons(
    WidgetTester tester,
    Size physicalSize,
    int count,
  ) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const keys = ['father', 'mother', 'brother', 'sister', 'son'];
    SharedPreferences.setMockInitialValues({
      'persons_data': jsonEncode({for (final k in keys.take(count)) k: ''}),
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
  }

  // `find.byType(SafeArea)` matcherait aussi le `SafeArea(bottom: false,
  // ...)` que le Material `AppBar` s'applique lui-même en interne — sans
  // rapport avec le nôtre. Le nôtre (`SafeArea(child: ...)` explicite dans
  // `home_screen.dart`) est le seul dont les 4 côtés valent `true` par défaut.
  Widget bodyRoot(WidgetTester tester) {
    final safeArea = tester.widget<SafeArea>(
      find.byWidgetPredicate((w) => w is SafeArea && w.bottom),
    );
    final padding = safeArea.child as Padding;
    return padding.child!;
  }

  // Localise directement `AppCard` (unique dans l'arbre HomeScreen) plutôt
  // que par index de Column/Row — robuste que la carte vive dans une simple
  // Column (portrait) ou dans la Column principale du Row paysage.
  AppCard findAppCard(WidgetTester tester) =>
      tester.widget<AppCard>(find.byType(AppCard));

  double footerReservedHeight(WidgetTester tester) {
    final stack = findAppCard(tester).child as Stack;
    final positionedFill = stack.children[0] as Positioned;
    return positionedFill.bottom!;
  }

  Text duaText(WidgetTester tester) {
    final stack = findAppCard(tester).child as Stack;
    final positionedFill = stack.children[0] as Positioned;
    final center = positionedFill.child as Center;
    final scrollView = center.child as SingleChildScrollView;
    return scrollView.child as Text;
  }

  // Localise les deux `Text` de la ligne « pour qui » par leur contenu
  // (état par défaut, aucune personne sélectionnée) plutôt que par
  // structure — valable identiquement en Row (portrait) ou Column
  // (compact, rail paysage).
  ({TextStyle summary, TextStyle action}) personsLineStyles(WidgetTester tester) {
    final summary = tester.widget<Text>(find.text('ادعُ لمن تحب'));
    final action = tester.widget<Text>(find.text('اختيار'));
    return (summary: summary.style!, action: action.style!);
  }

  testWidgets(
      'portrait : Column historique, aucun rail, valeurs inchangées',
      (tester) async {
    // 400x800 : portrait sans ambiguïté (hauteur > largeur).
    await pumpHome(tester, const Size(400, 800));

    // Structure racine : Column (pas de rail en portrait).
    final root = bodyRoot(tester);
    expect(root, isA<Column>());
    final column = root as Column;

    // Aucun rail de 108dp nulle part dans l'arbre en portrait.
    expect(
      find.byWidgetPredicate((w) => w is SizedBox && w.width == 108),
      findsNothing,
    );

    // Chips : rangée horizontale 50/50, gaps historiques (md=12).
    final chipsRow = column.children[0] as Row;
    expect((chipsRow.children[0] as Expanded).child, isA<AppChip>());
    expect((chipsRow.children[2] as Expanded).child, isA<AppChip>());
    expect((column.children[1] as SizedBox).height, AppSpacing.md);
    expect((column.children[3] as SizedBox).height, AppSpacing.md);
    expect((column.children[5] as SizedBox).height, AppSpacing.md);

    expect(footerReservedHeight(tester), 56.0);

    // Ligne « pour qui » : Row horizontale (pas compactée), interligne et
    // taille de police historiques, jamais tronquée.
    expect(column.children[2], isA<Row>());
    final styles = personsLineStyles(tester);
    expect(styles.summary.fontSize, 15.0);
    expect(styles.summary.height, 1.75);
    expect(styles.action.fontSize, 15.0);
    expect(styles.action.height, 1.50);

    // Douʿā : aucun textHeightBehavior en portrait, fontSize/height intacts.
    final dua = duaText(tester);
    expect(dua.textHeightBehavior, isNull);
    expect(dua.style!.fontSize, 29.0);
    expect(dua.style!.height, 2.05);
  });

  testWidgets(
      'paysage : rail 108dp (chips + ligne personne) et HeroCard dans le reste de la largeur',
      (tester) async {
    // 800x400 : paysage sans ambiguïté (largeur > hauteur).
    await pumpHome(tester, const Size(800, 400));

    // Structure racine : Row (rail + contenu principal), pas de Column.
    final root = bodyRoot(tester);
    expect(root, isA<Row>());
    final row = root as Row;
    expect(row.children.length, 3);

    // ---- Rail : SizedBox(width: 108) en 1er enfant du Row ----
    final railBox = row.children[0] as SizedBox;
    expect(railBox.width, 108.0);
    final railColumn = railBox.child as Column;

    // Les 3 éléments, dans l'ordre : chip « عام », chip « دعاء الجمعة »,
    // ligne « pour qui » (compactée en Column).
    final chip1 = railColumn.children[0] as AppChip;
    final chip2 = railColumn.children[2] as AppChip;
    expect(chip1.label, 'عام');
    expect(chip2.label, 'دعاء الجمعة');
    expect(railColumn.children[4], isA<Column>()); // ligne personne compactée

    // ---- Contenu principal : Expanded en dernier enfant du Row ----
    final mainExpanded = row.children[2] as Expanded;
    final mainColumn = mainExpanded.child as Column;
    expect(mainColumn.children[0], isA<Expanded>()); // HeroCard
    // HeroCard bien à l'intérieur de cette zone Expanded (espace restant).
    expect(
      find.descendant(of: find.byWidget(mainExpanded), matching: find.byType(AppCard)),
      findsOneWidget,
    );

    expect(footerReservedHeight(tester), 56.0);

    // Ligne « pour qui » : interligne et taille de police IDENTIQUES au
    // portrait (seule l'orientation Row->Column change, jamais le style).
    final styles = personsLineStyles(tester);
    expect(styles.summary.fontSize, 15.0);
    expect(styles.summary.height, 1.75);
    expect(styles.action.fontSize, 15.0);
    expect(styles.action.height, 1.50);

    // Douʿā : textHeightBehavior toujours actif en paysage (LOT précédent,
    // non affecté par cette restructuration), fontSize/height intacts.
    final dua = duaText(tester);
    expect(dua.textHeightBehavior, const TextHeightBehavior(applyHeightToFirstAscent: false));
    expect(dua.style!.fontSize, 29.0);
    expect(dua.style!.height, 2.05);
  });

  testWidgets(
      'paysage : le changement de catégorie via le rail fonctionne toujours',
      (tester) async {
    await pumpHome(tester, const Size(800, 400));

    expect(tester.widget<AppChip>(find.widgetWithText(AppChip, 'عام')).selected, isTrue);
    expect(
      tester.widget<AppChip>(find.widgetWithText(AppChip, 'دعاء الجمعة')).selected,
      isFalse,
    );

    await tester.tap(find.widgetWithText(AppChip, 'دعاء الجمعة'));
    await tester.pumpAndSettle();

    expect(tester.widget<AppChip>(find.widgetWithText(AppChip, 'عام')).selected, isFalse);
    expect(
      tester.widget<AppChip>(find.widgetWithText(AppChip, 'دعاء الجمعة')).selected,
      isTrue,
    );
  });

  testWidgets(
      'paysage : le تap sur اختيار/تغيير du rail ouvre toujours la sélection des personnes',
      (tester) async {
    await pumpHome(tester, const Size(800, 400));

    await tester.tap(find.text('اختيار'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonSelectionScreen), findsOneWidget);
  });

  for (final count in [2, 5]) {
    testWidgets(
        'paysage : rail — le pluriel « $count أشخاص » sépare « تدعو لـ » de « $count أشخاص » (jamais la chaîne combinée)',
        (tester) async {
      await pumpHomeWithPersons(tester, const Size(800, 400), count);

      // Composition logique forcée : deux Text distincts, jamais la
      // rupture accidentelle du wrapping naturel (ex. « تدعو لـ $count »
      // seul, coupé de « أشخاص », observée sur appareil réel).
      expect(find.text('تدعو لـ'), findsOneWidget);
      expect(find.text('$count أشخاص'), findsOneWidget);
      expect(find.text('تدعو لـ $count أشخاص'), findsNothing);

      // « تغيير » (personnes déjà sélectionnées) toujours présent et
      // fonctionnel — comportement inchangé par ce correctif.
      expect(find.text('تغيير'), findsOneWidget);
      await tester.tap(find.text('تغيير'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonSelectionScreen), findsOneWidget);
    });
  }

  for (final count in [2, 5]) {
    testWidgets(
        'portrait : le pluriel « $count أشخاص » garde la chaîne combinée historique (aucune régression)',
        (tester) async {
      await pumpHomeWithPersons(tester, const Size(400, 800), count);

      // Portrait n'utilise jamais le mode compact : une seule chaîne, comme
      // avant ce correctif — jamais scindée en deux `Text`.
      expect(find.text('تدعو لـ $count أشخاص'), findsOneWidget);
      expect(find.text('تدعو لـ'), findsNothing);
      expect(find.text('$count أشخاص'), findsNothing);
    });
  }
}
