import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models.dart';

class PdfService {
  static const double pageWidthPx=1240;
  static const double pageHeightPx=1754;
  // Render at lower pixel density to avoid memory exhaustion on phones.
  static const double _renderScale=0.82;

  Future<Uint8List> buildTestPdf(
    GeneratedTest test,{
    required bool includeAnswers,
    required bool includeExplanations,
  }) async {
    final doc=pw.Document();
    await _addVersion(
      doc,
      test,
      includeAnswers:includeAnswers,
      includeExplanations:includeExplanations,
    );
    return doc.save();
  }

  Future<Uint8List> buildCombinedPdf(GeneratedTest test) async {
    final doc=pw.Document();
    await _addVersion(doc,test,includeAnswers:false,includeExplanations:false);
    await _addVersion(doc,test,includeAnswers:true,includeExplanations:true);
    return doc.save();
  }

  Future<Uint8List> buildResultPdf(
    GeneratedTest test,{
    required int earnedScore,
    required Map<String,String> answers,
  }) async {
    final doc=pw.Document();
    final png=await _renderResultPage(test,earnedScore:earnedScore,answers:answers);
    doc.addPage(
      pw.Page(
        pageFormat:PdfPageFormat.a4,
        margin:pw.EdgeInsets.zero,
        build:(_)=>pw.Image(pw.MemoryImage(png),fit:pw.BoxFit.cover),
      ),
    );
    return doc.save();
  }


  // Fill each A4 page with as many whole questions as will actually fit.
  // Using a fixed question count wastes paper and clips longer questions.
  List<List<Question>> paginateQuestions(
    List<Question> questions, {
    required bool includeAnswers,
    required bool includeExplanations,
  }) {
    final pages=<List<Question>>[];
    var current=<Question>[];
    double y=330;
    String lastType='';
    for(final question in questions) {
      final type=_typeLabel(question.type);
      final heading=type!=lastType?50.0:0.0;
      final height=_questionHeight(question,
        includeAnswers:includeAnswers,
        includeExplanations:includeExplanations,
      );
      // Leave a comfortable margin above the footer (at 1696px).
      if(current.isNotEmpty && y+heading+height>pageHeightPx-112) {
        pages.add(current);
        current=<Question>[];
        y=330;
        lastType='';
      }
      final effectiveHeading=type!=lastType?50.0:0.0;
      current.add(question);
      y+=effectiveHeading+height;
      lastType=type;
    }
    if(current.isNotEmpty) pages.add(current);
    return pages;
  }

  double _textHeight(String text,double width,double size,{bool bold=false}) {
    final painter=TextPainter(
      text:TextSpan(text:text,style:TextStyle(
        fontSize:size,
        fontWeight:bold?FontWeight.bold:FontWeight.normal,
        height:1.35,
      )),
      textDirection:ui.TextDirection.rtl,
    )..layout(maxWidth:width);
    return painter.height;
  }

  double _questionHeight(Question q,{
    required bool includeAnswers,
    required bool includeExplanations,
  }) {
    var height=_textHeight(q.question,pageWidthPx-360,33,bold:true)+11;
    if(q.type==QuestionType.trueFalse) {
      height+=60;
    } else if(q.options.isNotEmpty) {
      for(final option in q.options) {
        final optionHeight=_textHeight(option,pageWidthPx-260,27);
        height+=(optionHeight>43?optionHeight:43)+7;
      }
      height+=6;
    } else if(includeAnswers) {
      height+=_textHeight('الإجابة الصحيحة: ${q.correctAnswer}',
        pageWidthPx-210,27,bold:true)+7;
    } else {
      final lines=(q.type==QuestionType.shortAnswer||
        q.type==QuestionType.reading||q.type==QuestionType.applied)?3:1;
      height+=5+56.0*lines;
    }
    if(includeAnswers&&includeExplanations&&q.explanation.isNotEmpty) {
      height+=_textHeight('ملاحظة: ${q.explanation}',pageWidthPx-210,24)+8;
    }
    return height+18+12; // separator and safety allowance
  }

