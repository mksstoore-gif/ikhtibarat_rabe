import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../theme/app_theme.dart';

class SubjectsScreen extends StatefulWidget {
  final CurriculumRepository repository;
  const SubjectsScreen({super.key, required this.repository});

  @override
  State<SubjectsScreen> createState() => _SubjectsState();
}

class _SubjectsState extends State<SubjectsScreen> {
  Set<String> studied = <String>{};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await AppDatabase.instance.loadStudiedLessonIds();
    if (!mounted) return;
    setState(() {
      studied = ids;
      loading = false;
    });
  }

  Future<void> _set(String id, bool value) async {
    setState(() {
      if (value) {
        studied.add(id);
      } else {
        studied.remove(id);
      }
    });
    await AppDatabase.instance.setLessonStudied(id, value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.repository.subjects
        .where(
          (subject) =>
              widget.repository.questionCountForSubject(subject.id) > 0,
        )
        .toList();

    final totalLessons = active
        .expand((subject) => widget.repository.lessonsFor(subject.id))
        .where((lesson) => widget.repository.hasQuestionBank(lesson.id))
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('الدروس المدروسة')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.navy, AppColors.navySoft],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppShadows.glow(AppColors.navy),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.09),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.checklist_rtl_rounded,
                          color: AppColors.gold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حدد ما تم شرحه',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              studied.length.toString() +
                                  ' من ' +
                                  totalLessons.toString() +
                                  ' درس محدد',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.60),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.info),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'منشئ الاختبارات يلتزم بالدروس التي تحددها هنا فقط.',
                          style: TextStyle(
                            color: AppColors.text,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...active.map((subject) {
                  final subjectLessons =
                      widget.repository.lessonsFor(subject.id).where((lesson) {
                    return widget.repository.hasQuestionBank(lesson.id);
                  }).toList();
                  final selectedCount = subjectLessons
                      .where((lesson) => studied.contains(lesson.id))
                      .length;
                  final accent = _colorFor(subject.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft(),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(8, 0, 8, 10),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.11),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_iconFor(subject.id), color: accent),
                      ),
                      title: Text(
                        subject.name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        selectedCount.toString() +
                            ' من ' +
                            subjectLessons.length.toString() +
                            ' درس محدد',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children:
                          widget.repository.unitsFor(subject.id).map((unit) {
                        final lessons = widget.repository
                            .lessonsForUnit(unit.id)
                            .where(
                              (lesson) =>
                                  widget.repository.hasQuestionBank(lesson.id),
                            )
                            .toList();

                        if (lessons.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Text(
                            unit.name,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          children: lessons
                              .map(
                                (lesson) => CheckboxListTile(
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  activeColor: accent,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  value: studied.contains(lesson.id),
                                  onChanged: (value) =>
                                      _set(lesson.id, value ?? false),
                                  title: Text(
                                    lesson.name,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    widget.repository
                                            .questionCountForLesson(lesson.id)
                                            .toString() +
                                        ' سؤال تدريبي',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'math' => Icons.calculate_rounded,
        'arabic' => Icons.menu_book_rounded,
        'science' => Icons.science_rounded,
        'social' => Icons.public_rounded,
        'islamic' => Icons.auto_stories_rounded,
        _ => Icons.school_rounded,
      };

  Color _colorFor(String id) => switch (id) {
        'math' => const Color(0xFF7259F7),
        'arabic' => const Color(0xFF4A7CF7),
        'science' => const Color(0xFF20B486),
        'social' => const Color(0xFFF29A3F),
        'islamic' => const Color(0xFF258D7C),
        _ => AppColors.primary,
      };
}
