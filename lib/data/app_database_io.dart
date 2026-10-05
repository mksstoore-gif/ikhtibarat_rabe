import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance=AppDatabase._();
  Database? _db;
  Future<Database> get database async {
    if(_db!=null) return _db!;
    final p=join(await getDatabasesPath(),'ikhtibarat_rabe.db');
    _db=await openDatabase(p,version:2,onCreate:(db,v) async {
      await db.execute('CREATE TABLE subjects(id TEXT PRIMARY KEY,name TEXT NOT NULL)');
      await db.execute('CREATE TABLE units(id TEXT PRIMARY KEY,subject_id TEXT NOT NULL,name TEXT NOT NULL)');
      await db.execute('CREATE TABLE lessons(id TEXT PRIMARY KEY,unit_id TEXT NOT NULL,subject_id TEXT NOT NULL,name TEXT NOT NULL,is_official INTEGER NOT NULL DEFAULT 0)');
      await db.execute('CREATE TABLE skills(id TEXT PRIMARY KEY,lesson_id TEXT NOT NULL,name TEXT NOT NULL)');
      await db.execute('CREATE TABLE questions(id TEXT PRIMARY KEY,subject_id TEXT NOT NULL,unit_id TEXT NOT NULL,lesson_id TEXT NOT NULL,skill_id TEXT NOT NULL,type TEXT NOT NULL,difficulty TEXT NOT NULL,question TEXT NOT NULL,options_json TEXT,correct_answer TEXT NOT NULL,explanation TEXT,score INTEGER NOT NULL DEFAULT 1,is_official INTEGER NOT NULL DEFAULT 0)');
      await db.execute('CREATE TABLE tests(id TEXT PRIMARY KEY,subject_name TEXT NOT NULL,lessons TEXT NOT NULL,question_count INTEGER NOT NULL,created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE test_questions(id INTEGER PRIMARY KEY AUTOINCREMENT,test_id TEXT NOT NULL,question_id TEXT NOT NULL,question_order INTEGER NOT NULL)');
      await db.execute('CREATE TABLE test_results(id INTEGER PRIMARY KEY AUTOINCREMENT,test_id TEXT NOT NULL,subject_name TEXT NOT NULL,lessons TEXT NOT NULL,question_count INTEGER NOT NULL,earned_score INTEGER NOT NULL,total_score INTEGER NOT NULL,created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE skill_progress(skill_id TEXT PRIMARY KEY,correct_count INTEGER NOT NULL DEFAULT 0,wrong_count INTEGER NOT NULL DEFAULT 0,updated_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE app_settings(key TEXT PRIMARY KEY,value TEXT)');
      await db.execute('CREATE TABLE studied_lessons(lesson_id TEXT PRIMARY KEY,studied_at TEXT NOT NULL)');
    },onUpgrade:(db,oldVersion,newVersion) async {
      if(oldVersion<2){
        await db.execute('CREATE TABLE IF NOT EXISTS studied_lessons(lesson_id TEXT PRIMARY KEY,studied_at TEXT NOT NULL)');
      }
    });
    return _db!;
  }

  Future<Set<String>> loadStudiedLessonIds() async {
    final db=await database;
    final rows=await db.query('studied_lessons');
    return rows.map((r)=>r['lesson_id'] as String).toSet();
  }
  Future<void> setLessonStudied(String lessonId,bool studied) async {
    final db=await database;
    if(studied){
      await db.insert('studied_lessons',{'lesson_id':lessonId,'studied_at':DateTime.now().toIso8601String()},conflictAlgorithm:ConflictAlgorithm.replace);
    }else{
      await db.delete('studied_lessons',where:'lesson_id=?',whereArgs:[lessonId]);
    }
  }

  Future<void> saveResult(TestHistoryItem i) async {
    final db=await database;
    await db.insert('test_results',{'test_id':i.testId,'subject_name':i.subjectName,'lessons':i.lessons,'question_count':i.questionCount,'earned_score':i.earnedScore,'total_score':i.totalScore,'created_at':i.createdAt.toIso8601String()});
  }
  Future<List<TestHistoryItem>> loadHistory() async {
    final db=await database;
    final rows=await db.query('test_results',orderBy:'created_at DESC');
    return rows.map((r)=>TestHistoryItem(dbId:r['id'] as int?,testId:r['test_id'] as String,subjectName:r['subject_name'] as String,lessons:r['lessons'] as String,questionCount:r['question_count'] as int,earnedScore:r['earned_score'] as int,totalScore:r['total_score'] as int,createdAt:DateTime.parse(r['created_at'] as String))).toList();
  }
  Future<void> updateSkill(String skillId,{required bool correct}) async {
    final db=await database;
    final rows=await db.query('skill_progress',where:'skill_id=?',whereArgs:[skillId]);
    if(rows.isEmpty){
      await db.insert('skill_progress',{'skill_id':skillId,'correct_count':correct?1:0,'wrong_count':correct?0:1,'updated_at':DateTime.now().toIso8601String()});
    } else {
      final r=rows.first;
      await db.update('skill_progress',{'correct_count':(r['correct_count'] as int)+(correct?1:0),'wrong_count':(r['wrong_count'] as int)+(correct?0:1),'updated_at':DateTime.now().toIso8601String()},where:'skill_id=?',whereArgs:[skillId]);
    }
  }
  Future<List<Map<String,Object?>>> loadSkillProgress() async {
    final db=await database;
    return db.query('skill_progress',orderBy:'wrong_count DESC');
  }
}
