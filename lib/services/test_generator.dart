import 'dart:math';
import '../data/models.dart';
class TestGenerator {
  final Random _random;
  TestGenerator({Random? random}):_random=random??Random();
  GeneratedTest generate({required String subjectId,required String subjectName,required List<String> lessonIds,required List<QuestionType> types,required List<Difficulty> difficulties,required int count,required List<Question> bank,List<String> lessonNames=const [],String title='اختبار',String studentName='',String schoolName='',String className=''}){
    final c=bank.where((q)=>q.subjectId==subjectId&&lessonIds.contains(q.lessonId)&&types.contains(q.type)&&difficulties.contains(q.difficulty)).toList();
    if(c.length<count) throw StateError('بنك الأسئلة المطابق يحتوي ${c.length} سؤالًا فقط، بينما المطلوب $count.');
    c.shuffle(_random);
    return GeneratedTest(id:'test_${DateTime.now().microsecondsSinceEpoch}',subjectId:subjectId,subjectName:subjectName,lessonIds:lessonIds,lessonNames:lessonNames,questions:c.take(count).toList(),createdAt:DateTime.now(),title:title.trim().isEmpty?'اختبار':title.trim(),studentName:studentName.trim(),schoolName:schoolName.trim(),className:className.trim());
  }
}
