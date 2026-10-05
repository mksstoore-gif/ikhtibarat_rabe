import 'package:flutter/material.dart';
import '../data/curriculum_repository.dart';
import 'create_test_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'subjects_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context){
    final repo=CurriculumRepository.instance;
    final mathCount=repo.questionCountForSubject('math');
    return Scaffold(
      appBar: AppBar(title:const Text('اختبارات رابع'),centerTitle:true),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Card(
          color:Theme.of(context).colorScheme.primaryContainer,
          child:Padding(
            padding:const EdgeInsets.all(14),
            child:Text('تم إدخال فهارس الدروس من الكتب الرسمية المرفوعة. بنك الأسئلة المحلي المفعّل الآن للرياضيات ($mathCount سؤال تدريبي أصلي)، وبقية المواد تظهر بفهرسها الرسمي حتى يكتمل بنكها.',textAlign:TextAlign.center),
          ),
        ),
        const SizedBox(height:10),
        _Tile(Icons.add_circle_outline,'إنشاء اختبار','اختر المادة والدروس المتاح لها بنك أسئلة',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CreateTestScreen()))),
        _Tile(Icons.menu_book_outlined,'المواد والدروس','حدد ما تمت دراسته واعرض الفهرس الرسمي',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SubjectsScreen(repository:repo)))),
        _Tile(Icons.history,'سجل الاختبارات','النتائج السابقة محفوظة محليًا',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen()))),
        _Tile(Icons.insights_outlined,'مستوى الطالب','عرض مؤشرات الأداء حسب المهارات',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProgressScreen()))),
        _Tile(Icons.settings_outlined,'الإعدادات','معلومات النسخة والمحتوى',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen()))),
      ]),
    );
  }
}
class _Tile extends StatelessWidget{
  final IconData icon; final String title,subtitle; final VoidCallback tap;
  const _Tile(this.icon,this.title,this.subtitle,this.tap);
  @override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.only(bottom:12),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:10),leading:Icon(icon,size:34),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_left),onTap:tap));
}
