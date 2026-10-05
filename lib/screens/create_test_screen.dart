import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
import '../services/test_generator.dart';
import 'solve_test_screen.dart';
import 'subjects_screen.dart';

class CreateTestScreen extends StatefulWidget{
  final String? initialSubjectId;
  const CreateTestScreen({super.key,this.initialSubjectId});
  @override State<CreateTestScreen> createState()=>_CreateTestState();
}

class _CreateTestState extends State<CreateTestScreen>{
  final repo=CurriculumRepository.instance;
  final generator=TestGenerator();
  final studentController=TextEditingController();
  final titleController=TextEditingController(text:'اختبار تدريبي');

  String? subjectId;
  Set<String> studied=<String>{};
  final lessonIds=<String>{};
  String questionMode='mixed';
  String difficultyMode='mixed';
  int count=10;
  bool loading=true;

  @override
  void initState(){
    super.initState();
    subjectId=widget.initialSubjectId;
    _loadStudied();
  }

  @override
  void dispose(){
    studentController.dispose();
    titleController.dispose();
    super.dispose();
  }

  Future<void> _loadStudied() async {
    final ids=await AppDatabase.instance.loadStudiedLessonIds();
    if(!mounted)return;
    setState((){
      studied=ids;
      loading=false;
      if(subjectId!=null){
        _selectAllEligible();
      }
    });
  }

  List<SubjectInfo> get activeSubjects=>repo.subjects.where((s)=>repo.questionCountForSubject(s.id)>0).toList();

  List<LessonInfo> get eligibleLessons{
    if(subjectId==null)return <LessonInfo>[];
    return repo.lessonsFor(subjectId!).where((l)=>studied.contains(l.id)&&repo.hasQuestionBank(l.id)).toList();
  }

  Set<QuestionType> get availableTypes{
    final ids=lessonIds.isEmpty?eligibleLessons.map((e)=>e.id).toSet():lessonIds;
    return repo.questions.where((q)=>ids.contains(q.lessonId)).map((q)=>q.type).toSet();
  }

  Set<QuestionType> get selectedTypes{
    final available=availableTypes;
    if(questionMode=='tf')return {QuestionType.trueFalse}.intersection(available);
    if(questionMode=='mcq')return {QuestionType.multipleChoice}.intersection(available);
    if(questionMode=='written'){
      const written={
        QuestionType.fillBlank,
        QuestionType.shortAnswer,
        QuestionType.numeric,
        QuestionType.reading,
        QuestionType.applied,
        QuestionType.ordering,
        QuestionType.matching,
        QuestionType.imageChoice,
      };
      return written.intersection(available);
    }
    return available;
  }

  Set<Difficulty> get selectedDifficulties{
    if(difficultyMode=='easy')return {Difficulty.easy};
    if(difficultyMode=='medium')return {Difficulty.medium};
    if(difficultyMode=='hard')return {Difficulty.hard};
    return Difficulty.values.toSet();
  }

  int get matchingPool{
    if(subjectId==null||lessonIds.isEmpty||selectedTypes.isEmpty)return 0;
    return repo.questions.where((q)=>
      q.subjectId==subjectId &&
      lessonIds.contains(q.lessonId) &&
      selectedTypes.contains(q.type) &&
      selectedDifficulties.contains(q.difficulty)
    ).length;
  }

  void _selectSubject(String id){
    setState((){
      subjectId=id;
      lessonIds.clear();
      _selectAllEligible();
      questionMode='mixed';
      difficultyMode='mixed';
      count=10;
      _fixCount();
    });
  }

  void _selectAllEligible(){
    lessonIds
      ..clear()
      ..addAll(eligibleLessons.map((e)=>e.id));
  }

  void _fixCount(){
    final pool=matchingPool;
    const choices=[5,10,15,20,25,30];
    final allowed=choices.where((n)=>n<=pool).toList();
    if(allowed.isEmpty){
      count=pool;
    }else if(!allowed.contains(count)){
      count=allowed.last;
    }
  }

