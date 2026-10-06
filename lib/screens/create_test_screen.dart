import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
import '../services/test_generator.dart';
import '../theme/app_theme.dart';
import 'solve_test_screen.dart';
import 'subjects_screen.dart';

class CreateTestScreen extends StatefulWidget {
  final String? initialSubjectId;
  const CreateTestScreen({super.key, this.initialSubjectId});

  @override
  State<CreateTestScreen> createState() => _CreateTestState();
}

class _CreateTestState extends State<CreateTestScreen> {
  final repo = CurriculumRepository.instance;
  final generator = TestGenerator();
  final studentController = TextEditingController();
  final titleController = TextEditingController(text: 'اختبار تدريبي');

  String? subjectId;
  Set<String> studied = <String>{};
  final lessonIds = <String>{};
  String questionMode = 'mixed';
  String difficultyMode = 'mixed';
  int count = 10;
  int step = 0;
  bool loading = true;

  static const _stepTitles = <String>[
    'المادة',
    'الدروس',
    'الإعدادات',
    'بيانات الورقة',
    'المراجعة',
  ];

  @override
  void initState() {
    super.initState();
    subjectId = widget.initialSubjectId;
    _loadStudied();
  }

  @override
  void dispose() {
    studentController.dispose();
    titleController.dispose();
    super.dispose();
  }

  Future<void> _loadStudied() async {
    final ids = await AppDatabase.instance.loadStudiedLessonIds();
    if (!mounted) return;
    setState(() {
      studied = ids;
      loading = false;
      if (subjectId != null) {
        _selectAllEligible();
        _fixCount();
        if (widget.initialSubjectId != null) {
          step = 1;
        }
      }
    });
  }

  List<SubjectInfo> get activeSubjects => repo.subjects
      .where((subject) => repo.questionCountForSubject(subject.id) > 0)
      .toList();

  List<LessonInfo> get eligibleLessons {
    if (subjectId == null) return <LessonInfo>[];
    return repo
        .lessonsFor(subjectId!)
        .where(
          (lesson) =>
              studied.contains(lesson.id) && repo.hasQuestionBank(lesson.id),
        )
        .toList();
  }

  Set<QuestionType> get availableTypes {
    final ids =
        lessonIds.isEmpty ? eligibleLessons.map((e) => e.id).toSet() : lessonIds;
    return repo.questions
        .where((question) => ids.contains(question.lessonId))
        .map((question) => question.type)
        .toSet();
  }

  Set<QuestionType> get selectedTypes {
    final available = availableTypes;
    if (questionMode == 'tf') {
      return {QuestionType.trueFalse}.intersection(available);
    }
    if (questionMode == 'mcq') {
      return {QuestionType.multipleChoice}.intersection(available);
    }
    if (questionMode == 'written') {
      const written = {
        QuestionType.fillBlank,
        QuestionType.shortAnswer,
        QuestionType.numeric,
        QuestionType.reading,
        QuestionType.applied,
        QuestionType.ordering,
        QuestionType.matching,
        QuestionType.imageChoice,
      };
      return written.intersection(available);
    }
    return available;
  }

  Set<Difficulty> get selectedDifficulties {
    if (difficultyMode == 'easy') return {Difficulty.easy};
    if (difficultyMode == 'medium') return {Difficulty.medium};
    if (difficultyMode == 'hard') return {Difficulty.hard};
    return Difficulty.values.toSet();
  }

  int get matchingPool {
    if (subjectId == null || lessonIds.isEmpty || selectedTypes.isEmpty) {
      return 0;
    }
    return repo.questions
        .where(
          (question) =>
              question.subjectId == subjectId &&
              lessonIds.contains(question.lessonId) &&
              selectedTypes.contains(question.type) &&
              selectedDifficulties.contains(question.difficulty),
        )
        .length;
  }

  void _selectSubject(String id) {
    setState(() {
      subjectId = id;
      lessonIds.clear();
      _selectAllEligible();
      questionMode = 'mixed';
      difficultyMode = 'mixed';
      count = 10;
      _fixCount();
    });
  }

  void _selectAllEligible() {
    lessonIds
      ..clear()
      ..addAll(eligibleLessons.map((e) => e.id));
  }

