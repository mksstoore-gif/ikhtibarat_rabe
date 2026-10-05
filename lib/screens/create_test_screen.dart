import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
import '../services/test_generator.dart';
import 'solve_test_screen.dart';

class CreateTestScreen extends StatefulWidget{
  const CreateTestScreen({super.key});
  @override State<CreateTestScreen> createState()=>_State();
}
class _State extends State<CreateTestScreen>{
  final repo=CurriculumRepository.instance, generator=TestGenerator();
  final studentController=TextEditingController();
  final titleController=TextEditingController(text:'اختبار تدريبي');
  String? subjectId;
  Set<String> studied=<String>{};
  bool loadingStudied=true;
  final lessonIds=<String>{};
  final types=<QuestionType>{};
  final difficulties=Difficulty.values.toSet();
  int count=10;

  @override void initState(){super.initState();_loadStudied();}
  @override void dispose(){studentController.dispose();titleController.dispose();super.dispose();}
  Future<void> _loadStudied() async {
    final ids=await AppDatabase.instance.loadStudiedLessonIds();
    if(!mounted)return;
    setState((){studied=ids;loadingStudied=false;});
  }

  List<LessonInfo> get eligibleLessons=>subjectId==null?<LessonInfo>[]:repo.lessonsFor(subjectId!).where((l)=>studied.contains(l.id)&&repo.hasQuestionBank(l.id)).toList();
  Set<QuestionType> get availableTypes{
    final selected=lessonIds.isEmpty?eligibleLessons.map((e)=>e.id).toSet():lessonIds;
    return repo.questions.where((q)=>selected.contains(q.lessonId)).map((q)=>q.type).toSet();
  }

  @override Widget build(BuildContext context){
    final units=subjectId==null?<CurriculumUnit>[]:repo.unitsFor(subjectId!);
    final eligible=eligibleLessons;
    final availableQuestions=repo.questions.where((q)=>lessonIds.contains(q.lessonId)).length;
    final aTypes=availableTypes;
    return Scaffold(appBar:AppBar(title:const Text('إنشاء اختبار')),body:loadingStudied
      ?const Center(child:CircularProgressIndicator())
      :ListView(padding:const EdgeInsets.all(16),children:[
      TextField(controller:studentController,decoration:const InputDecoration(labelText:'اسم الطالب (اختياري)',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:titleController,decoration:const InputDecoration(labelText:'عنوان الاختبار',border:OutlineInputBorder())),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(
        value:subjectId,
        decoration:const InputDecoration(labelText:'المادة',border:OutlineInputBorder()),
        items:repo.subjects.map((s)=>DropdownMenuItem(value:s.id,child:Text(s.name))).toList(),
        onChanged:(v)=>setState((){
          subjectId=v;
          lessonIds.clear();
          types.clear();
          if(v!=null){
            lessonIds.addAll(repo.lessonsFor(v).where((l)=>studied.contains(l.id)&&repo.hasQuestionBank(l.id)).map((e)=>e.id));
            types.addAll(repo.questions.where((q)=>lessonIds.contains(q.lessonId)).map((q)=>q.type));
          }
        }),
      ),
      const SizedBox(height:14),
      if(subjectId!=null&&eligible.isEmpty)
        Card(color:Theme.of(context).colorScheme.secondaryContainer,child:const Padding(
          padding:EdgeInsets.all(12),
          child:Text('لا يوجد حاليًا درس يجمع بين شرطين: تم تحديده كدرس تمت دراسته، وله بنك أسئلة جاهز. من شاشة «المواد والدروس» حدد الدروس التي درسها الطالب.',textAlign:TextAlign.center),
        )),
      const SizedBox(height:10),
      const Text('الدروس',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      if(subjectId==null) const Text('اختر المادة أولًا.') else ...units.map((u)=>Card(
        margin:const EdgeInsets.only(top:8),
        child:ExpansionTile(
          initiallyExpanded:subjectId=='math',
          title:Text(u.name,style:const TextStyle(fontWeight:FontWeight.bold)),
          children:repo.lessonsForUnit(u.id).map((l){
            final qCount=repo.questionCountForLesson(l.id);
            final isStudied=studied.contains(l.id);
            final enabled=isStudied&&qCount>0;
            final subtitle=!isStudied?'لم يُحدد كدرس تمت دراسته':qCount>0?'تمت دراسته — $qCount سؤال تدريبي متاح':'تمت دراسته — بنك الأسئلة قيد الإعداد';
            return CheckboxListTile(
              value:lessonIds.contains(l.id),
              title:Text(l.name),
              subtitle:Text(subtitle),
              secondary:Icon(enabled?Icons.verified_outlined:isStudied?Icons.lock_outline:Icons.visibility_off_outlined),
              onChanged:!enabled?null:(v)=>setState((){
                v==true?lessonIds.add(l.id):lessonIds.remove(l.id);
                types.removeWhere((t)=>!availableTypes.contains(t));
                if(types.isEmpty)types.addAll(availableTypes);
              }),
            );
          }).toList(),
        ),
      )),
      const SizedBox(height:8),
      if(subjectId!=null)Text('المتاح للاختيار الحالي: $availableQuestions سؤال',style:Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height:12),
      const Text('نوع الأسئلة',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      Wrap(spacing:8,runSpacing:6,children:QuestionType.values.map((t){
        final enabled=aTypes.contains(t);
        return FilterChip(label:Text(t.label),selected:types.contains(t),onSelected:!enabled?null:(v)=>setState(()=>v?types.add(t):types.remove(t)));
      }).toList()),
      const SizedBox(height:18),
      const Text('الصعوبة',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      Wrap(spacing:8,children:Difficulty.values.map((d)=>FilterChip(label:Text(d.label),selected:difficulties.contains(d),onSelected:(v)=>setState(()=>v?difficulties.add(d):difficulties.remove(d)))).toList()),
      const SizedBox(height:18),
      DropdownButtonFormField<int>(value:count,decoration:const InputDecoration(labelText:'عدد الأسئلة',border:OutlineInputBorder()),items:const [5,10,15,20,25,30].map((n)=>DropdownMenuItem(value:n,child:Text('$n'))).toList(),onChanged:(v)=>setState(()=>count=v??10)),
      const SizedBox(height:24),
      FilledButton.icon(onPressed:eligible.isEmpty?null:_generate,icon:const Icon(Icons.auto_awesome),label:const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('إنشاء الاختبار'))),
    ]));
  }

  void _generate(){
    if(subjectId==null){_err('اختر المادة.');return;}
    if(lessonIds.isEmpty){_err('اختر درسًا واحدًا على الأقل تمت دراسته وله بنك أسئلة.');return;}
    if(types.isEmpty||difficulties.isEmpty){_err('اختر نوع سؤال وصعوبة على الأقل.');return;}
    try{
      final selectedLessons=repo.lessons.where((l)=>lessonIds.contains(l.id)).toList();
      final t=generator.generate(
        subjectId:subjectId!,subjectName:repo.subjectName(subjectId!),lessonIds:lessonIds.toList(),
        lessonNames:selectedLessons.map((e)=>e.name).toList(),types:types.toList(),difficulties:difficulties.toList(),count:count,bank:repo.questions,
        title:titleController.text,studentName:studentController.text,
      );
      Navigator.push(context,MaterialPageRoute(builder:(_)=>SolveTestScreen(test:t)));
    } on StateError catch(e){_err(e.message);}
  }
  void _err(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
}