  @override
  Widget build(BuildContext context){
    if(loading){
      return const Scaffold(body:Center(child:CircularProgressIndicator()));
    }

    final eligible=eligibleLessons;
    final units=subjectId==null?<CurriculumUnit>[]:repo.unitsFor(subjectId!);
    final pool=matchingPool;
    final countChoices=[5,10,15,20,25,30].where((n)=>n<=pool).toList();

    return Scaffold(
      appBar:AppBar(title:const Text('اختبار جديد')),
      body:ListView(
        padding:const EdgeInsets.fromLTRB(16,8,16,28),
        children:[
          _sectionTitle('1','اختر المادة'),
          const SizedBox(height:10),
          Wrap(
            spacing:8,
            runSpacing:8,
            children:activeSubjects.map((s){
              final selected=subjectId==s.id;
              return ChoiceChip(
                selected:selected,
                label:Text(s.name),
                avatar:Icon(_iconFor(s.id),size:19),
                showCheckmark:false,
                onSelected:(_)=>_selectSubject(s.id),
              );
            }).toList(),
          ),
          if(subjectId!=null)...[
            const SizedBox(height:24),
            _sectionTitle('2','اختر الدروس'),
            const SizedBox(height:6),
            const Text('يظهر هنا فقط ما حددته مسبقًا بأنه تمت دراسته.',style:TextStyle(color:Color(0xFF64748B))),
            const SizedBox(height:10),
            if(eligible.isEmpty)
              _EmptyLessons(
                onTap:() async {
                  await Navigator.push(context,MaterialPageRoute(builder:(_)=>SubjectsScreen(repository:repo)));
                  await _loadStudied();
                },
              )
            else ...[
              Row(
                children:[
                  Text('${lessonIds.length} درس محدد',style:const TextStyle(fontWeight:FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed:()=>setState((){
                      if(lessonIds.length==eligible.length){
                        lessonIds.clear();
                      }else{
                        _selectAllEligible();
                      }
                      _fixCount();
                    }),
                    child:Text(lessonIds.length==eligible.length?'إلغاء الكل':'تحديد الكل'),
                  ),
                ],
              ),
              ...units.map((u){
                final lessons=repo.lessonsForUnit(u.id).where((l)=>eligible.any((e)=>e.id==l.id)).toList();
                if(lessons.isEmpty)return const SizedBox.shrink();
                return Container(
                  margin:const EdgeInsets.only(bottom:10),
                  decoration:BoxDecoration(
                    color:Colors.white,
                    borderRadius:BorderRadius.circular(16),
                    border:Border.all(color:const Color(0xFFE5E7EB)),
                  ),
                  child:ExpansionTile(
                    tilePadding:const EdgeInsets.symmetric(horizontal:14),
                    childrenPadding:const EdgeInsets.fromLTRB(8,0,8,8),
                    title:Text(u.name,style:const TextStyle(fontWeight:FontWeight.w800)),
                    initiallyExpanded:true,
                    children:lessons.map((l)=>CheckboxListTile(
                      dense:true,
                      contentPadding:const EdgeInsets.symmetric(horizontal:8),
                      value:lessonIds.contains(l.id),
                      title:Text(l.name),
                      subtitle:Text('${repo.questionCountForLesson(l.id)} سؤال متاح',style:const TextStyle(fontSize:12,color:Color(0xFF64748B))),
                      controlAffinity:ListTileControlAffinity.leading,
                      onChanged:(v)=>setState((){
                        if(v==true){
                          lessonIds.add(l.id);
                        }else{
                          lessonIds.remove(l.id);
                        }
                        _fixCount();
                      }),
                    )).toList(),
                  ),
                );
              }),
            ],
            const SizedBox(height:18),
            _sectionTitle('3','شكل الاختبار'),
            const SizedBox(height:10),
            _choiceRow(
              [
                ('mixed','متنوع'),
                ('tf','صح / خطأ'),
                ('mcq','اختيارات'),
                ('written','كتابي'),
              ],
              questionMode,
              (v)=>setState((){
                questionMode=v;
                _fixCount();
              }),
            ),
            const SizedBox(height:20),
            _sectionTitle('4','المستوى'),
            const SizedBox(height:10),
            _choiceRow(
              [
                ('mixed','متنوع'),
                ('easy','سهل'),
                ('medium','متوسط'),
                ('hard','صعب'),
              ],
              difficultyMode,
              (v)=>setState((){
                difficultyMode=v;
                _fixCount();
              }),
            ),
            const SizedBox(height:20),
            _sectionTitle('5','عدد الأسئلة'),
            const SizedBox(height:10),
            if(pool==0)
              const Text('غيّر نوع الاختبار أو اختر درسًا آخر.',style:TextStyle(color:Color(0xFFB91C1C),fontWeight:FontWeight.w700))
            else
              Wrap(
                spacing:8,
                runSpacing:8,
                children:[
                  ...countChoices.map((n)=>ChoiceChip(
                    selected:count==n,
                    label:Text('$n أسئلة'),
                    showCheckmark:false,
                    onSelected:(_)=>setState(()=>count=n),
                  )),
                  if(countChoices.isEmpty)
                    ChoiceChip(selected:true,label:Text('$pool أسئلة'),onSelected:(_)=>setState(()=>count=pool)),
                ],
              ),
            const SizedBox(height:8),
            Text('المتاح بهذه الإعدادات: $pool سؤال',style:const TextStyle(color:Color(0xFF64748B),fontSize:13)),
            const SizedBox(height:22),
            _sectionTitle('6','بيانات الورقة'),
            const SizedBox(height:10),
            TextField(
              controller:studentController,
              decoration:const InputDecoration(labelText:'اسم الطالب (اختياري)',prefixIcon:Icon(Icons.person_outline)),
            ),
            const SizedBox(height:10),
            TextField(
              controller:titleController,
              decoration:const InputDecoration(labelText:'عنوان الاختبار',prefixIcon:Icon(Icons.edit_note_rounded)),
            ),
            const SizedBox(height:22),
            FilledButton.icon(
              onPressed:pool>0&&count>0&&lessonIds.isNotEmpty?_generate:null,
              icon:const Icon(Icons.play_arrow_rounded),
              label:const Text('ابدأ الاختبار',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String number,String title)=>Row(
    children:[
      Container(
        width:30,height:30,
        alignment:Alignment.center,
        decoration:BoxDecoration(color:const Color(0xFF2563EB),borderRadius:BorderRadius.circular(10)),
        child:Text(number,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
      ),
      const SizedBox(width:9),
      Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
    ],
  );

  Widget _choiceRow(List<(String,String)> choices,String selected,ValueChanged<String> onChanged)=>Wrap(
    spacing:8,
    runSpacing:8,
    children:choices.map((c)=>ChoiceChip(
      selected:selected==c.$1,
      label:Text(c.$2),
      showCheckmark:false,
      onSelected:(_)=>onChanged(c.$1),
    )).toList(),
  );

  IconData _iconFor(String id)=>switch(id){
    'math'=>Icons.calculate_outlined,
    'arabic'=>Icons.menu_book_outlined,
    'science'=>Icons.science_outlined,
    'social'=>Icons.public_outlined,
    'islamic'=>Icons.mosque_outlined,
    _=>Icons.school_outlined,
  };

  void _generate(){
    if(subjectId==null||lessonIds.isEmpty||count<=0){
      _error('اختر المادة والدروس أولًا.');
      return;
    }
    try{
      final selectedLessons=repo.lessons.where((l)=>lessonIds.contains(l.id)).toList();
      final test=generator.generate(
        subjectId:subjectId!,
        subjectName:repo.subjectName(subjectId!),
        lessonIds:lessonIds.toList(),
        lessonNames:selectedLessons.map((e)=>e.name).toList(),
        types:selectedTypes.toList(),
        difficulties:selectedDifficulties.toList(),
        count:count,
        bank:repo.questions,
        title:titleController.text,
        studentName:studentController.text,
      );
      Navigator.push(context,MaterialPageRoute(builder:(_)=>SolveTestScreen(test:test)));
    }on StateError catch(e){
      _error(e.message);
    }
  }

  void _error(String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));
}

class _EmptyLessons extends StatelessWidget{
  final VoidCallback onTap;
  const _EmptyLessons({required this.onTap});

  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(18),
    decoration:BoxDecoration(
      color:const Color(0xFFFFFBEB),
      borderRadius:BorderRadius.circular(16),
      border:Border.all(color:const Color(0xFFFDE68A)),
    ),
    child:Column(
      children:[
        const Icon(Icons.checklist_rounded,size:36,color:Color(0xFFD97706)),
        const SizedBox(height:8),
        const Text('حدد أولًا الدروس التي درسها الطالب.',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        OutlinedButton(onPressed:onTap,child:const Text('اختيار الدروس المدروسة')),
      ],
    ),
  );
}
