import 'dart:math';
import '../data/models.dart';

class TestGenerator {
  final Random _random;
  TestGenerator({Random? random}) : _random = random ?? Random();

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
    final pool = bank.where((q) =>
      q.subjectId == subjectId &&
      lessonIds.contains(q.lessonId) &&
      types.contains(q.type) &&
      difficulties.contains(q.difficulty)
    ).toList();

    if (pool.length < count) {
      throw StateError('بنك الأسئلة المطابق يحتوي ${pool.length} سؤالًا فقط، بينما المطلوب $count.');
    }

    // Build a teacher-like balanced exam: cover lessons first, then vary
    // question type and difficulty instead of pure random selection.
    final selected = <Question>[];
    final used = <String>{};
    final shuffledLessons = [...lessonIds]..shuffle(_random);

    for (final lessonId in shuffledLessons) {
      if (selected.length >= count) break;
      final lessonPool = pool.where((q) => q.lessonId == lessonId).toList()
        ..shuffle(_random);
      if (lessonPool.isNotEmpty) {
        selected.add(lessonPool.first);
        used.add(lessonPool.first.id);
      }
    }

    final preferredTypes = [
      QuestionType.multipleChoice,
      QuestionType.trueFalse,
      QuestionType.fillBlank,
      QuestionType.shortAnswer,
      QuestionType.numeric,
      QuestionType.applied,
      QuestionType.reading,
    ].where(types.contains).toList();

    while (selected.length < count) {
      Question? pick;
      for (final type in preferredTypes) {
        final candidates = pool.where((q) => !used.contains(q.id) && q.type == type).toList()
          ..shuffle(_random);
        if (candidates.isNotEmpty) {
          pick = candidates.first;
          break;
        }
      }
      pick ??= (pool.where((q) => !used.contains(q.id)).toList()..shuffle(_random)).first;
      selected.add(pick);
      used.add(pick.id);
      if (preferredTypes.isNotEmpty) {
        preferredTypes.add(preferredTypes.removeAt(0));
      }
    }

    return GeneratedTest(
      id: 'test_${DateTime.now().microsecondsSinceEpoch}',
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
