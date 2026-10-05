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

  @override
  void initState(){
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids=await AppDatabase.instance.loadStudiedLessonIds();
    if(!mounted)return;
    setState((){
      studied=ids;
      loading=false;
    });
  }

  Future<void> _set(String id,bool value) async {
    setState((){
      if(value){
        studied.add(id);
      }else{
        studied.remove(id);
      }
    });
    await AppDatabase.instance.setLessonStudied(id,value);
  }

  @override
  Widget build(BuildContext context){
    final active=widget.repository.subjects.where((s)=>widget.repository.questionCountForSubject(s.id)>0).toList();
    return Scaffold(
      appBar:AppBar(title:const Text('الدروس التي تمت دراستها')),
      body:loading
        ?const Center(child:CircularProgressIndicator())
        :ListView(
          padding:const EdgeInsets.fromLTRB(16,8,16,24),
          children:[
            Container(
              padding:const EdgeInsets.all(15),
              decoration:BoxDecoration(
                color:const Color(0xFFF0F7FF),
                borderRadius:BorderRadius.circular(16),
                border:Border.all(color:const Color(0xFFD7E9FF)),
              ),
              child:const Row(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Icon(Icons.info_outline_rounded,color:Color(0xFF2563EB)),
                  SizedBox(width:10),
                  Expanded(child:Text('ضع علامة على الدروس التي وصل إليها الطالب. الاختبارات ستلتزم بهذه الدروس فقط.',style:TextStyle(height:1.5))),
                ],
              ),
            ),
            const SizedBox(height:16),
            ...active.map((s){
              final subjectLessons=widget.repository.lessonsFor(s.id);
              final selectedCount=subjectLessons.where((l)=>studied.contains(l.id)).length;
              return Container(
                margin:const EdgeInsets.only(bottom:12),
                decoration:BoxDecoration(
                  color:Colors.white,
                  borderRadius:BorderRadius.circular(18),
                  border:Border.all(color:const Color(0xFFE5E7EB)),
                ),
                child:ExpansionTile(
                  tilePadding:const EdgeInsets.symmetric(horizontal:16,vertical:4),
                  leading:Container(
                    width:42,height:42,
                    decoration:BoxDecoration(color:const Color(0xFFF8FAFC),borderRadius:BorderRadius.circular(12)),
                    child:Icon(_iconFor(s.id),color:const Color(0xFF2563EB)),
                  ),
                  title:Text(s.name,style:const TextStyle(fontWeight:FontWeight.w900)),
                  subtitle:Text('$selectedCount من ${subjectLessons.length} درس محدد',style:const TextStyle(color:Color(0xFF64748B))),
                  children:widget.repository.unitsFor(s.id).map((u){
                    final lessons=widget.repository.lessonsForUnit(u.id);
                    return ExpansionTile(
                      tilePadding:const EdgeInsets.symmetric(horizontal:18),
                      title:Text(u.name,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:15)),
                      children:lessons.map((l){
                        final q=widget.repository.questionCountForLesson(l.id);
                        return CheckboxListTile(
                          controlAffinity:ListTileControlAffinity.leading,
                          contentPadding:const EdgeInsets.symmetric(horizontal:16),
                          value:studied.contains(l.id),
                          onChanged:q==0?null:(v)=>_set(l.id,v??false),
                          title:Text(l.name),
                          subtitle:Text(q>0?'$q سؤال تدريبي متاح':'بنك الأسئلة غير متاح',style:const TextStyle(fontSize:12,color:Color(0xFF64748B))),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
    );
  }

  IconData _iconFor(String id)=>switch(id){
    'math'=>Icons.calculate_outlined,
    'arabic'=>Icons.menu_book_outlined,
    'science'=>Icons.science_outlined,
    'social'=>Icons.public_outlined,
    'islamic'=>Icons.mosque_outlined,
    _=>Icons.school_outlined,
  };
}