  Future<void> _addVersion(
    pw.Document doc,
    GeneratedTest test,{
    required bool includeAnswers,
    required bool includeExplanations,
  }) async {
    final pages=paginateQuestions(test.questions,
      includeAnswers:includeAnswers,
      includeExplanations:includeExplanations,
    );
    var startNumber=1;
    for(var index=0;index<pages.length;index++) {
      final group=pages[index];
      final png=await _renderPage(test,group,
        startNumber:startNumber,
        includeAnswers:includeAnswers,
        includeExplanations:includeExplanations,
        pageNumber:index+1,
        totalPages:pages.length,
      );
      doc.addPage(pw.Page(
        pageFormat:PdfPageFormat.a4,
        margin:pw.EdgeInsets.zero,
        build:(_)=>pw.Image(pw.MemoryImage(png),fit:pw.BoxFit.cover),
      ));
      startNumber+=group.length;
    }
  }

  Future<Uint8List> _renderResultPage(
    GeneratedTest test,{
    required int earnedScore,
    required Map<String,String> answers,
  }) async {
    final recorder=ui.PictureRecorder();
    final canvas=ui.Canvas(recorder,const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx));
    canvas.scale(_renderScale);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx),
      ui.Paint()..color=const ui.Color(0xFFFFFFFF),
    );
    _drawWatermark(canvas);

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(60,42,pageWidthPx-120,230),
        const ui.Radius.circular(24),
      ),
      ui.Paint()..color=const ui.Color(0xFF0E1228),
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(pageWidthPx-190,62,90,56),
        const ui.Radius.circular(18),
      ),
      ui.Paint()..color=const ui.Color(0xFF6C5CE7),
    );
    _draw(canvas,'٤',pageWidthPx-180,67,70,32,true,align:ui.TextAlign.center,color:const ui.Color(0xFFFFFFFF));
    _draw(canvas,'اختبارات رابع',92,70,pageWidthPx-330,30,true,color:const ui.Color(0xFFFFFFFF));
    _draw(canvas,'تقرير الطالب الذكي',92,111,pageWidthPx-330,17,false,color:const ui.Color(0xFFB9BED4));
    _draw(canvas,'تقرير نتيجة الاختبار',92,158,pageWidthPx-184,34,true,color:const ui.Color(0xFFFFFFFF));
    _draw(canvas,test.title,92,205,pageWidthPx-184,20,false,color:const ui.Color(0xFFD9DCEF));

    final date=DateFormat('yyyy/MM/dd').format(DateTime.now());
    final student=test.studentName.trim().isEmpty?'................................................':test.studentName.trim();
    final school=test.schoolName.trim().isEmpty?'................................................':test.schoolName.trim();
    final className=test.className.trim().isEmpty?'____':test.className.trim();
    final percent=test.totalScore==0?0:(earnedScore/test.totalScore*100).round();
    final correctCount=test.questions.where((q)=>_norm(answers[q.id]??'')==_norm(q.correctAnswer)).length;
    final wrongCount=test.questions.length-correctCount;

    double y=310;
    y=_draw(canvas,'اسم الطالب: $student',90,y,pageWidthPx-180,22,true)+8;
    y=_draw(canvas,'المدرسة: $school',90,y,pageWidthPx-180,19,false)+6;
    y=_draw(canvas,'الصف: الرابع الابتدائي        الفصل: $className',90,y,pageWidthPx-180,19,false)+6;
    y=_draw(canvas,'المادة: ${test.subjectName}        التاريخ: $date',90,y,pageWidthPx-180,19,false)+18;

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(82,y,pageWidthPx-164,210),
        const ui.Radius.circular(24),
      ),
      ui.Paint()..color=const ui.Color(0xFF0E1228),
    );
    _draw(canvas,'النتيجة النهائية',112,y+28,310,19,false,color:const ui.Color(0xFFB9BED4));
    _draw(canvas,'$percent%',112,y+58,310,54,true,color:const ui.Color(0xFFF5B942));
    _draw(canvas,'$earnedScore / ${test.totalScore} درجة',112,y+128,340,22,true,color:const ui.Color(0xFFFFFFFF));
    _draw(canvas,'صحيح: $correctCount',pageWidthPx-480,y+62,300,23,true,color:const ui.Color(0xFF8EE2B8));
    _draw(canvas,'تحتاج مراجعة: $wrongCount',pageWidthPx-480,y+110,300,21,true,color:const ui.Color(0xFFFF9D9D));
    y+=240;

    final recommendation=percent>=90
      ?'ممتاز جدًا. انتقل لاختبار أصعب أو دروس جديدة.'
      :percent>=80
        ?'أداء قوي. راجع الأخطاء مرة واحدة ثم أعد اختبارًا قصيرًا.'
        :percent>=60
          ?'راجع النقاط الضعيفة ثم نفّذ اختبارًا قصيرًا من 5 أسئلة.'
          :'ابدأ بالأسئلة الخاطئة، راجع الدرس، ثم أعد التدريب تدريجيًا.';
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(82,y,pageWidthPx-164,118),
        const ui.Radius.circular(18),
      ),
      ui.Paint()..color=const ui.Color(0xFFFFF4D8),
    );
    _draw(canvas,'توصية التطبيق',108,y+17,pageWidthPx-216,18,true,color:const ui.Color(0xFF7A5A08));
    _draw(canvas,recommendation,108,y+49,pageWidthPx-216,18,false,color:const ui.Color(0xFF473A14));
    y+=154;

    final wrong=test.questions.where((q)=>_norm(answers[q.id]??'')!=_norm(q.correctAnswer)).take(5).toList();
    _draw(canvas,'أهم نقاط المراجعة',90,y,pageWidthPx-180,24,true);
    y+=40;
    if(wrong.isEmpty){
      _draw(canvas,'لا توجد إجابات خاطئة - أحسنت!',95,y,pageWidthPx-190,20,true,color:const ui.Color(0xFF167A4B));
    }else{
      for(var i=0;i<wrong.length;i++){
        final q=wrong[i];
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(88,y-4,pageWidthPx-176,88),
            const ui.Radius.circular(14),
          ),
          ui.Paint()..color=const ui.Color(0xFFF9F9FC),
        );
        _draw(canvas,'${i+1}. ${q.question}',108,y+7,pageWidthPx-216,17,true);
        _draw(canvas,'الإجابة الصحيحة: ${q.correctAnswer}',108,y+47,pageWidthPx-216,16,false,color:const ui.Color(0xFF222222));
        y+=101;
      }
    }

    _draw(canvas,'تم إنشاء التقرير بواسطة تطبيق اختبارات رابع',80,pageHeightPx-64,pageWidthPx-160,15,false,align:ui.TextAlign.center,color:const ui.Color(0xFF8B90A5));

    return _finishPage(recorder);
  }

  Future<Uint8List> _renderPage(
    GeneratedTest test,
    List<Question> questions,{
    required int startNumber,
    required bool includeAnswers,
    required bool includeExplanations,
    required int pageNumber,
    required int totalPages,
  }) async {
    final recorder=ui.PictureRecorder();
    final canvas=ui.Canvas(recorder,const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx));
    canvas.scale(_renderScale);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx),
      ui.Paint()..color=const ui.Color(0xFFFFFFFF),
    );
    _drawWatermark(canvas);

    final border=ui.Paint()
      ..color=const ui.Color(0xFFCBD5E1)
      ..style=ui.PaintingStyle.stroke
      ..strokeWidth=2;

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(60,42,pageWidthPx-120,260),
        const ui.Radius.circular(18),
      ),
      border,
    );

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(60,42,pageWidthPx-120,52),
        const ui.Radius.circular(18),
      ),
      ui.Paint()..color=const ui.Color(0xFF202020),
    );
    _draw(canvas,'اختبار تدريبي للصف الرابع الابتدائي',88,53,pageWidthPx-176,24,true,align:ui.TextAlign.center,color:const ui.Color(0xFFFFFFFF));

    double y=108;
    y=_draw(
      canvas,
      includeAnswers?'نموذج الإجابة للمعلم':'ورقة اختبار الطالب',
      90,y,pageWidthPx-180,34,true,
      align:ui.TextAlign.center,
    )+4;
    y=_draw(
      canvas,
      test.title,
      90,y,pageWidthPx-180,27,true,
      align:ui.TextAlign.center,
    )+10;

    final date=DateFormat('yyyy/MM/dd').format(test.createdAt);
    final student=test.studentName.trim().isEmpty?'................................................':test.studentName.trim();

    final school=test.schoolName.trim().isEmpty?'................................................':test.schoolName.trim();
    final className=test.className.trim().isEmpty?'____':test.className.trim();
    y=_draw(canvas,'اسم الطالب: $student',88,y,pageWidthPx-176,20,true)+4;
    y=_draw(canvas,'المدرسة: $school        الصف: الرابع الابتدائي        الفصل: $className',88,y,pageWidthPx-176,18,false)+4;
    y=_draw(canvas,'المادة: ${test.subjectName}        التاريخ: $date        الدرجة: ${test.totalScore}',88,y,pageWidthPx-176,18,false)+5;

    if(test.lessonNames.isNotEmpty){
      final lessons=test.lessonNames.length>3
        ?'${test.lessonNames.take(3).join('، ')} ...'
        :test.lessonNames.join('، ');
      y=_draw(canvas,'الدروس: $lessons',88,y,pageWidthPx-176,17,false);
    }

    y=330;
    _draw(canvas,'أجب عن جميع الأسئلة مستعينًا بالله',92,307,pageWidthPx-184,22,true,align:ui.TextAlign.center);
    canvas.drawLine(ui.Offset(76,321),ui.Offset(pageWidthPx-76,321),ui.Paint()..color=const ui.Color(0xFF222222)..strokeWidth=2);
    var lastType = '';
    for(var i=0;i<questions.length;i++){
      final q=questions[i];
      final number=startNumber+i;
      final typeLabel=_typeLabel(q.type);
      if(typeLabel!=lastType){
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(88,y-2,pageWidthPx-176,38),const ui.Radius.circular(10)),
          ui.Paint()..color=const ui.Color(0xFFF2F2F2),
        );
        _draw(canvas,typeLabel,104,y+3,pageWidthPx-208,22,true,color:const ui.Color(0xFF4E3ED4));
        y+=50;
        lastType=typeLabel;
      }

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(pageWidthPx-136,y-2,56,43),
          const ui.Radius.circular(9),
        ),
        ui.Paint()..color=const ui.Color(0xFFF1F5F9),
      );
      _draw(canvas,'$number',pageWidthPx-130,y+2,44,27,true,align:ui.TextAlign.center);

      _draw(canvas,'الدرجة: ${q.score}',90,y,125,19,false);
      final qBottom=_draw(canvas,q.question,210,y,pageWidthPx-360,33,true);
      y=qBottom+11;

      if(q.type==QuestionType.trueFalse){
        y=_drawTrueFalse(canvas,y,includeAnswers?q.correctAnswer:null)+14;
      }else if(q.options.isNotEmpty){
        for(final option in q.options){
          final checked=includeAnswers&&_norm(option)==_norm(q.correctAnswer);
          y=_drawOption(canvas,option,y,checked)+7;
        }
        y+=6;
      }else{
        if(includeAnswers){
          y=_draw(canvas,'الإجابة الصحيحة: ${q.correctAnswer}',105,y,pageWidthPx-210,27,true)+7;
        }else{
          y+=5;
          final lines=(q.type==QuestionType.shortAnswer||q.type==QuestionType.reading||q.type==QuestionType.applied)?3:1;
          for(var line=0;line<lines;line++){
            _answerLine(canvas,y);
            y+=56;
          }
        }
      }

      if(includeAnswers&&includeExplanations&&q.explanation.isNotEmpty){
        y=_draw(canvas,'ملاحظة: ${q.explanation}',105,y,pageWidthPx-210,24,false,color:const ui.Color(0xFF475569))+8;
      }

      canvas.drawLine(
        ui.Offset(88,y),
        ui.Offset(pageWidthPx-88,y),
        ui.Paint()..color=const ui.Color(0xFFE2E8F0)..strokeWidth=1.5,
      );
      y+=18;
    }

    _draw(
      canvas,
      'انتهت الأسئلة • مع تمنياتنا بالتوفيق  |  صفحة $pageNumber من $totalPages',
      80,pageHeightPx-58,pageWidthPx-160,16,false,
      align:ui.TextAlign.center,
      color:const ui.Color(0xFF64748B),
    );

    return _finishPage(recorder);
  }

  Future<Uint8List> _finishPage(ui.PictureRecorder recorder) async {
    final picture=recorder.endRecording();
    ui.Image? image;
    try {
      image=await picture.toImage(
        (pageWidthPx*_renderScale).round(),
        (pageHeightPx*_renderScale).round(),
      );
      final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
      if(bytes==null) throw StateError('تعذر تحويل صفحة الاختبار إلى صورة');
      return Uint8List.fromList(bytes.buffer.asUint8List(bytes.offsetInBytes,bytes.lengthInBytes));
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }

  void _drawWatermark(ui.Canvas canvas){
    canvas.save();
    canvas.translate(pageWidthPx/2,pageHeightPx/2+80);
    canvas.rotate(-0.24);
    _draw(
      canvas,
      'اختبارات رابع',
      -430,-44,860,78,true,
      align:ui.TextAlign.center,
      color:const ui.Color(0x0D6C5CE7),
    );
    canvas.restore();
  }

  double _drawTrueFalse(ui.Canvas canvas,double y,String? answer){
    final rightX=pageWidthPx-390;
    final leftX=pageWidthPx-700;
    _boxWithLabel(canvas,'صح',rightX,y,answer=='صح');
    _boxWithLabel(canvas,'خطأ',leftX,y,answer=='خطأ');
    return y+46;
  }

  double _drawOption(ui.Canvas canvas,String text,double y,bool checked){
    const right=pageWidthPx-112;
    final boxLeft=right-30;
    final rect=ui.Rect.fromLTWH(boxLeft,y+2,29,29);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect,const ui.Radius.circular(4)),
      ui.Paint()
        ..color=const ui.Color(0xFF64748B)
        ..style=ui.PaintingStyle.stroke
        ..strokeWidth=2,
    );
    if(checked)_drawCheck(canvas,boxLeft,y+2);
    final bottom=_draw(canvas,text,110,y,pageWidthPx-260,27,false);
    return bottom>y+43?bottom:y+43;
  }

  void _boxWithLabel(ui.Canvas canvas,String label,double x,double y,bool checked){
    final rect=ui.Rect.fromLTWH(x,y,31,31);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect,const ui.Radius.circular(4)),
      ui.Paint()
        ..color=const ui.Color(0xFF64748B)
        ..style=ui.PaintingStyle.stroke
        ..strokeWidth=2,
    );
    if(checked)_drawCheck(canvas,x,y);
    _draw(canvas,label,x-120,y-3,105,26,true);
  }

  void _drawCheck(ui.Canvas canvas,double x,double y){
    final p=ui.Paint()
      ..color=const ui.Color(0xFF166534)
      ..strokeWidth=4
      ..strokeCap=ui.StrokeCap.round
      ..style=ui.PaintingStyle.stroke;
    final path=ui.Path()
      ..moveTo(x+6,y+16)
      ..lineTo(x+13,y+23)
      ..lineTo(x+26,y+8);
    canvas.drawPath(path,p);
  }

  void _answerLine(ui.Canvas canvas,double y){
    canvas.drawLine(
      ui.Offset(115,y+24),
      ui.Offset(pageWidthPx-115,y+24),
      ui.Paint()..color=const ui.Color(0xFF94A3B8)..strokeWidth=1.7,
    );
  }

  double _draw(
    ui.Canvas canvas,
    String text,
    double x,
    double y,
    double width,
    double size,
    bool bold,{
    ui.TextAlign align=ui.TextAlign.right,
    ui.Color color=const ui.Color(0xFF111827),
  }){
    final painter=TextPainter(
      text:TextSpan(
        text:text,
        style:TextStyle(
          color:color,
          fontSize:size,
          fontWeight:bold?FontWeight.bold:FontWeight.normal,
          height:1.35,
        ),
      ),
      textDirection:ui.TextDirection.rtl,
      textAlign:align,
    )..layout(maxWidth:width);
    painter.paint(canvas,ui.Offset(x,y));
    return y+painter.height;
  }

  String _typeLabel(QuestionType type)=>switch(type){
    QuestionType.multipleChoice=>'اختر الإجابة الصحيحة',
    QuestionType.trueFalse=>'ضع علامة صح أو خطأ',
    QuestionType.numeric=>'أوجد الناتج',
    QuestionType.shortAnswer=>'أجب عن السؤال',
    QuestionType.reading=>'اقرأ ثم أجب',
    QuestionType.applied=>'حل المسألة',
    _=>'أجب عن السؤال',
  };

  String _norm(String value)=>normalizeStudentAnswer(value);

  Future<void> printOrPreview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout:(_)=>bytes);
  }

  Future<void> share(Uint8List bytes,{required String filename}) async {
    await Printing.sharePdf(bytes:bytes,filename:filename);
  }
}
