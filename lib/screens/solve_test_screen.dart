import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../data/models.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class SolveTestScreen extends StatefulWidget {
  final GeneratedTest test;
  const SolveTestScreen({super.key, required this.test});

  @override
  State<SolveTestScreen> createState() => _SolveTestState();
}

class _SolveTestState extends State<SolveTestScreen> {
  final answers = <String, String>{};
  final controller = PageController();
  int index = 0;
  bool submitted = false;
  int earned = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.test.questions.length;
    final answered = widget.test.questions
        .where((question) => (answers[question.id] ?? '').trim().isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.test.subjectName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'طباعة ومشاركة',
            onPressed: _showPdfMenu,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _QuizHeader(
              title: widget.test.title,
              date: DateFormat('yyyy/MM/dd').format(widget.test.createdAt),
              current: index + 1,
              total: total,
              answered: answered,
              submitted: submitted,
              earned: earned,
              totalScore: widget.test.totalScore,
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: total,
                onPageChanged: (value) => setState(() {
                  index = value;
                }),
                itemBuilder: (context, i) {
                  final question = widget.test.questions[i];
                  return _QuestionPage(
                    number: i + 1,
                    total: total,
                    question: question,
                    value: answers[question.id],
                    submitted: submitted,
                    onChanged: (value) => setState(() {
                      answers[question.id] = value;
                    }),
                  );
                },
              ),
            ),
            _QuizControls(
              index: index,
              total: total,
              submitted: submitted,
              onPrevious: index == 0
                  ? null
                  : () => controller.previousPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                      ),
              onNext: index == total - 1
                  ? null
                  : () => controller.nextPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                      ),
              onSubmit: submitted ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final missing = widget.test.questions
        .where((question) => (answers[question.id] ?? '').trim().isEmpty)
        .length;

    if (missing > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('باقي ' + missing.toString() + ' سؤال بدون إجابة.'),
        ),
      );
      return;
    }

    var score = 0;
    for (final question in widget.test.questions) {
      final correct = _normalize(answers[question.id] ?? '') ==
          _normalize(question.correctAnswer);
      if (correct) score += question.score;
      await AppDatabase.instance.updateSkill(
        question.skillId,
        correct: correct,
      );
    }

    await AppDatabase.instance.saveResult(
      TestHistoryItem(
        testId: widget.test.id,
        subjectName: widget.test.subjectName,
        lessons: (widget.test.lessonNames.isEmpty
                ? widget.test.lessonIds
                : widget.test.lessonNames)
            .join('، '),
        questionCount: widget.test.questions.length,
        earnedScore: score,
        totalScore: widget.test.totalScore,
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    setState(() {
      submitted = true;
      earned = score;
    });
    await _showResult();
  }

  String _normalize(String value) => normalizeStudentAnswer(value);

  Future<void> _showResult() async {
    final percent = widget.test.totalScore == 0
        ? 0
        : (earned / widget.test.totalScore * 100).round();
    final accent = percent >= 80
        ? AppColors.success
        : percent >= 60
            ? AppColors.gold
            : AppColors.danger;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: CircularProgressIndicator(
                        value: percent / 100,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        color: accent,
                        backgroundColor: accent.withOpacity(.12),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          percent.toString() + '%',
                          style: TextStyle(
                            color: accent,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'النتيجة',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                percent >= 80
                    ? 'أداء ممتاز'
                    : percent >= 60
                        ? 'أداء جيد'
                        : 'نحتاج مراجعة بسيطة',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'حصلت على ' +
                    earned.toString() +
                    ' من ' +
                    widget.test.totalScore.toString() +
                    ' درجات.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('مراجعة الإجابات'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pdfAction('result_share');
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('مشاركة تقرير النتيجة PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPdfMenu() async {
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'الطباعة وملفات PDF',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              subtitle: Text(
                'اختر النسخة المناسبة لك',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            _PdfAction(
              icon: Icons.description_outlined,
              title: 'معاينة نسخة الطالب',
              subtitle: 'ورقة اختبار بدون إجابات',
              onTap: () => Navigator.pop(context, 'student_print'),
            ),
            _PdfAction(
              icon: Icons.share_outlined,
              title: 'مشاركة نسخة الطالب',
              subtitle: 'إرسال الورقة كملف PDF',
              onTap: () => Navigator.pop(context, 'student_share'),
            ),
            _PdfAction(
              icon: Icons.fact_check_outlined,
              title: 'معاينة نموذج الإجابة',
              subtitle: 'الإجابات مع الشرح المختصر',
              onTap: () => Navigator.pop(context, 'answers_print'),
            ),
            _PdfAction(
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDF كامل',
              subtitle: 'نسخة الطالب + نموذج الإجابة',
              onTap: () => Navigator.pop(context, 'bundle_share'),
            ),
            if (submitted)
              _PdfAction(
                icon: Icons.assessment_rounded,
                title: 'تقرير نتيجة الطالب',
                subtitle: 'الدرجة + النسبة + نقاط المراجعة والتوصية',
                onTap: () => Navigator.pop(context, 'result_share'),
              ),
          ],
        ),
      ),
    );
    if (action != null) await _pdfAction(action);
  }

  Future<void> _pdfAction(String action) async {
    if (!mounted || (action == 'result_share' && !submitted)) return;

    final service = PdfService();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    late final Uint8List bytes;
    try {
      // Allow the progress overlay to render before heavy PDF work starts.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      if (action == 'result_share') {
        bytes = await service.buildResultPdf(
          widget.test,
          earnedScore: earned,
          answers: answers,
        );
      } else if (action.startsWith('bundle')) {
        bytes = await service.buildCombinedPdf(widget.test);
      } else {
        final answersVersion = action.startsWith('answers');
        bytes = await service.buildTestPdf(
          widget.test,
          includeAnswers: answersVersion,
          includeExplanations: answersVersion,
        );
      }
      if (bytes.isEmpty) throw StateError('الملف الناتج فارغ');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('تعذر توليد PDF: $error'),
        ),
      );
      return;
    } finally {
      // Never pop the test screen when sharing or printing fails.
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;
    try {
      if (action.endsWith('share')) {
        final filename = action == 'result_share'
            ? 'تقرير_نتيجة_الطالب.pdf'
            : action.startsWith('bundle')
                ? 'اختبار_ونموذج_الإجابة.pdf'
                : action.startsWith('answers')
                    ? 'نموذج_الإجابة.pdf'
                    : 'نسخة_الطالب.pdf';
        await service.share(bytes, filename: filename);
      } else {
        await service.printOrPreview(bytes);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('تم توليد PDF لكن تعذر فتحه أو مشاركته: $error'),
        ),
      );
    }
  }
}

