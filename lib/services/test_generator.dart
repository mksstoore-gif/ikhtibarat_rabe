import 'dart:math';
import '../data/models.dart';

/// Creates varied practice papers without repeating the same question text.
class TestGenerator {
  final Random _random;
  TestGenerator({Random? random}) : _random = random ?? Random();

  static String questionKey(Question q) =>
      q.question.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  /// Use the same unique-question pool in the picker and in generation.
  static List<Question> eligibleQuestions({
    required String subjectId,
    required Iterable<String> lessonIds,
    required Iterable<QuestionType> types,
    required Iterable<Difficulty> difficulties,
    required List<Question> bank,
  }) {
    final lessonSet = lessonIds.toSet();
    final typeSet = types.toSet();
    final difficultySet = difficulties.toSet();
    final seen = <String>{};
    return bank.where((q) =>
        q.subjectId == subjectId &&
        lessonSet.contains(q.lessonId) &&
        typeSet.contains(q.type) &&
        difficultySet.contains(q.difficulty) &&
        seen.add(questionKey(q))).toList();
  }

  GeneratedTest generate({
    required String subjectId,
    required String subjectName,
    required List<String> lessonIds,
    required List<QuestionType> types,
    required List<Difficulty> difficulties,
    required int count,
    required List<Question> bank,
    List<String> lessonNames = const [],
    String title = 'اختبار',
    String studentName = '',
    String schoolName = '',
    String className = '',
  }) {
    final pool = eligibleQuestions(
      subjectId: subjectId,
      lessonIds: lessonIds,
      types: types,
      difficulties: difficulties,
      bank: bank,
    );
    if (pool.length < count) {
      throw StateError(
        'توجد ' + pool.length.toString() +
        ' أسئلة متنوعة فقط بهذه الإعدادات بعد استبعاد المكرر. '
        'اختر دروسًا أكثر أو قلّل عدد الأسئلة.');
    }

    // Choose the least represented lesson/type/difficulty first. Shuffle
    // beforehand to avoid predictable ties while keeping test results stable
    // for a seeded Random in unit tests.
    final available = [...pool]..shuffle(_random);
    final selected = <Question>[];
    final lessonUse = <String, int>{};
    final typeUse = <QuestionType, int>{};
    final difficultyUse = <Difficulty, int>{};
    while (selected.length < count) {
      var bestIndex = 0;
      var bestScore = 1 << 30;
      for (var i = 0; i < available.length; i++) {
        final q = available[i];
        final score =
            (lessonUse[q.lessonId] ?? 0) * 20 +
            (typeUse[q.type] ?? 0) * 8 +
            (difficultyUse[q.difficulty] ?? 0) * 3 +
            (q.question.startsWith('أي العبارتين الآتيتين صحيحة؟') ? 20 : 0);
        if (score < bestScore) {
          bestScore = score;
          bestIndex = i;
        }
      }
      final q = available.removeAt(bestIndex);
      selected.add(q);
      lessonUse[q.lessonId] = (lessonUse[q.lessonId] ?? 0) + 1;
      typeUse[q.type] = (typeUse[q.type] ?? 0) + 1;
      difficultyUse[q.difficulty] = (difficultyUse[q.difficulty] ?? 0) + 1;
    }

    return GeneratedTest(
      id: 'test_' + DateTime.now().microsecondsSinceEpoch.toString(),
      subjectId: subjectId,
      subjectName: subjectName,
      lessonIds: lessonIds,
      lessonNames: lessonNames,
      questions: selected,
      createdAt: DateTime.now(),
      title: title.trim().isEmpty ? 'اختبار' : title.trim(),
      studentName: studentName.trim(),
      schoolName: schoolName.trim(),
      className: className.trim(),
    );
  }
}
