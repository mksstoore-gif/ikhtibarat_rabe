import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';

class SubjectsScreen extends StatefulWidget{
  final CurriculumRepository repository;
  const SubjectsScreen({super.key,required this.repository});
  @override State<SubjectsScreen> createState()=>_SubjectsState();
}

class _SubjectsState extends State<SubjectsScreen>{
  Set<String> studied=<String>{};
  bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final ids=await AppDatabase.instance.loadStudiedLessonIds();
    if(!mounted)return;
    setState((){studied=ids;loading=false;});
  }
  Future<void> _set(String id,bool value) async {
    setState(()=>value?studied.add(id):studied.remove(id));
    await AppDatabase.instance.setLessonStudied(id,value);
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('المواد والدروس')),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(
      padding:const EdgeInsets.all(12),
      children:[
        Card(color:Theme.of(context).colorScheme.secondaryContainer,child:const Padding(
          padding:EdgeInsets.all(12),
          child:Text('حدد الدروس التي درسها الطالب. لن يسمح التطبيق بإدخال درس غير محدد ضمن الاختبار.',textAlign:TextAlign.center),
        )),
        const SizedBox(height:8),
        ...widget.repository.subjects.map((s)=>Card(
          child:ExpansionTile(
            title:Text(s.name,style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text('${widget.repository.unitsFor(s.id).length} وحدات/فصول — ${widget.repository.lessonsFor(s.id).length} درسًا'),
            children:widget.repository.unitsFor(s.id).map((u)=>ExpansionTile(
              title:Text(u.name),
              children:widget.repository.lessonsForUnit(u.id).map((l){
                final q=widget.repository.questionCountForLesson(l.id);
                return CheckboxListTile(
                  value:studied.contains(l.id),
                  onChanged:(v)=>_set(l.id,v??false),
                  title:Text(l.name),
                  subtitle:Text(q>0?'عنوان موثق — بنك أسئلة متاح ($q)':'عنوان موثق — بنك الأسئلة قيد الإعداد'),
                  secondary:Icon(q>0?Icons.verified_outlined:Icons.menu_book_outlined),
                );
              }).toList(),
            )).toList(),
          ),
        )),
      ],
    ),
  );
}