class _QuizHeader extends StatelessWidget {
  final String title;
  final String date;
  final int current;
  final int total;
  final int answered;
  final bool submitted;
  final int earned;
  final int totalScore;

  const _QuizHeader({
    required this.title,
    required this.date,
    required this.current,
    required this.total,
    required this.answered,
    required this.submitted,
    required this.earned,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppShadows.glow(AppColors.navy),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                date,
                style: TextStyle(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 8,
              color: AppColors.gold,
              backgroundColor: Colors.white.withOpacity(.10),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                'السؤال ' +
                    current.toString() +
                    ' من ' +
                    total.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                submitted
                    ? 'النتيجة ' +
                        earned.toString() +
                        ' / ' +
                        totalScore.toString()
                    : 'تمت الإجابة ' +
                        answered.toString() +
                        ' / ' +
                        total.toString(),
                style: TextStyle(
                  color: submitted
                      ? const Color(0xFF8EE2B8)
                      : Colors.white.withOpacity(.62),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final int number;
  final int total;
  final Question question;
  final String? value;
  final bool submitted;
  final ValueChanged<String> onChanged;

  const _QuestionPage({
    required this.number,
    required this.total,
    required this.question,
    required this.value,
    required this.submitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final correct = (value ?? '').trim().toLowerCase() ==
        question.correctAnswer.trim().toLowerCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 19, 18, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'سؤال ' + number.toString(),
                    style: const TextStyle(
                      color: AppColors.primaryDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                _DifficultyBadge(difficulty: question.difficulty),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 22,
                height: 1.55,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _instruction(question.type),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            if (question.type == QuestionType.trueFalse)
              Row(
                children: [
                  Expanded(
                    child: _LargeChoice(
                      label: 'صح',
                      icon: Icons.check_rounded,
                      selected: value == 'صح',
                      enabled: !submitted,
                      onTap: () => onChanged('صح'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LargeChoice(
                      label: 'خطأ',
                      icon: Icons.close_rounded,
                      selected: value == 'خطأ',
                      enabled: !submitted,
                      onTap: () => onChanged('خطأ'),
                    ),
                  ),
                ],
              )
            else if (question.options.isNotEmpty)
              ...question.options.asMap().entries.map(
                    (entry) => _OptionTile(
                      index: entry.key,
                      label: entry.value,
                      selected: value == entry.value,
                      enabled: !submitted,
                      onTap: () => onChanged(entry.value),
                    ),
                  )
            else
              TextFormField(
                key: ValueKey(question.id),
                initialValue: value,
                enabled: !submitted,
                minLines: question.type == QuestionType.shortAnswer ? 2 : 1,
                maxLines: question.type == QuestionType.shortAnswer ? 4 : 1,
                keyboardType: question.type == QuestionType.numeric
                    ? TextInputType.number
                    : TextInputType.text,
                decoration: const InputDecoration(
                  hintText: 'اكتب إجابتك هنا',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                onChanged: onChanged,
              ),
            if (submitted) ...[
              const SizedBox(height: 22),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      correct ? AppColors.successSoft : AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (correct ? AppColors.success : AppColors.danger)
                        .withOpacity(.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          correct
                              ? Icons.verified_rounded
                              : Icons.info_rounded,
                          color: correct
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          correct ? 'إجابة صحيحة' : 'الإجابة تحتاج مراجعة',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: correct
                                ? const Color(0xFF147A4B)
                                : const Color(0xFFB73D3D),
                          ),
                        ),
                      ],
                    ),
                    if (!correct) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الإجابة الصحيحة: ' + question.correctAnswer,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    if (question.explanation.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        question.explanation,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _instruction(QuestionType type) => switch (type) {
        QuestionType.trueFalse => 'اختر صح أو خطأ.',
        QuestionType.multipleChoice => 'اختر إجابة واحدة من الخيارات.',
        QuestionType.numeric => 'اكتب الناتج في الخانة.',
        _ => 'اكتب إجابتك في الخانة.',
      };
}

class _DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      Difficulty.easy => AppColors.success,
      Difficulty.medium => AppColors.gold,
      Difficulty.hard => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LargeChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LargeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(21),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.primaryDeep : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      );
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      )
                    : Text(
                        index < letters.length ? letters[index] : '',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15.5,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
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

class _QuizControls extends StatelessWidget {
  final int index;
  final int total;
  final bool submitted;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const _QuizControls({
    required this.index,
    required this.total,
    required this.submitted,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
          SizedBox(
            width: 106,
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('السابق'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isLast
                ? FilledButton.icon(
                    onPressed: onSubmit,
                    icon: Icon(
                      submitted
                          ? Icons.verified_rounded
                          : Icons.flag_rounded,
                    ),
                    label: Text(
                      submitted ? 'تم التسليم' : 'تسليم الاختبار',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text(
                      'التالي',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PdfAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PdfAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Material(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
