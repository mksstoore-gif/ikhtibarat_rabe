import 'package:flutter/material.dart';
import '../data/curriculum_repository.dart';

class SettingsScreen extends StatelessWidget{
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context){
    final repo=CurriculumRepository.instance;
    final active=repo.subjects.where((s)=>repo.questionCountForSubject(s.id)>0).length;
    return Scaffold(
      appBar:AppBar(title:const Text('معلومات التطبيق')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          _info(Icons.apps_rounded,'اسم التطبيق','اختبارات الصف الرابع'),
          _info(Icons.school_outlined,'الصف','الرابع الابتدائي'),
          _info(Icons.calendar_month_outlined,'العام الدراسي','1448هـ / 2026-2027م'),
          _info(Icons.storage_outlined,'الخصوصية','كل البيانات محفوظة محليًا على الجهاز.'),
          _info(Icons.quiz_outlined,'بنوك الأسئلة','$active مواد مفعلة — ${repo.questions.length} سؤال تدريبي محلي.'),
          _info(Icons.picture_as_pdf_outlined,'الطباعة','نسخة طالب + نموذج إجابة بتنسيق ورقة اختبار.'),
          _info(Icons.block_outlined,'الدراسات الإسلامية','القرآن الكريم غير مدرج حسب إعداد المشروع.'),
        ],
      ),
    );
  }

  Widget _info(IconData icon,String title,String value)=>Container(
    margin:const EdgeInsets.only(bottom:10),
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(
      color:Colors.white,
      borderRadius:BorderRadius.circular(16),
      border:Border.all(color:const Color(0xFFE5E7EB)),
    ),
    child:Row(
      crossAxisAlignment:CrossAxisAlignment.start,
      children:[
        Icon(icon,color:const Color(0xFF2563EB)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),
          const SizedBox(height:3),
          Text(value,style:const TextStyle(color:Color(0xFF64748B))),
        ])),
      ],
    ),
  );
}
