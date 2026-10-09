import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikhtibarat_rabe/data/models.dart';
import 'package:ikhtibarat_rabe/services/pdf_service.dart';
import 'package:ikhtibarat_rabe/services/summary_pdf_service.dart';
import 'package:ikhtibarat_rabe/services/summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Student and parent exam PDFs are generated locally', () async {
    final exam = GeneratedTest(
      id: 'pdf-smoke-test',
      subjectId: 'science',
      subjectName: 'العلوم',
      lessonIds: const ['lesson-1'],
      lessonNames: const ['النظام البيئي'],
      questions: const [
        Question(
          id: 'q-1',
          subjectId: 'science',
          unitId: 'unit-1',
          lessonId: 'lesson-1',
          skillId: 'skill-1',
          type: QuestionType.multipleChoice,
          difficulty: Difficulty.easy,
          question: 'ما وظيفة المنتج في النظام البيئي؟',
          options: ['صناعة الغذاء', 'الافتراس', 'الهجرة'],
          correctAnswer: 'صناعة الغذاء',
          explanation: 'تنتج النباتات غذاءها بنفسها.',
          score: 1,
          isOfficial: false,
        ),
      ],
      createdAt: DateTime(2026, 10, 9),
    );

    final generator = PdfService();
    final student = await generator.buildTestPdf(
      exam,
      includeAnswers: false,
      includeExplanations: false,
    );
    final parent = await generator.buildTestPdf(
      exam,
      includeAnswers: true,
      includeExplanations: true,
    );

    expect(utf8.decode(student.take(4).toList()), '%PDF');
    expect(utf8.decode(parent.take(4).toList()), '%PDF');
    expect(student.length, greaterThan(1000));
    expect(parent.length, greaterThan(1000));
  });

  test('Revision summary PDF is generated locally', () async {
    final summary = StudySummary(
      subjectName: 'العلوم',
      createdAt: DateTime(2026, 10, 9),
      lessons: const [
        StudyLessonSummary(
          lessonId: 'lesson-1',
          lessonName: 'النظام البيئي',
          unitName: 'المخلوقات الحية',
          keyPoints: ['المنتجات تصنع غذاءها.'],
          questionsAndAnswers: ['من المنتج؟ الإجابة: النبات'],
          examples: ['النبات مثال على المنتج.'],
        ),
      ],
    );

    final bytes = await SummaryPdfService().build(summary);
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
  test('Compact questions share pages; large answer spaces stay intact', () {
    final tiny = List<Question>.generate(12, (i) => Question(
      id: 'tiny-$i',
      subjectId: 'science', unitId: 'unit-1', lessonId: 'lesson-1',
      skillId: 'skill-1', type: QuestionType.trueFalse,
      difficulty: Difficulty.easy, question: 'النبات يصنع غذاءه.',
      options: const [], correctAnswer: 'صح',
      explanation: '', score: 1, isOfficial: false,
    ));
    final service = PdfService();
    final pages = service.paginateQuestions(tiny,
      includeAnswers: false,
      includeExplanations: false,
    );
    expect(pages.length, lessThanOrEqualTo(2),
      reason: 'Twelve short true/false questions should not waste six pages');
    expect(pages.expand((e) => e).map((e) => e.id).toList(),
      tiny.map((e) => e.id).toList());
  });

}
