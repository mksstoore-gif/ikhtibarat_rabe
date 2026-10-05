import 'package:flutter/material.dart';
import '../data/curriculum_repository.dart';
class SettingsScreen extends StatelessWidget{
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context){
    final repo=CurriculumRepository.instance;
    return Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const ListTile(leading:Icon(Icons.school_outlined),title:Text('الصف'),subtitle:Text('الرابع الابتدائي')),
      const ListTile(leading:Icon(Icons.calendar_month_outlined),title:Text('العام الدراسي'),subtitle:Text('1448هـ / 2026-2027م')),
      const ListTile(leading:Icon(Icons.storage_outlined),title:Text('التخزين'),subtitle:Text('محلي على الجهاز — بدون تسجيل دخول أو خادم')),
      ListTile(leading:const Icon(Icons.menu_book_outlined),title:const Text('المحتوى'),subtitle:Text('${repo.subjects.length} مواد — ${repo.lessons.length} عنوان درس موثق من الكتب المرفوعة')),
      ListTile(leading:const Icon(Icons.quiz_outlined),title:const Text('بنك الأسئلة الحالي'),subtitle:Text('${repo.questions.length} سؤال تدريبي أصلي في الرياضيات؛ بقية المواد قيد الإعداد. الدروس المدروسة محفوظة محليًا.')),
      const ListTile(leading:Icon(Icons.block_outlined),title:Text('الدراسات الإسلامية'),subtitle:Text('القرآن الكريم مستبعد من التطبيق حسب متطلبات المشروع.')),
    ]));
  }
}
