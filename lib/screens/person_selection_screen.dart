import 'dart:async';

import 'package:flutter/material.dart';

import '../models/person_type.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../user_prefs.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_snackbar.dart';

/// Person Selection — Mode Édition (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §4).
/// AppBar h56, titre `تدعو لـ`, retour `→`, aucun CTA en bas : chaque
/// coche/décoche/frappe s'enregistre immédiatement.
class PersonSelectionScreen extends StatefulWidget {
  const PersonSelectionScreen({super.key});

  @override
  State<PersonSelectionScreen> createState() => _PersonSelectionScreenState();
}

class _PersonSelectionScreenState extends State<PersonSelectionScreen> {
  Set<PersonType> selectedPersons = {};
  final Map<PersonType, TextEditingController> controllers = {};
  final Map<PersonType, FocusNode> focusNodes = {};
  final Map<PersonType, Timer?> _debounce = {};

  @override
  void initState() {
    super.initState();
    for (final person in PersonType.values) {
      controllers[person] = TextEditingController();
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) {
          _debounce[person]?.cancel();
          _persist();
        }
      });
      focusNodes[person] = node;
    }
    _loadData();
  }

  @override
  void dispose() {
    for (final timer in _debounce.values) {
      timer?.cancel();
    }
    // Écriture à la sortie (§4) — avant la disposition des contrôleurs.
    _persist();
    for (final controller in controllers.values) {
      controller.dispose();
    }
    for (final node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await UserPrefs.getPersonsData();

    setState(() {
      selectedPersons = data.keys
          .map((e) => PersonType.values.firstWhere((p) => p.name == e))
          .toSet();

      for (final person in PersonType.values) {
        controllers[person]!.text = data[person.name] ?? '';
      }
    });
  }

  /// Persiste toutes les personnes sélectionnées, prénom écrit **même vide**
  /// (§4 — correction du bug `data[person.name] = name` conditionnel).
  Future<void> _persist() async {
    final data = <String, String>{
      for (final p in selectedPersons) p.name: controllers[p]!.text,
    };
    await UserPrefs.savePersonsData(data);
  }

  void _onNameChanged(PersonType person, String value) {
    _debounce[person]?.cancel();
    _debounce[person] = Timer(const Duration(milliseconds: 400), _persist);
  }

  void _toggle(BuildContext snackBarContext, PersonType person) {
    if (selectedPersons.contains(person)) {
      _uncheck(snackBarContext, person);
    } else {
      setState(() => selectedPersons.add(person));
      _persist();
    }
  }

  /// Décochage silencieux, jamais bloquant (§4) : suppression immédiate +
  /// snackbar `تراجع` qui restaure la coche.
  ///
  /// `snackBarContext` doit être un descendant du `ScaffoldMessenger`
  /// propre à cet écran (voir `build()`) — jamais `this.context` (l'élément
  /// de `PersonSelectionScreen` lui-même se trouve *au-dessus* de ce
  /// `ScaffoldMessenger` local, pas en dessous : `ScaffoldMessenger.of` y
  /// retomberait sur celui, racine, de `MaterialApp`, partagé par toute
  /// l'app — le snackbar restait alors affiché après avoir quitté l'écran,
  /// y compris après retour au HOME).
  ///
  /// Décocher ne vide jamais le champ (§4 : « le prénom est toujours
  /// facultatif, conservé même après décochage » — même comportement que
  /// l'Onboarding, `_togglePerson`) : le contrôleur garde son texte,
  /// invisible tant que la ligne n'est pas recochée, où il réapparaît tel
  /// quel. La persistance `persons_data` reste par construction limitée aux
  /// personnes cochées (la présence d'une clé EST la sélection) — la
  /// conservation porte donc sur le champ affiché, pas sur un stockage
  /// disque distinct pour une personne décochée, que le modèle existant ne
  /// permet pas de distinguer d'« jamais renseignée ».
  void _uncheck(BuildContext snackBarContext, PersonType person) {
    final previousName = controllers[person]!.text;

    setState(() {
      selectedPersons.remove(person);
    });
    _persist();

    showAppUndoSnackBar(
      snackBarContext,
      message: 'تم إلغاء اختيار ${_possessiveLabel(person)}',
      actionLabel: 'تراجع',
      onUndo: () {
        setState(() {
          selectedPersons.add(person);
          controllers[person]!.text = previousName;
        });
        _persist();
      },
    );
  }

  /// Libellés possessifs déjà établis dans l'écran (`أبي`, `أمي`...) —
  /// repris tels quels, non redécidés par ce lot.
  String _possessiveLabel(PersonType person) {
    switch (person) {
      case PersonType.father:
        return 'أبي';
      case PersonType.mother:
        return 'أمي';
      case PersonType.parents:
        return 'والديّ';
      case PersonType.grandfather:
        return 'جدي';
      case PersonType.grandmother:
        return 'جدتي';
      case PersonType.brother:
        return 'أخي';
      case PersonType.sister:
        return 'أختي';
      case PersonType.son:
        return 'ابني';
      case PersonType.daughter:
        return 'ابنتي';
      case PersonType.husband:
        return 'زوجي';
      case PersonType.wife:
        return 'زوجتي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      // ScaffoldMessenger local à cet écran : le snackbar تراجع est ainsi
      // physiquement détaché quand PersonSelectionScreen quitte l'arbre
      // (retour arrière), au lieu du ScaffoldMessenger racine de
      // MaterialApp (partagé par toute l'app — voir même correctif déjà
      // appliqué à FavoritesScreen).
      child: ScaffoldMessenger(
        child: Scaffold(
          appBar: AppTopBar(
            title: 'تدعو لـ',
            height: 56,
            titleStyle: AppTypography.screenTitle.copyWith(color: cs.onPrimary),
            leading: IconButton(
              icon: Icon(Icons.arrow_forward, color: cs.onPrimary),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          // Aucun CTA en bas (§4) : le bas de l'écran reste vide.
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'يُحفظ اختيارك تلقائيًا',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.label
                        .copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView.separated(
                      itemCount: PersonType.values.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final person = PersonType.values[index];
                        final isSelected = selectedPersons.contains(person);

                        return Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            AppChip(
                              variant: AppChipVariant.person,
                              label: _possessiveLabel(person),
                              selected: isSelected,
                              onTap: () => _toggle(context, person),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextField(
                                  controller: controllers[person],
                                  focusNode: focusNodes[person],
                                  textDirection: TextDirection.rtl,
                                  style: AppTypography.body
                                      .copyWith(color: cs.onSurface),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'الاسم (اختياري)',
                                    // Bordures alignées sur le champ de
                                    // recherche (§P2-D) — `enabledBorder`/
                                    // `focusedBorder` explicites, sinon
                                    // `border:` seul retombe sur le style
                                    // Material par défaut pour ces deux
                                    // états.
                                    border: OutlineInputBorder(
                                        borderRadius: AppRadii.fieldRadius),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: AppRadii.fieldRadius,
                                      borderSide: BorderSide(color: cs.outline, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: AppRadii.fieldRadius,
                                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                                    ),
                                  ),
                                  onChanged: (v) => _onNameChanged(person, v),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
