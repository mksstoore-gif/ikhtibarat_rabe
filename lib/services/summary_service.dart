import '../data/curriculum_repository.dart';
import '../data/models.dart';

class StudySummary {
  final String subjectName;
  final DateTime createdAt;
  final List<StudyLessonSummary> lessons;

  const StudySummary({
    required this.subjectName,
    required this.createdAt,
    required this.lessons,
  });
}

class StudyLessonSummary {
  final String lessonId;
  final String lessonName;
  final String unitName;
  final List<String> keyPoints;
  final List<String> questionsAndAnswers;
  final List<String> examples;

  const StudyLessonSummary({
    required this.lessonId,
    required this.lessonName,
    required this.unitName,
    required this.keyPoints,
    required this.questionsAndAnswers,
    required this.examples,
  });
}

class StudySummaryService {
  final CurriculumRepository repo;
  StudySummaryService({CurriculumRepository? repository})
      : repo = repository ?? CurriculumRepository.instance;

  StudySummary build({
    required String subjectId,
    required Set<String> lessonIds,
  }) {
    final selected = repo.lessons
        .where((lesson) =>
            lesson.subjectId == subjectId && lessonIds.contains(lesson.id))
        .toList();

    return StudySummary(
      subjectName: repo.subjectName(subjectId),
      createdAt: DateTime.now(),
      lessons: selected.map(_lessonSummary).toList(),
    );
  }

  StudyLessonSummary _lessonSummary(LessonInfo lesson) {
    final questions =
        repo.questions.where((q) => q.lessonId == lesson.id).toList();

    final points = <String>[];
    final qa = <String>[];
    final examples = <String>[];

    for (final q in questions) {
      if (q.type == QuestionType.trueFalse &&
          _norm(q.correctAnswer) == _norm('صح')) {
        _addUnique(points, q.question, limit: 6);
      }
    }

    if (points.length < 5) {
      for (final q in questions) {
        final explanation = q.explanation.trim();
        if (explanation.isEmpty || _isGenericExplanation(explanation)) continue;
        _addUnique(points, explanation, limit: 6);
      }
    }

    // Exam-first review: prioritize the clearest, most testable facts.
    final ranked = [...questions]..sort((a,b) {
      int score(Question q) {
        var v = 0;
        if (q.type == QuestionType.multipleChoice) v += 5;
        if (q.type == QuestionType.shortAnswer) v += 4;
        if (q.type == QuestionType.fillBlank) v += 4;
        if (q.type == QuestionType.numeric || q.type == QuestionType.applied) v += 5;
        if (q.difficulty == Difficulty.medium) v += 3;
        if (q.difficulty == Difficulty.easy) v += 2;
        if (q.explanation.trim().isNotEmpty && !_isGenericExplanation(q.explanation.trim())) v += 2;
        return v;
      }
      return score(b).compareTo(score(a));
    });

    for (final q in ranked) {
      if ((q.type == QuestionType.shortAnswer ||
          q.type == QuestionType.multipleChoice ||
          q.type == QuestionType.fillBlank ||
          q.type == QuestionType.numeric ||
          q.type == QuestionType.applied) &&
          !q.question.startsWith('أي العبارتين الآتيتين صحيحة؟')) {
        _addUnique(
          qa,
          '${q.question}\nالإجابة: ${q.correctAnswer}',
          limit: 5,
        );
      }
    }

    if (lesson.subjectId == 'math') {
      for (final q in questions) {
        if (q.type == QuestionType.numeric ||
            q.type == QuestionType.applied ||
            q.type == QuestionType.multipleChoice) {
          _addUnique(
            examples,
            '${q.question}\nالناتج: ${q.correctAnswer}',
            limit: 3,
          );
        }
      }
    }

    if (points.isEmpty && lesson.subjectId == 'math') {
      // Only include worked, bank-backed examples; a bare numeric answer
      // is not a meaningful study point by itself.
      for (final question in questions.where((q) =>
          q.type == QuestionType.numeric ||
          q.type == QuestionType.applied)) {
        _addUnique(
          points,
          'تدريب سريع: ' + question.question +
              '\nالإجابة: ' + question.correctAnswer,
          limit: 2,
        );
      }
    }
    if (points.isEmpty && questions.isNotEmpty) {
      points.add('راجع أسئلة الدرس وإجاباتها أدناه؛ لا تتوفر نقاط نظرية موثقة في بنك المراجعة.');
    }

    return StudyLessonSummary(
      lessonId: lesson.id,
      lessonName: lesson.name,
      unitName: repo.unitName(lesson.unitId),
      keyPoints: points.take(5).toList(),
      questionsAndAnswers: qa.take(5).toList(),
      examples: examples.take(3).toList(),
    );
  }

  bool _isGenericExplanation(String value) {
    const generic = [
      'العبارة صحيحة.',
      'العبارة غير صحيحة.',
      'اختر الإجابة التي توافق مفهوم الدرس.',
      'راجع الفكرة الأساسية في الدرس.',
      'إجابة قصيرة مباشرة من مفهوم الدرس.',
      'سؤال تدريبي أصلي مبني على مهارة الدرس الموثق.',
    ];
    return generic.contains(value);
  }

  void _addUnique(List<String> target, String value, {required int limit}) {
    if (target.length >= limit) return;
    final clean = value.trim().split('\n').map((line) =>
        line.replaceAll(RegExp(r'[ \t]+'), ' ').trim()).join('\n');
    if (clean.isEmpty) return;
    final normalized = _norm(clean);
    if (target.any((item) => _norm(item) == normalized)) return;
    target.add(clean);
  }

  String _norm(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}
