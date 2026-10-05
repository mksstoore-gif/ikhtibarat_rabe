import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../data/models.dart';
class HistoryScreen extends StatefulWidget{const HistoryScreen({super.key});@override State<HistoryScreen> createState()=>_HistoryState();}
class _HistoryState extends State<HistoryScreen>{
  late Future<List<TestHistoryItem>> future;
  @override void initState(){super.initState();future=AppDatabase.instance.loadHistory();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('سجل الاختبارات')),body:FutureBuilder<List<TestHistoryItem>>(future:future,builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final a=s.data!; if(a.isEmpty)return const Center(child:Text('لا توجد اختبارات محفوظة بعد.'));
    return ListView.builder(padding:const EdgeInsets.all(12),itemCount:a.length,itemBuilder:(_,i){final x=a[i];return Card(child:ListTile(leading:CircleAvatar(child:Text('${x.percentage.round()}%')),title:Text(x.subjectName),subtitle:Text('${DateFormat('yyyy/MM/dd – HH:mm').format(x.createdAt)}\n${x.questionCount} سؤال'),trailing:Text('${x.earnedScore}/${x.totalScore}',style:const TextStyle(fontWeight:FontWeight.bold))));});
  }));
}
