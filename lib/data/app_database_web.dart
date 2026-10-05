import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance=AppDatabase._();

  static const _studiedKey='studied_lessons_v1';
  static const _historyKey='test_history_v1';
  static const _skillsKey='skill_progress_v1';

  Future<void> get database async {
    await SharedPreferences.getInstance();
  }

  Future<Set<String>> loadStudiedLessonIds() async {
    final prefs=await SharedPreferences.getInstance();
    return (prefs.getStringList(_studiedKey)??const <String>[]).toSet();
  }

  Future<void> setLessonStudied(String lessonId,bool studied) async {
    final prefs=await SharedPreferences.getInstance();
    final ids=(prefs.getStringList(_studiedKey)??const <String>[]).toSet();
    if(studied){
      ids.add(lessonId);
    }else{
      ids.remove(lessonId);
    }
    final sorted=ids.toList()..sort();
    await prefs.setStringList(_studiedKey,sorted);
  }

  Future<void> saveResult(TestHistoryItem item) async {
    final prefs=await SharedPreferences.getInstance();
    final list=_decodeList(prefs.getString(_historyKey));
    list.add({
      'test_id':item.testId,
      'subject_name':item.subjectName,
      'lessons':item.lessons,
      'question_count':item.questionCount,
      'earned_score':item.earnedScore,
      'total_score':item.totalScore,
      'created_at':item.createdAt.toIso8601String(),
    });
    await prefs.setString(_historyKey,jsonEncode(list));
  }

  Future<List<TestHistoryItem>> loadHistory() async {
    final prefs=await SharedPreferences.getInstance();
    final list=_decodeList(prefs.getString(_historyKey));
    final result=<TestHistoryItem>[];
    for(var i=0;i<list.length;i++){
      final row=list[i];
      try{
        result.add(TestHistoryItem(
          dbId:i,
          testId:row['test_id'] as String,
          subjectName:row['subject_name'] as String,
          lessons:row['lessons'] as String,
          questionCount:(row['question_count'] as num).toInt(),
          earnedScore:(row['earned_score'] as num).toInt(),
          totalScore:(row['total_score'] as num).toInt(),
          createdAt:DateTime.parse(row['created_at'] as String),
        ));
      }catch(_){}
    }
    result.sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> updateSkill(String skillId,{required bool correct}) async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(_skillsKey);
    final Map<String,dynamic> root;
    if(raw==null||raw.isEmpty){
      root=<String,dynamic>{};
    }else{
      final decoded=jsonDecode(raw);
      root=decoded is Map<String,dynamic>?decoded:<String,dynamic>{};
    }

    final current=root[skillId] is Map
      ?Map<String,dynamic>.from(root[skillId] as Map)
      :<String,dynamic>{'correct_count':0,'wrong_count':0};

    current['correct_count']=((current['correct_count'] as num?)?.toInt()??0)+(correct?1:0);
    current['wrong_count']=((current['wrong_count'] as num?)?.toInt()??0)+(correct?0:1);
    current['updated_at']=DateTime.now().toIso8601String();
    root[skillId]=current;
    await prefs.setString(_skillsKey,jsonEncode(root));
  }

  Future<List<Map<String,Object?>>> loadSkillProgress() async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(_skillsKey);
    if(raw==null||raw.isEmpty)return <Map<String,Object?>>[];

    final decoded=jsonDecode(raw);
    if(decoded is! Map)return <Map<String,Object?>>[];

    final rows=<Map<String,Object?>>[];
    decoded.forEach((key,value){
      if(value is Map){
        final map=Map<String,dynamic>.from(value);
        rows.add({
          'skill_id':key.toString(),
          'correct_count':(map['correct_count'] as num?)?.toInt()??0,
          'wrong_count':(map['wrong_count'] as num?)?.toInt()??0,
          'updated_at':map['updated_at']?.toString()??'',
        });
      }
    });
    rows.sort((a,b)=>(b['wrong_count'] as int).compareTo(a['wrong_count'] as int));
    return rows;
  }

  List<Map<String,dynamic>> _decodeList(String? raw){
    if(raw==null||raw.isEmpty)return <Map<String,dynamic>>[];
    try{
      final decoded=jsonDecode(raw);
      if(decoded is List){
        return decoded.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
      }
    }catch(_){}
    return <Map<String,dynamic>>[];
  }
}
