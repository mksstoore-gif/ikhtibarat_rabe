import 'package:flutter/material.dart';
import '../data/app_database.dart';
class ProgressScreen extends StatelessWidget{
  const ProgressScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('مستوى الطالب')),body:FutureBuilder<List<Map<String,Object?>>>(future:AppDatabase.instance.loadSkillProgress(),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final a=s.data!; if(a.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('ابدأ بحل بعض الاختبارات ليظهر مستوى المهارات هنا.',textAlign:TextAlign.center)));
    return ListView.builder(padding:const EdgeInsets.all(12),itemCount:a.length,itemBuilder:(_,i){final r=a[i],ok=r['correct_count'] as int,bad=r['wrong_count'] as int,total=ok+bad,p=total==0?0:(ok/total*100).round();return Card(child:ListTile(title:Text('مهارة: ${r['skill_id']}'),subtitle:Text('صحيح: $ok — خطأ: $bad'),trailing:Text('$p%')));});
  }));
}
