import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/models.dart';
import '../services/pdf_service.dart';

class SolveTestScreen extends StatefulWidget{
  final GeneratedTest test;
  const SolveTestScreen({super.key,required this.test});
  @override State<SolveTestScreen> createState()=>_SolveState();
}
class _SolveState extends State<SolveTestScreen>{
  final answers=<String,String>{};
  bool submitted=false; int earned=0;

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.test.subjectName),actions:[
      PopupMenuButton<String>(icon:const Icon(Icons.picture_as_pdf_outlined),onSelected:_pdfAction,itemBuilder:(_)=>const [
        PopupMenuItem(value:'student_print',child:Text('طباعة/معاينة نسخة الطالب')),
        PopupMenuItem(value:'student_share',child:Text('مشاركة نسخة الطالب')),
        PopupMenuItem(value:'answers_print',child:Text('طباعة/معاينة نموذج الإجابة')),
        PopupMenuItem(value:'answers_share',child:Text('مشاركة نموذج الإجابة')),
        PopupMenuDivider(),
        PopupMenuItem(value:'bundle_print',child:Text('طباعة PDF كامل (طالب + إجابة)')),
        PopupMenuItem(value:'bundle_share',child:Text('مشاركة PDF كامل (طالب + إجابة)')),
      ])
    ]),
    body:ListView.builder(
      padding:const EdgeInsets.all(16),
      itemCount:widget.test.questions.length+1,
      itemBuilder:(context,index){
        if(index==widget.test.questions.length){
          return Padding(padding:const EdgeInsets.symmetric(vertical:24),child:submitted
            ?Card(child:Padding(padding:const EdgeInsets.all(18),child:Text('النتيجة: $earned / ${widget.test.totalScore}',textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold))))
            :FilledButton(onPressed:_submit,child:const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('تسليم الاختبار'))));
        }
        final q=widget.test.questions[index];
        return _QuestionCard(number:index+1,question:q,value:answers[q.id],submitted:submitted,onChanged:(v)=>setState(()=>answers[q.id]=v));
      },
    ),
  );

  Future<void> _submit() async {
    var score=0;
    for(final q in widget.test.questions){
      final correct=_norm(answers[q.id]??'')==_norm(q.correctAnswer);
      if(correct)score+=q.score;
      await AppDatabase.instance.updateSkill(q.skillId,correct:correct);
    }
    await AppDatabase.instance.saveResult(TestHistoryItem(testId:widget.test.id,subjectName:widget.test.subjectName,lessons:(widget.test.lessonNames.isEmpty?widget.test.lessonIds:widget.test.lessonNames).join(', '),questionCount:widget.test.questions.length,earnedScore:score,totalScore:widget.test.totalScore,createdAt:DateTime.now()));
    if(!mounted)return;
    setState((){submitted=true;earned=score;});
  }

  String _norm(String x)=>x.replaceAll(RegExp(r'\s+'),' ').trim().toLowerCase();

  Future<void> _pdfAction(String action) async {
    final service=PdfService();
    final isBundle=action.startsWith('bundle');
    final answerVersion=action.startsWith('answers');
    final bytes=isBundle
      ?await service.buildCombinedPdf(widget.test)
      :await service.buildTestPdf(widget.test,includeAnswers:answerVersion,includeExplanations:answerVersion);
    if(action.endsWith('share')){
      final filename=isBundle?'test_and_answer_key.pdf':answerVersion?'answer_key.pdf':'student_test.pdf';
      await service.share(bytes,filename:filename);
    }else{
      await service.printOrPreview(bytes);
    }
  }
}

class _QuestionCard extends StatelessWidget{
  final int number; final Question question; final String? value; final bool submitted; final ValueChanged<String> onChanged;
  const _QuestionCard({required this.number,required this.question,required this.value,required this.submitted,required this.onChanged});
  @override Widget build(BuildContext context){
    final ok=(value??'').trim().toLowerCase()==question.correctAnswer.trim().toLowerCase();
    return Card(margin:const EdgeInsets.only(bottom:14),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('$number) ${question.question}',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      if(question.options.isNotEmpty)
        ...question.options.map((o)=>RadioListTile<String>(value:o,groupValue:value,title:Text(o),onChanged:submitted?null:(v)=>onChanged(v??'')))
      else
        TextFormField(enabled:!submitted,initialValue:value,decoration:const InputDecoration(hintText:'اكتب الإجابة',border:OutlineInputBorder()),onChanged:onChanged),
      if(submitted)...[
        const SizedBox(height:10),
        Text(ok?'صحيحة':'غير صحيحة — الإجابة: ${question.correctAnswer}',style:TextStyle(fontWeight:FontWeight.bold,color:ok?Colors.green.shade700:Colors.red.shade700)),
        const SizedBox(height:4),
        Text(question.explanation),
      ]
    ])));
  }
}
