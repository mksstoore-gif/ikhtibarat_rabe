import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikhtibarat_rabe/data/models.dart';
import 'package:ikhtibarat_rabe/services/test_generator.dart';

void main(){
  test('generator never returns duplicate questions',(){
    final bank=List.generate(10,(i)=>Question(id:'q$i',subjectId:'math',unitId:'u1',lessonId:'l1',skillId:'s1',type:QuestionType.multipleChoice,difficulty:Difficulty.easy,question:'q$i',options:const ['أ','ب'],correctAnswer:'أ',explanation:'',score:1,isOfficial:false));
    final t=TestGenerator(random:Random(1)).generate(subjectId:'math',subjectName:'الرياضيات',lessonIds:const ['l1'],types:const [QuestionType.multipleChoice],difficulties:const [Difficulty.easy],count:5,bank:bank);
    expect(t.questions.length,5);
    expect(t.questions.map((e)=>e.id).toSet().length,5);
  });
  test('Duplicate stems do not appear in generated exams', () {
    final bank = [
      for (var i = 0; i < 9; i++)
        Question(
          id: 'd' + i.toString(),
          subjectId: 'math', unitId: 'u', lessonId: i.isEven ? 'l1' : 'l2',
          skillId: 's', type: i.isEven
              ? QuestionType.multipleChoice : QuestionType.shortAnswer,
          difficulty: Difficulty.easy,
          question: i < 5 ? 'ما المقصود بالتقدير؟'
              : 'ما الرقم في السؤال ' + i.toString() + '؟',
          options: const ['أ', 'ب'],
          correctAnswer: 'أ', explanation: '', score: 1, isOfficial: false,
        ),
    ];
    final unique = TestGenerator.eligibleQuestions(
      subjectId: 'math', lessonIds: ['l1', 'l2'],
      types: [QuestionType.multipleChoice, QuestionType.shortAnswer],
      difficulties: [Difficulty.easy], bank: bank,
    );
    expect(unique.length, 5);
    final test = TestGenerator(random: Random(3)).generate(
      subjectId: 'math', subjectName: 'رياضيات', lessonIds: ['l1', 'l2'],
      types: [QuestionType.multipleChoice, QuestionType.shortAnswer],
      difficulties: [Difficulty.easy], count: 5, bank: bank,
    );
    expect(test.questions.map(TestGenerator.questionKey).toSet().length, 5);
    expect(test.questions.map((q) => q.lessonId).toSet(), {'l1', 'l2'});
  });

}
