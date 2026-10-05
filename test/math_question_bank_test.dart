import 'package:flutter_test/flutter_test.dart';
import 'package:ikhtibarat_rabe/data/math_question_bank.dart';
import 'package:ikhtibarat_rabe/data/models.dart';

void main(){
  test('official math lesson receives a non-empty local practice bank',(){
    const lesson=LessonInfo(id:'math_c1_l1',unitId:'math_c1',subjectId:'math',name:'القيمة المنزلية ضمن مئات الألوف',isOfficial:true);
    final bank=MathQuestionBank.build(const [lesson]);
    expect(bank.length,36);
    expect(bank.map((q)=>q.id).toSet().length,36);
    expect(bank.every((q)=>q.lessonId==lesson.id),isTrue);
    expect(bank.every((q)=>!q.question.contains('DEMO')),isTrue);
  });

  test('unsupported planning lesson stays locked instead of receiving fake questions',(){
    const lesson=LessonInfo(id:'math_c1_l8',unitId:'math_c1',subjectId:'math',name:'اختيار الخطة المناسبة',isOfficial:true);
    final bank=MathQuestionBank.build(const [lesson]);
    expect(bank,isEmpty);
  });
}
