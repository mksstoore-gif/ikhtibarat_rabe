import 'package:flutter/material.dart';
import '../data/curriculum_repository.dart';
import 'create_test_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'subjects_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _subjectIcons=<String,IconData>{
    'math':Icons.calculate_outlined,
    'arabic':Icons.menu_book_outlined,
    'science':Icons.science_outlined,
    'social':Icons.public_outlined,
    'islamic':Icons.mosque_outlined,
  };

  @override
  Widget build(BuildContext context){
    final repo=CurriculumRepository.instance;
    final activeSubjects=repo.subjects.where((s)=>repo.questionCountForSubject(s.id)>0).toList();

    return Scaffold(
      appBar:AppBar(
        title:const Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text('اختبارات الصف الرابع',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
            Text('تدريب بسيط وواضح',style:TextStyle(fontSize:13,fontWeight:FontWeight.w400,color:Color(0xFF6B7280))),
          ],
        ),
        actions:[
          IconButton(
            tooltip:'الإعدادات',
            onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen())),
            icon:const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width:6),
        ],
      ),
      body:ListView(
        padding:const EdgeInsets.fromLTRB(16,12,16,28),
        children:[
          Container(
            padding:const EdgeInsets.all(18),
            decoration:BoxDecoration(
              color:const Color(0xFFF0F7FF),
              borderRadius:BorderRadius.circular(22),
              border:Border.all(color:const Color(0xFFD7E9FF)),
            ),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.stretch,
              children:[
                const Text('جاهز لاختبار اليوم؟',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:Color(0xFF0F172A))),
                const SizedBox(height:6),
                const Text('اختر المادة والدروس، والباقي يرتبه التطبيق لك.',style:TextStyle(fontSize:15,color:Color(0xFF475569))),
                const SizedBox(height:18),
                FilledButton.icon(
                  onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CreateTestScreen())),
                  icon:const Icon(Icons.play_arrow_rounded),
                  label:const Text('ابدأ اختبارًا جديدًا',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height:24),
          const Text('المواد المتاحة',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          Wrap(
            spacing:10,
            runSpacing:10,
            children:activeSubjects.map((s){
              final count=repo.questionCountForSubject(s.id);
              return _SubjectCard(
                icon:_subjectIcons[s.id]??Icons.school_outlined,
                name:s.name,
                count:count,
                onTap:()=>Navigator.push(
                  context,
                  MaterialPageRoute(builder:(_)=>CreateTestScreen(initialSubjectId:s.id)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height:24),
          const Text('إدارة ومتابعة',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          _MenuTile(
            icon:Icons.checklist_rounded,
            title:'الدروس التي تمت دراستها',
            subtitle:'حدد الدروس مرة واحدة، ولن يظهر غيرها في الاختبارات.',
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SubjectsScreen(repository:repo))),
          ),
          _MenuTile(
            icon:Icons.history_rounded,
            title:'النتائج السابقة',
            subtitle:'راجع درجات الاختبارات السابقة.',
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen())),
          ),
          _MenuTile(
            icon:Icons.insights_rounded,
            title:'مستوى الطالب',
            subtitle:'تعرف على المهارات التي تحتاج إلى مراجعة.',
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProgressScreen())),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget{
  final IconData icon;
  final String name;
  final int count;
  final VoidCallback onTap;
  const _SubjectCard({required this.icon,required this.name,required this.count,required this.onTap});

  @override
  Widget build(BuildContext context){
    final width=(MediaQuery.sizeOf(context).width-42)/2;
    return SizedBox(
      width:width,
      child:InkWell(
        borderRadius:BorderRadius.circular(18),
        onTap:onTap,
        child:Container(
          padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(
            color:Colors.white,
            borderRadius:BorderRadius.circular(18),
            border:Border.all(color:const Color(0xFFE5E7EB)),
          ),
          child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Container(
                width:42,height:42,
                decoration:BoxDecoration(color:const Color(0xFFF1F5F9),borderRadius:BorderRadius.circular(12)),
                child:Icon(icon,color:const Color(0xFF2563EB)),
              ),
              const SizedBox(height:13),
              Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),
              const SizedBox(height:4),
              Text('$count سؤال تدريبي',style:const TextStyle(color:Color(0xFF64748B),fontSize:12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget{
  final IconData icon;
  final String title,subtitle;
  final VoidCallback onTap;
  const _MenuTile({required this.icon,required this.title,required this.subtitle,required this.onTap});

  @override
  Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.only(bottom:10),
    child:InkWell(
      borderRadius:BorderRadius.circular(16),
      onTap:onTap,
      child:Container(
        padding:const EdgeInsets.all(14),
        decoration:BoxDecoration(
          color:Colors.white,
          borderRadius:BorderRadius.circular(16),
          border:Border.all(color:const Color(0xFFE5E7EB)),
        ),
        child:Row(
          children:[
            Container(
              width:44,height:44,
              decoration:BoxDecoration(color:const Color(0xFFF8FAFC),borderRadius:BorderRadius.circular(12)),
              child:Icon(icon,color:const Color(0xFF334155)),
            ),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),
              const SizedBox(height:3),
              Text(subtitle,style:const TextStyle(fontSize:13,color:Color(0xFF64748B))),
            ])),
            const Icon(Icons.chevron_left_rounded,color:Color(0xFF94A3B8)),
          ],
        ),
      ),
    ),
  );
}
