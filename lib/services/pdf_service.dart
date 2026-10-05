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

  Future<void> _addVersion(
    pw.Document doc,
    GeneratedTest test,{
    required bool includeAnswers,
    required bool includeExplanations,
  }) async {
    final perPage=includeAnswers?4:5;
    final totalPages=(test.questions.length/perPage).ceil();
    var pageNumber=1;

    for(var start=0;start<test.questions.length;start+=perPage){
      final end=(start+perPage>test.questions.length)?test.questions.length:start+perPage;
      final png=await _renderPage(
        test,
        test.questions.sublist(start,end),
        startNumber:start+1,
        includeAnswers:includeAnswers,
        includeExplanations:includeExplanations,
        pageNumber:pageNumber,
        totalPages:totalPages,
      );
      doc.addPage(
        pw.Page(
          pageFormat:PdfPageFormat.a4,
          margin:pw.EdgeInsets.zero,
          build:(_)=>pw.Image(pw.MemoryImage(png),fit:pw.BoxFit.cover),
        ),
      );
      pageNumber++;
    }
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
    canvas.drawRect(
      const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx),
      ui.Paint()..color=const ui.Color(0xFFFFFFFF),
    );

    final border=ui.Paint()
      ..color=const ui.Color(0xFFCBD5E1)
      ..style=ui.PaintingStyle.stroke
      ..strokeWidth=2;

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(60,42,pageWidthPx-120,190),
        const ui.Radius.circular(18),
      ),
      border,
    );

    double y=62;
    y=_draw(
      canvas,
      includeAnswers?'نموذج الإجابة':'اختبار الصف الرابع الابتدائي',
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

    y=_draw(canvas,'المادة: ${test.subjectName}        التاريخ: $date        الدرجة: ${test.totalScore}',88,y,pageWidthPx-176,21,false)+5;
    y=_draw(canvas,'اسم الطالب: $student',88,y,pageWidthPx-176,21,false)+5;

    if(test.lessonNames.isNotEmpty){
      final lessons=test.lessonNames.length>3
        ?'${test.lessonNames.take(3).join('، ')} ...'
        :test.lessonNames.join('، ');
      y=_draw(canvas,'الدروس: $lessons',88,y,pageWidthPx-176,17,false);
    }

    y=260;
    for(var i=0;i<questions.length;i++){
      final q=questions[i];
      final number=startNumber+i;

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(pageWidthPx-136,y-2,56,43),
          const ui.Radius.circular(9),
        ),
        ui.Paint()..color=const ui.Color(0xFFF1F5F9),
      );
      _draw(canvas,'$number',pageWidthPx-130,y+4,44,22,true,align:ui.TextAlign.center);

      final qBottom=_draw(canvas,q.question,92,y,pageWidthPx-250,25,true);
      y=qBottom+11;

      if(q.type==QuestionType.trueFalse){
        y=_drawTrueFalse(canvas,y,includeAnswers?q.correctAnswer:null)+14;
      }else if(q.options.isNotEmpty){
        for(final option in q.options){
          final checked=includeAnswers&&_norm(option)==_norm(q.correctAnswer);
          y=_drawOption(canvas,option,y,checked)+5;
        }
        y+=6;
      }else{
        if(includeAnswers){
          y=_draw(canvas,'الإجابة الصحيحة: ${q.correctAnswer}',105,y,pageWidthPx-210,20,true)+7;
        }else{
          y+=5;
          _answerLine(canvas,y);
          y+=45;
          if(q.type==QuestionType.shortAnswer||q.type==QuestionType.reading||q.type==QuestionType.applied){
            _answerLine(canvas,y);
            y+=45;
          }
        }
      }

      if(includeAnswers&&includeExplanations&&q.explanation.isNotEmpty){
        y=_draw(canvas,'ملاحظة: ${q.explanation}',105,y,pageWidthPx-210,17,false,color:const ui.Color(0xFF475569))+8;
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
      'صفحة $pageNumber من $totalPages',
      80,pageHeightPx-58,pageWidthPx-160,16,false,
      align:ui.TextAlign.center,
      color:const ui.Color(0xFF64748B),
    );

    final picture=recorder.endRecording();
    final image=await picture.toImage(pageWidthPx.toInt(),pageHeightPx.toInt());
    final data=await image.toByteData(format:ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
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
    final bottom=_draw(canvas,text,110,y,pageWidthPx-260,20,false);
    return bottom>y+34?bottom:y+34;
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
    _draw(canvas,label,x-120,y-1,105,21,true);
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

  String _norm(String value)=>value.replaceAll(RegExp(r'\s+'),' ').trim().toLowerCase();

  Future<void> printOrPreview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout:(_)=>bytes);
  }

  Future<void> share(Uint8List bytes,{required String filename}) async {
    await Printing.sharePdf(bytes:bytes,filename:filename);
  }
}