  void _fixCount() {
    final pool = matchingPool;
    const choices = [5, 10, 15, 20, 25, 30];
    final allowed = choices.where((n) => n <= pool).toList();
    if (allowed.isEmpty) {
      count = pool;
    } else if (!allowed.contains(count)) {
      count = allowed.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء اختبار'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  (step + 1).toString() + ' / ' + _stepTitles.length.toString(),
                  style: const TextStyle(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(step: step, titles: _stepTitles),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: _buildStep(context),
                ),
              ),
            ),
            _BottomControls(
              step: step,
              totalSteps: _stepTitles.length,
              canContinue: _canContinue,
              onBack: step == 0
                  ? null
                  : () => setState(() {
                        step -= 1;
                      }),
              onNext: step == _stepTitles.length - 1
                  ? _generate
                  : () => setState(() {
                        step += 1;
                      }),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canContinue {
    switch (step) {
      case 0:
        return subjectId != null;
      case 1:
        return lessonIds.isNotEmpty;
      case 2:
        return matchingPool > 0 && count > 0;
      case 3:
        return titleController.text.trim().isNotEmpty;
      default:
        return matchingPool > 0 && lessonIds.isNotEmpty;
    }
  }

  Widget _buildStep(BuildContext context) {
    switch (step) {
      case 0:
        return _subjectStep();
      case 1:
        return _lessonsStep(context);
      case 2:
        return _settingsStep();
      case 3:
        return _paperStep();
      default:
        return _reviewStep();
    }
  }

  Widget _subjectStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const _StepIntro(
          eyebrow: 'الخطوة الأولى',
          title: 'وش المادة اليوم؟',
          subtitle: 'اختر مادة واحدة، وبعدها نحدد الدروس بدقة.',
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: 20),
        ...activeSubjects.map(
          (subject) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _SubjectOption(
              title: subject.name,
              subtitle:
                  repo.questionCountForSubject(subject.id).toString() +
                      ' سؤال تدريبي متاح',
              icon: _iconFor(subject.id),
              accent: _colorFor(subject.id),
              selected: subjectId == subject.id,
              onTap: () => _selectSubject(subject.id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lessonsStep(BuildContext context) {
    final eligible = eligibleLessons;
    final units =
        subjectId == null ? <CurriculumUnit>[] : repo.unitsFor(subjectId!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const _StepIntro(
          eyebrow: 'الخطوة الثانية',
          title: 'حدد نطاق الاختبار',
          subtitle: 'لن يظهر أي سؤال من درس غير محدد هنا.',
          icon: Icons.checklist_rtl_rounded,
        ),
        const SizedBox(height: 18),
        if (eligible.isEmpty)
          _EmptyLessons(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectsScreen(repository: repo),
                ),
              );
              await _loadStudied();
            },
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.done_all_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lessonIds.length.toString() +
                        ' من ' +
                        eligible.length.toString() +
                        ' درس محدد',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (lessonIds.length == eligible.length) {
                      lessonIds.clear();
                    } else {
                      _selectAllEligible();
                    }
                    _fixCount();
                  }),
                  child: Text(
                    lessonIds.length == eligible.length
                        ? 'إلغاء الكل'
                        : 'تحديد الكل',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...units.map((unit) {
            final lessons = repo
                .lessonsForUnit(unit.id)
                .where(
                  (lesson) =>
                      eligible.any((eligible) => eligible.id == lesson.id),
                )
                .toList();
            if (lessons.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft(),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  unit.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  lessons.length.toString() + ' درس',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: lessons
                    .map(
                      (lesson) => CheckboxListTile(
                        dense: false,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        value: lessonIds.contains(lesson.id),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        title: Text(
                          lesson.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          repo.questionCountForLesson(lesson.id).toString() +
                              ' سؤال متاح',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            lessonIds.add(lesson.id);
                          } else {
                            lessonIds.remove(lesson.id);
                          }
                          _fixCount();
                        }),
                      ),
                    )
                    .toList(),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _settingsStep() {
    final pool = matchingPool;
    final countChoices =
        [5, 10, 15, 20, 25, 30].where((n) => n <= pool).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const _StepIntro(
          eyebrow: 'الخطوة الثالثة',
          title: 'صمّم الاختبار',
          subtitle: 'اختر الشكل والمستوى والحجم المناسب.',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 20),
        _OptionSection(
          title: 'نوع الأسئلة',
          icon: Icons.quiz_rounded,
          child: _choiceWrap(
            const [
              ('mixed', 'متنوع'),
              ('tf', 'صح / خطأ'),
              ('mcq', 'اختيارات'),
              ('written', 'كتابي'),
            ],
            questionMode,
            (value) => setState(() {
              questionMode = value;
              _fixCount();
            }),
          ),
        ),
        const SizedBox(height: 12),
        _OptionSection(
          title: 'مستوى الصعوبة',
          icon: Icons.speed_rounded,
          child: _choiceWrap(
            const [
              ('mixed', 'مختلط'),
              ('easy', 'سهل'),
              ('medium', 'متوسط'),
              ('hard', 'صعب'),
            ],
            difficultyMode,
            (value) => setState(() {
              difficultyMode = value;
              _fixCount();
            }),
          ),
        ),
        const SizedBox(height: 12),
        _OptionSection(
          title: 'عدد الأسئلة',
          icon: Icons.format_list_numbered_rounded,
          child: pool == 0
              ? const Text(
                  'لا توجد أسئلة مطابقة لهذه الإعدادات. غيّر النوع أو المستوى.',
                  style: TextStyle(
                    color: AppColors.danger,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...countChoices.map(
                      (number) => ChoiceChip(
                        selected: count == number,
                        showCheckmark: false,
                        label: Text(number.toString()),
                        onSelected: (_) => setState(() {
                          count = number;
                        }),
                      ),
                    ),
                    if (countChoices.isEmpty)
                      ChoiceChip(
                        selected: true,
                        showCheckmark: false,
                        label: Text(pool.toString()),
                        onSelected: (_) => setState(() {
                          count = pool;
                        }),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'متاح بهذه الإعدادات: ' + pool.toString() + ' سؤال',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paperStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const _StepIntro(
          eyebrow: 'الخطوة الرابعة',
          title: 'لمسة أخيرة',
          subtitle: 'هذه البيانات ستظهر في ورقة الاختبار وملف PDF.',
          icon: Icons.edit_document,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft(),
          ),
          child: Column(
            children: [
              TextField(
                controller: studentController,
                decoration: const InputDecoration(
                  labelText: 'اسم الطالب (اختياري)',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'عنوان الاختبار',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoSoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: AppColors.info),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'يمكنك بعد الإنشاء معاينة نسخة الطالب، نموذج الإجابة، أو مشاركة PDF كامل.',
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
      ],
    );
  }

  Widget _reviewStep() {
    final subjectName =
        subjectId == null ? '—' : repo.subjectName(subjectId!);
    final typeLabel = switch (questionMode) {
      'tf' => 'صح / خطأ',
      'mcq' => 'اختيار من متعدد',
      'written' => 'كتابي',
      _ => 'متنوع',
    };
    final difficultyLabel = switch (difficultyMode) {
      'easy' => 'سهل',
      'medium' => 'متوسط',
      'hard' => 'صعب',
      _ => 'مختلط',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const _StepIntro(
          eyebrow: 'جاهز',
          title: 'راجع قبل البدء',
          subtitle: 'كل شيء مضبوط. اضغط إنشاء وابدأ الحل.',
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 20),
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
          child: Column(
            children: [
              _ReviewRow(
                icon: Icons.school_rounded,
                label: 'المادة',
                value: subjectName,
              ),
              const _ReviewDivider(),
              _ReviewRow(
                icon: Icons.checklist_rounded,
                label: 'الدروس',
                value: lessonIds.length.toString() + ' درس',
              ),
              const _ReviewDivider(),
              _ReviewRow(
                icon: Icons.quiz_rounded,
                label: 'الأسئلة',
                value: count.toString() + ' — ' + typeLabel,
              ),
              const _ReviewDivider(),
              _ReviewRow(
                icon: Icons.speed_rounded,
                label: 'المستوى',
                value: difficultyLabel,
              ),
              const _ReviewDivider(),
              _ReviewRow(
                icon: Icons.description_rounded,
                label: 'العنوان',
                value: titleController.text.trim().isEmpty
                    ? 'اختبار تدريبي'
                    : titleController.text.trim(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _choiceWrap(
    List<(String, String)> choices,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices
          .map(
            (choice) => ChoiceChip(
              selected: selected == choice.$1,
              showCheckmark: false,
              label: Text(choice.$2),
              onSelected: (_) => onChanged(choice.$1),
            ),
          )
          .toList(),
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

  void _generate() {
    if (subjectId == null || lessonIds.isEmpty || count <= 0) {
      _error('اختر المادة والدروس أولًا.');
      return;
    }
    try {
      final selectedLessons =
          repo.lessons.where((lesson) => lessonIds.contains(lesson.id)).toList();
      final test = generator.generate(
        subjectId: subjectId!,
        subjectName: repo.subjectName(subjectId!),
        lessonIds: lessonIds.toList(),
        lessonNames: selectedLessons.map((e) => e.name).toList(),
        types: selectedTypes.toList(),
        difficulties: selectedDifficulties.toList(),
        count: count,
        bank: repo.questions,
        title: titleController.text,
        studentName: studentController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SolveTestScreen(test: test)),
      );
    } on StateError catch (error) {
      _error(error.message);
    }
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  final List<String> titles;

  const _ProgressHeader({required this.step, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              titles.length,
              (index) => Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsetsDirectional.only(
                    start: index == 0 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: index <= step
                        ? AppColors.primary
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                titles[step],
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Text(
                'اختبار مخصص',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF9A84FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.45,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _SubjectOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withOpacity(.07) : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? AppShadows.soft(accent) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accent : AppColors.border,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _OptionSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(.76), size: 20),
        const SizedBox(width: 11),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.60),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewDivider extends StatelessWidget {
  const _ReviewDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 28,
        color: Colors.white.withOpacity(.08),
      );
}

class _BottomControls extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _BottomControls({
    required this.step,
    required this.totalSteps,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            SizedBox(
              width: 106,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('رجوع'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: canContinue ? onNext : null,
              icon: Icon(
                isLast ? Icons.auto_awesome_rounded : Icons.arrow_back_rounded,
              ),
              label: Text(
                isLast ? 'إنشاء الاختبار' : 'التالي',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLessons extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyLessons({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.gold.withOpacity(.35)),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 31,
                color: Color(0xFFC68A16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'حدد أولًا الدروس التي درسها الطالب',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'بعدها سيبني التطبيق الاختبار من هذه الدروس فقط.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onTap,
              child: const Text('اختيار الدروس المدروسة'),
            ),
          ],
        ),
      );
}
