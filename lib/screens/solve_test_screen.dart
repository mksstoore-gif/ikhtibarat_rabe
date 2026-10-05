import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../data/models.dart';
import '../services/pdf_service.dart';

class SolveTestScreen extends StatefulWidget{
  final GeneratedTest test;
  const SolveTestScreen({super.key,required this.test});
  @override State<SolveTestScreen> createState()=>_SolveTestState();
}

class _SolveTestState extends State<SolveTestScreen>{
  final answers=<String,String>{};
  final controller=PageController();
  int index=0;
  bool submitted=false;
  int earned=0;

  @override
  void dispose(){
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    final total=widget.test.questions.length;
    return Scaffold(
      appBar:AppBar(
        title:Text(widget.test.subjectName,style:const TextStyle(fontWeight:FontWeight.w800)),
        actions:[
          IconButton(
            tooltip:'طباعة ومشاركة',
            onPressed:_showPdfMenu,
            icon:const Icon(Icons.print_outlined),
          ),
          const SizedBox(width:4),
        ],
      ),
      body:SafeArea(
        child:Column(
          children:[
            Container(
              width:double.infinity,
              margin:const EdgeInsets.fromLTRB(16,6,16,8),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                color:const Color(0xFFF8FAFC),
                borderRadius:BorderRadius.circular(16),
                border:Border.all(color:const Color(0xFFE5E7EB)),
              ),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Row(
                    children:[
                      Expanded(child:Text(widget.test.title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),
                      Text(DateFormat('yyyy/MM/dd').format(widget.test.createdAt),style:const TextStyle(color:Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height:8),
                  Row(
                    children:[
                      Text('السؤال ${index+1} من $total',style:const TextStyle(fontWeight:FontWeight.w700)),
                      const Spacer(),
                      if(submitted) Text('النتيجة: $earned / ${widget.test.totalScore}',style:const TextStyle(fontWeight:FontWeight.w800,color:Color(0xFF166534))),
                    ],
                  ),
                  const SizedBox(height:9),
                  ClipRRect(
                    borderRadius:BorderRadius.circular(999),
                    child:LinearProgressIndicator(
                      value:(index+1)/total,
                      minHeight:7,
                      backgroundColor:const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:PageView.builder(
                controller:controller,
                physics:const NeverScrollableScrollPhysics(),
                itemCount:total,
                onPageChanged:(v)=>setState(()=>index=v),
                itemBuilder:(context,i){
                  final q=widget.test.questions[i];
                  return _QuestionPage(
                    number:i+1,
                    question:q,
                    value:answers[q.id],
                    submitted:submitted,
                    onChanged:(v)=>setState(()=>answers[q.id]=v),
                  );
                },
              ),
            ),
            Container(
              padding:const EdgeInsets.fromLTRB(16,10,16,14),
              decoration:const BoxDecoration(
                color:Colors.white,
                border:Border(top:BorderSide(color:Color(0xFFE5E7EB))),
              ),
              child:Row(
                children:[
                  Expanded(
                    child:OutlinedButton.icon(
                      onPressed:index==0?null:()=>controller.previousPage(duration:const Duration(milliseconds:220),curve:Curves.easeOut),
                      icon:const Icon(Icons.arrow_forward_rounded),
                      label:const Text('السابق'),
                    ),
                  ),
                  const SizedBox(width:10),
                  Expanded(
                    flex:2,
                    child:index==total-1
                      ?FilledButton.icon(
                        onPressed:submitted?null:_submit,
                        icon:const Icon(Icons.check_rounded),
                        label:Text(submitted?'تم التسليم':'تسليم الاختبار',style:const TextStyle(fontWeight:FontWeight.w800)),
                      )
                      :FilledButton.icon(
                        onPressed:()=>controller.nextPage(duration:const Duration(milliseconds:220),curve:Curves.easeOut),
                        icon:const Icon(Icons.arrow_back_rounded),
                        label:const Text('التالي',style:TextStyle(fontWeight:FontWeight.w800)),
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final missing=widget.test.questions.where((q)=>(answers[q.id]??'').trim().isEmpty).length;
    if(missing>0){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('باقي $missing سؤال بدون إجابة.')));
      return;
    }
    var score=0;
    for(final q in widget.test.questions){
      final correct=_normalize(answers[q.id]??'')==_normalize(q.correctAnswer);
      if(correct)score+=q.score;
      await AppDatabase.instance.updateSkill(q.skillId,correct:correct);
    }
    await AppDatabase.instance.saveResult(
      TestHistoryItem(
        testId:widget.test.id,
        subjectName:widget.test.subjectName,
        lessons:(widget.test.lessonNames.isEmpty?widget.test.lessonIds:widget.test.lessonNames).join('، '),
        questionCount:widget.test.questions.length,
        earnedScore:score,
        totalScore:widget.test.totalScore,
        createdAt:DateTime.now(),
      ),
    );
    if(!mounted)return;
    setState((){
      submitted=true;
      earned=score;
    });
    await showDialog<void>(
      context:context,
      builder:(context)=>AlertDialog(
        title:const Text('تم تصحيح الاختبار',textAlign:TextAlign.center),
        content:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            Text('$score / ${widget.test.totalScore}',style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900,color:Color(0xFF2563EB))),
            const SizedBox(height:6),
            const Text('يمكنك الآن التنقل بين الأسئلة ومراجعة الإجابات.'),
          ],
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context),child:const Text('مراجعة الإجابات')),
          FilledButton(onPressed:(){Navigator.pop(context);_showPdfMenu();},child:const Text('طباعة / PDF')),
        ],
      ),
    );
  }

  String _normalize(String value)=>value.replaceAll(RegExp(r'\s+'),' ').trim().toLowerCase();

  Future<void> _showPdfMenu() async {
    if(!mounted)return;
    final action=await showModalBottomSheet<String>(
      context:context,
      showDragHandle:true,
      builder:(context)=>SafeArea(
        child:Padding(
          padding:const EdgeInsets.fromLTRB(12,0,12,12),
          child:Column(
            mainAxisSize:MainAxisSize.min,
            children:[
              const ListTile(title:Text('الطباعة وملفات PDF',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))),
              ListTile(leading:const Icon(Icons.description_outlined),title:const Text('معاينة نسخة الطالب'),subtitle:const Text('ورقة اختبار بدون إجابات'),onTap:()=>Navigator.pop(context,'student_print')),
              ListTile(leading:const Icon(Icons.share_outlined),title:const Text('مشاركة نسخة الطالب'),onTap:()=>Navigator.pop(context,'student_share')),
              ListTile(leading:const Icon(Icons.fact_check_outlined),title:const Text('معاينة نموذج الإجابة'),onTap:()=>Navigator.pop(context,'answers_print')),
              ListTile(leading:const Icon(Icons.picture_as_pdf_outlined),title:const Text('PDF كامل: الطالب + الإجابة'),onTap:()=>Navigator.pop(context,'bundle_share')),
            ],
          ),
        ),
      ),
    );
    if(action!=null)await _pdfAction(action);
  }

  Future<void> _pdfAction(String action) async {
    final service=PdfService();
    final isBundle=action.startsWith('bundle');
    final answersVersion=action.startsWith('answers');
    final bytes=isBundle
      ?await service.buildCombinedPdf(widget.test)
      :await service.buildTestPdf(widget.test,includeAnswers:answersVersion,includeExplanations:answersVersion);
    if(action.endsWith('share')){
      final filename=isBundle?'اختبار_ونموذج_الإجابة.pdf':answersVersion?'نموذج_الإجابة.pdf':'نسخة_الطالب.pdf';
      await service.share(bytes,filename:filename);
    }else{
      await service.printOrPreview(bytes);
    }
  }
}

class _QuestionPage extends StatelessWidget{
  final int number;
  final Question question;
  final String? value;
  final bool submitted;
  final ValueChanged<String> onChanged;
  const _QuestionPage({required this.number,required this.question,required this.value,required this.submitted,required this.onChanged});

  @override
  Widget build(BuildContext context){
    final correct=(value??'').trim().toLowerCase()==question.correctAnswer.trim().toLowerCase();
    return SingleChildScrollView(
      padding:const EdgeInsets.fromLTRB(16,8,16,24),
      child:Column(
        crossAxisAlignment:CrossAxisAlignment.stretch,
        children:[
          Text('السؤال $number',style:const TextStyle(color:Color(0xFF2563EB),fontWeight:FontWeight.w800)),
          const SizedBox(height:8),
          Text(question.question,style:const TextStyle(fontSize:22,height:1.55,fontWeight:FontWeight.w800,color:Color(0xFF0F172A))),
          const SizedBox(height:8),
          Text(_instruction(question.type),style:const TextStyle(color:Color(0xFF64748B),fontSize:14)),
          const SizedBox(height:22),
          if(question.type==QuestionType.trueFalse)
            Row(
              children:[
                Expanded(child:_LargeChoice(label:'صح',selected:value=='صح',enabled:!submitted,onTap:()=>onChanged('صح'))),
                const SizedBox(width:12),
                Expanded(child:_LargeChoice(label:'خطأ',selected:value=='خطأ',enabled:!submitted,onTap:()=>onChanged('خطأ'))),
              ],
            )
          else if(question.options.isNotEmpty)
            ...question.options.asMap().entries.map((entry)=>_OptionTile(
              index:entry.key,
              label:entry.value,
              selected:value==entry.value,
              enabled:!submitted,
              onTap:()=>onChanged(entry.value),
            ))
          else
            TextFormField(
              key:ValueKey(question.id),
              initialValue:value,
              enabled:!submitted,
              minLines:question.type==QuestionType.shortAnswer?2:1,
              maxLines:question.type==QuestionType.shortAnswer?4:1,
              keyboardType:question.type==QuestionType.numeric?TextInputType.number:TextInputType.text,
              decoration:const InputDecoration(hintText:'اكتب إجابتك هنا'),
              onChanged:onChanged,
            ),
          if(submitted)...[
            const SizedBox(height:22),
            Container(
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                color:correct?const Color(0xFFF0FDF4):const Color(0xFFFEF2F2),
                borderRadius:BorderRadius.circular(14),
                border:Border.all(color:correct?const Color(0xFFBBF7D0):const Color(0xFFFECACA)),
              ),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(correct?'إجابة صحيحة':'الإجابة تحتاج مراجعة',style:TextStyle(fontWeight:FontWeight.w900,color:correct?const Color(0xFF166534):const Color(0xFFB91C1C))),
                  if(!correct)...[
                    const SizedBox(height:4),
                    Text('الإجابة الصحيحة: ${question.correctAnswer}',style:const TextStyle(fontWeight:FontWeight.w800)),
                  ],
                  if(question.explanation.isNotEmpty)...[
                    const SizedBox(height:5),
                    Text(question.explanation,style:const TextStyle(color:Color(0xFF475569))),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _instruction(QuestionType type)=>switch(type){
    QuestionType.trueFalse=>'اضغط «صح» أو «خطأ».',
    QuestionType.multipleChoice=>'اختر إجابة واحدة من الخيارات.',
    QuestionType.numeric=>'اكتب الناتج في الخانة.',
    _=>'اكتب إجابتك في الخانة.',
  };
}

class _LargeChoice extends StatelessWidget{
  final String label;
  final bool selected,enabled;
  final VoidCallback onTap;
  const _LargeChoice({required this.label,required this.selected,required this.enabled,required this.onTap});

  @override
  Widget build(BuildContext context)=>InkWell(
    onTap:enabled?onTap:null,
    borderRadius:BorderRadius.circular(16),
    child:AnimatedContainer(
      duration:const Duration(milliseconds:140),
      height:78,
      alignment:Alignment.center,
      decoration:BoxDecoration(
        color:selected?const Color(0xFFEFF6FF):Colors.white,
        borderRadius:BorderRadius.circular(16),
        border:Border.all(color:selected?const Color(0xFF2563EB):const Color(0xFFD1D5DB),width:selected?2:1),
      ),
      child:Row(
        mainAxisAlignment:MainAxisAlignment.center,
        children:[
          Icon(selected?Icons.check_box_rounded:Icons.check_box_outline_blank_rounded,color:selected?const Color(0xFF2563EB):const Color(0xFF64748B)),
          const SizedBox(width:8),
          Text(label,style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:selected?const Color(0xFF1D4ED8):const Color(0xFF111827))),
        ],
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget{
  final int index;
  final String label;
  final bool selected,enabled;
  final VoidCallback onTap;
  const _OptionTile({required this.index,required this.label,required this.selected,required this.enabled,required this.onTap});

  @override
  Widget build(BuildContext context){
    const letters=['أ','ب','ج','د','هـ','و'];
    return Padding(
      padding:const EdgeInsets.only(bottom:10),
      child:InkWell(
        onTap:enabled?onTap:null,
        borderRadius:BorderRadius.circular(14),
        child:AnimatedContainer(
          duration:const Duration(milliseconds:140),
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(
            color:selected?const Color(0xFFEFF6FF):Colors.white,
            borderRadius:BorderRadius.circular(14),
            border:Border.all(color:selected?const Color(0xFF2563EB):const Color(0xFFE5E7EB),width:selected?2:1),
          ),
          child:Row(
            children:[
              Container(
                width:30,height:30,
                alignment:Alignment.center,
                decoration:BoxDecoration(
                  color:selected?const Color(0xFF2563EB):Colors.white,
                  borderRadius:BorderRadius.circular(7),
                  border:Border.all(color:selected?const Color(0xFF2563EB):const Color(0xFFCBD5E1)),
                ),
                child:selected
                  ?const Icon(Icons.check_rounded,size:20,color:Colors.white)
                  :Text(index<letters.length?letters[index]:'',style:const TextStyle(fontWeight:FontWeight.w800)),
              ),
              const SizedBox(width:12),
              Expanded(child:Text(label,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700))),
            ],
          ),
        ),
      ),
    );
  }
}
