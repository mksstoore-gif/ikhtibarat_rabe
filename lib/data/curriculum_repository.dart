import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';
import 'math_question_bank.dart';
import 'training_question_bank.dart';

class CurriculumRepository {
  CurriculumRepository._();
  static final CurriculumRepository instance=CurriculumRepository._();
  final subjects=<SubjectInfo>[];
  final units=<CurriculumUnit>[];
  final lessons=<LessonInfo>[];
  final questions=<Question>[];
  bool _loaded=false;

  Future<void> load() async {
    if(_loaded) return;
    final raw=await rootBundle.loadString('assets/data/curriculum.json');
    final root=jsonDecode(raw) as Map<String,dynamic>;
    final subjectRows=(root['subjects'] as List).cast<Map<String,dynamic>>();
    for(final s in subjectRows){
      final subject=SubjectInfo(id:s['id'] as String,name:s['name'] as String,source:(s['source']??'') as String);
      subjects.add(subject);
      for(final u in (s['units'] as List).cast<Map<String,dynamic>>()){
        final unit=CurriculumUnit(id:u['id'] as String,subjectId:subject.id,name:u['name'] as String);
        units.add(unit);
        for(final l in (u['lessons'] as List).cast<Map<String,dynamic>>()){
          lessons.add(LessonInfo(id:l['id'] as String,unitId:unit.id,subjectId:subject.id,name:l['name'] as String,isOfficial:true));
        }
      }
    }
    questions
      ..addAll(MathQuestionBank.build(lessons))
      ..addAll(TrainingQuestionBank.build(lessons));
    _loaded=true;
  }

  List<CurriculumUnit> unitsFor(String subjectId)=>units.where((x)=>x.subjectId==subjectId).toList();
  List<LessonInfo> lessonsFor(String subjectId)=>lessons.where((x)=>x.subjectId==subjectId).toList();
  List<LessonInfo> lessonsForUnit(String unitId)=>lessons.where((x)=>x.unitId==unitId).toList();
  String subjectName(String id)=>subjects.firstWhere((x)=>x.id==id).name;
  String unitName(String id)=>units.firstWhere((x)=>x.id==id).name;
  String lessonName(String id)=>lessons.firstWhere((x)=>x.id==id).name;
  int questionCountForLesson(String lessonId)=>questions.where((q)=>q.lessonId==lessonId).length;
  bool hasQuestionBank(String lessonId)=>questionCountForLesson(lessonId)>0;
  int questionCountForSubject(String subjectId)=>questions.where((q)=>q.subjectId==subjectId).length;
}