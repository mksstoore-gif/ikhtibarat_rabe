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
}
