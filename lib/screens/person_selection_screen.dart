import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/person_type.dart';
import '../user_prefs.dart';


class PersonSelectionScreen extends StatefulWidget {
  const PersonSelectionScreen({super.key});

  @override
  State<PersonSelectionScreen> createState() => _PersonSelectionScreenState();
}

class _PersonSelectionScreenState extends State<PersonSelectionScreen> {

  Set<PersonType> selectedPersons = {};

  Map<PersonType, TextEditingController> controllers = {};
  Map<String, String> personsData = {};

  @override
  void initState() {
    super.initState();

    // ✅ init controllers
    for (var person in PersonType.values) {
      controllers[person] = TextEditingController();
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final data = await UserPrefs.getPersonsData();

    setState(() {
      selectedPersons = data.keys
          .map((e) => PersonType.values.firstWhere((p) => p.name == e))
          .toSet();

      for (var person in PersonType.values) {
        controllers[person]!.text = data[person.name] ?? '';
      }
    });
  }

  Future<void> _save() async {
    Map<String, String> data = {};

    for (var person in selectedPersons) {
      final name = controllers[person]!.text.trim();

      if (name.isNotEmpty) {
        data[person.name] = name;
      }
    }

    await UserPrefs.savePersonsData(data);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختيار الأشخاص'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              const Text(
                'اختر الأشخاص الذين تريد الدعاء لهم',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600,),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                'تم اختيار ${selectedPersons.length} أشخاص',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w600,
                ),

              ),
              const SizedBox(height: 6),
              personsData.isEmpty
                  ? const Text(
                'لم يتم اختيار أي شخص',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              )
                  : Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: personsData.entries.map((e) {
                  String label;

                  switch (e.key) {
                    case 'father':
                      label = 'أبي';
                      break;
                    case 'mother':
                      label = 'أمي';
                      break;
                    case 'parents':
                      label = 'والديّ';
                      break;
                    case 'grandfather':
                      label = 'جدي';
                      break;
                    case 'grandmother':
                      label = 'جدتي';
                      break;
                    case 'brother':
                      label = 'أخي';
                      break;
                    case 'sister':
                      label = 'أختي';
                      break;
                    case 'son':
                      label = 'ابني';
                      break;
                    case 'daughter':
                      label = 'ابنتي';
                      break;
                    case 'husband':
                      label = 'زوجي';
                      break;
                    case 'wife':
                      label = 'زوجتي';
                      break;
                    default:
                      label = '';
                  }

                  return
                    InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            selectedPersons.removeWhere((p) => p.name == e.key);
                            personsData.remove(e.key); // ✅ IMPORTANT (ne pas oublier)
                          });
                        },
                      child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      // ✅ fond doré léger
                      color: const Color(0xFFB8860B)
                          .withOpacity(0.2),

                      // ✅ bordure dorée élégante
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFB8860B),
                        width: 1.2,
                      ),

                      // ✅ petit effet shadow premium
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFFD4AF37),
                          // ✅ doré appliqué correctement
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$label ${e.value}',
                          style: const TextStyle(
                            color:
                            Colors.white, // ✅ texte lisible
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),);
                }).toList(),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: PersonType.values.map((person) {

                    final isSelected = selectedPersons.contains(person);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4AF37).withOpacity(0.08)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD4AF37)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selectedPersons.add(person);
                                  personsData[person.name] = controllers[person]!.text;
                                } else {
                                  selectedPersons.remove(person);
                                  controllers[person]!.clear();
                                }
                              });
                            },
                          ),

                          Expanded(
                            child: Text(
                              person.label,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),

                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: controllers[person],
                              enabled: isSelected,
                              decoration: InputDecoration(
                                hintText: isSelected ? 'أدخل الاسم' : 'اضغط لاختيار',
                                hintStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.grey
                                      : Colors.grey,
                                  fontSize: 13,
                                ),

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),

                                filled: true,
                                fillColor: isSelected
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.08),

                                // ✅ bordure plus fine et premium
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),

                                // ✅ bordure active
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFFD4AF37).withOpacity(0.5)
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4AF37),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child:
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A4A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(color: Colors.white,fontSize: 16),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}