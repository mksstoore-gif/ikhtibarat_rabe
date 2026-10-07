import 'package:flutter/material.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
import '../services/summary_pdf_service.dart';
import '../services/summary_service.dart';
import '../theme/app_theme.dart';

class StudySummaryScreen extends StatefulWidget {
  const StudySummaryScreen({super.key});

  @override
  State<StudySummaryScreen> createState() => _StudySummaryScreenState();
}

class _StudySummaryScreenState extends State<StudySummaryScreen> {
  final repo = CurriculumRepository.instance;
  String? subjectId;
  final selectedLessons = <String>{};
  StudySummary? summary;
  bool busy = false;

  List<SubjectInfo> get subjects => repo.subjects
      .where((subject) => repo.questionCountForSubject(subject.id) > 0)
      .toList();

  List<LessonInfo> get lessons {
    if (subjectId == null) return const [];
    return repo
        .lessonsFor(subjectId!)
        .where((lesson) => repo.hasQuestionBank(lesson.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (summary != null) return _summaryView();

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء ملخص للمذاكرة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          _intro(),
          const SizedBox(height: 20),
          const Text(
            '1. اختر المادة',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects
                .map(
                  (subject) => ChoiceChip(
                    selected: subjectId == subject.id,
                    label: Text(subject.name),
                    onSelected: (_) => setState(() {
                      subjectId = subject.id;
                      selectedLessons.clear();
                    }),
                  ),
                )
                .toList(),
          ),
          if (subjectId != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '2. اختر الدروس',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (selectedLessons.length == lessons.length) {
                      selectedLessons.clear();
                    } else {
                      selectedLessons
                        ..clear()
                        ..addAll(lessons.map((e) => e.id));
                    }
                  }),
                  child: Text(
                    selectedLessons.length == lessons.length
                        ? 'إلغاء الكل'
                        : 'تحديد الكل',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...repo.unitsFor(subjectId!).map(_unitCard),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: FilledButton.icon(
          onPressed: selectedLessons.isEmpty || busy ? null : _generate,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            selectedLessons.isEmpty
                ? 'اختر درسًا واحدًا على الأقل'
                : 'إنشاء الملخص (${selectedLessons.length} درس)',
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, AppColors.navySoft],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.glow(AppColors.navy),
      ),
      child: const Row(
        children: [
          Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 38),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص جاهز للمذاكرة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'ملخص قصير ومركز على أهم ما يُسأل عنه في الاختبار: الفكرة الأساسية، السؤال المتوقع، والإجابة المباشرة.',
                  style: TextStyle(
                    color: Color(0xFFC9CDE0),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitCard(CurriculumUnit unit) {
    final unitLessons = repo
        .lessonsForUnit(unit.id)
        .where((lesson) => repo.hasQuestionBank(lesson.id))
        .toList();
    if (unitLessons.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          unit.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        children: unitLessons
            .map(
              (lesson) => CheckboxListTile(
                value: selectedLessons.contains(lesson.id),
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  lesson.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${repo.questionCountForLesson(lesson.id)} نقطة تدريبية متاحة',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selectedLessons.add(lesson.id);
                  } else {
                    selectedLessons.remove(lesson.id);
                  }
                }),
              ),
            )
            .toList(),
      ),
    );
  }

  void _generate() {
    setState(() {
      busy = true;
      summary = StudySummaryService(repository: repo).build(
        subjectId: subjectId!,
        lessonIds: selectedLessons,
      );
      busy = false;
    });
  }

  Widget _summaryView() {
    final data = summary!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص المذاكرة'),
        actions: [
          IconButton(
            tooltip: 'تعديل الدروس',
            onPressed: () => setState(() => summary = null),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'PDF',
            onPressed: _pdfMenu,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${data.subjectName} • ${data.lessons.length} درس',
                    style: const TextStyle(
                      color: AppColors.primaryDeep,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...data.lessons.map(_lessonSummaryCard),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: FilledButton.icon(
          onPressed: _sharePdf,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('مشاركة الملخص PDF'),
        ),
      ),
    );
  }

  Widget _lessonSummaryCard(StudyLessonSummary lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lesson.lessonName,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            lesson.unitName,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const _MiniTitle('الزبدة التي تحفظها', Icons.lightbulb_rounded),
          ...lesson.keyPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '• $point',
                style: const TextStyle(height: 1.55, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (lesson.questionsAndAnswers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _MiniTitle('أسئلة متوقعة في الاختبار', Icons.help_outline_rounded),
            ...lesson.questionsAndAnswers.take(3).map(
                  (item) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item, style: const TextStyle(height: 1.5)),
                  ),
                ),
          ],
          if (lesson.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _MiniTitle('مثال مهم', Icons.calculate_rounded),
            ...lesson.examples.take(2).map(
                  (item) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item, style: const TextStyle(height: 1.5)),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _pdfMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'ملخص PDF',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              subtitle: Text('جاهز للطباعة أو المذاكرة من الجوال'),
            ),
            ListTile(
              leading: const Icon(Icons.preview_rounded),
              title: const Text('معاينة وطباعة'),
              onTap: () => Navigator.pop(context, 'preview'),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('مشاركة PDF'),
              onTap: () => Navigator.pop(context, 'share'),
            ),
          ],
        ),
      ),
    );
    if (action == 'preview') await _previewPdf();
    if (action == 'share') await _sharePdf();
  }

  Future<void> _previewPdf() async {
    final service = SummaryPdfService();
    final bytes = await service.build(summary!);
    await service.preview(bytes);
  }

  Future<void> _sharePdf() async {
    final service = SummaryPdfService();
    final bytes = await service.build(summary!);
    await service.share(bytes);
  }
}

class _MiniTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const _MiniTitle(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}
