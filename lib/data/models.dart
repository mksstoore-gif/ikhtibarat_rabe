/// Treat Arabic-Indic and Western digits equally in numeric answers.
String normalizeStudentAnswer(String value) {
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  const easternDigits = '۰۱۲۳۴۵۶۷۸۹';
  final result = StringBuffer();
  for (final rune in value.runes) {
    final letter = String.fromCharCode(rune);
    final arabic = arabicDigits.indexOf(letter);
    final eastern = easternDigits.indexOf(letter);
    if (arabic >= 0) {
      result.write(arabic);
    } else if (eastern >= 0) {
      result.write(eastern);
    } else if (letter == '٫') {
      result.write('.');
    } else if (letter != '٬' && letter != ',') {
      result.write(letter);
    }
  }
  return result.toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}

enum QuestionType { multipleChoice, trueFalse, fillBlank, matching, ordering, shortAnswer, numeric, reading, applied, imageChoice }
extension QuestionTypeLabel on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.multipleChoice: return 'اختيار من متعدد';
      case QuestionType.trueFalse: return 'صح أو خطأ';
      case QuestionType.fillBlank: return 'أكمل الفراغ';
      case QuestionType.matching: return 'توصيل';
      case QuestionType.ordering: return 'ترتيب';
      case QuestionType.shortAnswer: return 'إجابة قصيرة';
      case QuestionType.numeric: return 'مسألة حسابية';
      case QuestionType.reading: return 'فهم مقروء';
      case QuestionType.applied: return 'تطبيق وحل مشكلات';
      case QuestionType.imageChoice: return 'اختيار من صورة/شكل';
    }
  }
}
enum Difficulty { easy, medium, hard }
extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
    Difficulty.easy => 'سهل',
    Difficulty.medium => 'متوسط',
    Difficulty.hard => 'صعب',
  };
}
class SubjectInfo { final String id,name,source; const SubjectInfo({required this.id,required this.name,this.source=''}); }
class CurriculumUnit { final String id,subjectId,name; const CurriculumUnit({required this.id,required this.subjectId,required this.name}); }
class LessonInfo {
  final String id,unitId,subjectId,name; final bool isOfficial;
  const LessonInfo({required this.id,required this.unitId,required this.subjectId,required this.name,required this.isOfficial});
}
class Question {
  final String id,subjectId,unitId,lessonId,skillId,question,correctAnswer,explanation;
  final QuestionType type; final Difficulty difficulty; final List<String> options; final int score; final bool isOfficial;
  const Question({required this.id,required this.subjectId,required this.unitId,required this.lessonId,required this.skillId,required this.type,required this.difficulty,required this.question,required this.options,required this.correctAnswer,required this.explanation,required this.score,required this.isOfficial});
}
class GeneratedTest {
  final String id,subjectId,subjectName,title,studentName,schoolName,className;
  final List<String> lessonIds,lessonNames;
  final List<Question> questions;
  final DateTime createdAt;
  const GeneratedTest({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.lessonIds,
    required this.questions,
    required this.createdAt,
    this.lessonNames=const [],
    this.title='اختبار',
    this.studentName='',
    this.schoolName='',
    this.className='',
  });
  int get totalScore => questions.fold(0,(s,q)=>s+q.score);
}

class TestHistoryItem {
  final int? dbId; final String testId,subjectName,lessons; final int questionCount,earnedScore,totalScore; final DateTime createdAt;
  const TestHistoryItem({this.dbId,required this.testId,required this.subjectName,required this.lessons,required this.questionCount,required this.earnedScore,required this.totalScore,required this.createdAt});
  double get percentage => totalScore==0?0:earnedScore/totalScore*100;
}
