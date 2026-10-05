import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models.dart';

class PdfService {
  static const double pageWidthPx=1240;
  static const double pageHeightPx=1754;

  Future<Uint8List> buildTestPdf(GeneratedTest test,{required bool includeAnswers,required bool includeExplanations}) async {
    final doc=pw.Document();
    await _addVersion(doc,test,includeAnswers:includeAnswers,includeExplanations:includeExplanations);
    return doc.save();
  }

  Future<Uint8List> buildCombinedPdf(GeneratedTest test) async {
    final doc=pw.Document();
    await _addVersion(doc,test,includeAnswers:false,includeExplanations:false);
    await _addVersion(doc,test,includeAnswers:true,includeExplanations:true);
    return doc.save();
  }

  Future<void> _addVersion(pw.Document doc,GeneratedTest test,{required bool includeAnswers,required bool includeExplanations}) async {
    final perPage=includeAnswers?4:5;
    for(var start=0;start<test.questions.length;start+=perPage){
      final end=(start+perPage>test.questions.length)?test.questions.length:start+perPage;
      final png=await _renderPage(
        test,test.questions.sublist(start,end),startNumber:start+1,
        includeAnswers:includeAnswers,includeExplanations:includeExplanations,
        title:includeAnswers?'نموذج الإجابة':'نسخة الطالب',
      );
      doc.addPage(pw.Page(pageFormat:PdfPageFormat.a4,margin:pw.EdgeInsets.zero,build:(_)=>pw.Image(pw.MemoryImage(png),fit:pw.BoxFit.cover)));
    }
  }

  Future<Uint8List> _renderPage(GeneratedTest test,List<Question> qs,{required int startNumber,required bool includeAnswers,required bool includeExplanations,required String title}) async {
    final recorder=ui.PictureRecorder();
    final canvas=ui.Canvas(recorder,const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx));
    canvas.drawRect(const ui.Rect.fromLTWH(0,0,pageWidthPx,pageHeightPx),ui.Paint()..color=const ui.Color(0xFFFFFFFF));
    double y=55;
    y=_draw(canvas,'${test.title} — $title',80,y,pageWidthPx-160,38,true)+10;
    y=_draw(canvas,'المادة: ${test.subjectName}    التاريخ: ${test.createdAt.toLocal().toString().split(' ').first}    الدرجة: ${test.totalScore}',80,y,pageWidthPx-160,22,false)+8;
    final student=test.studentName.isEmpty?'........................................':test.studentName;
    y=_draw(canvas,'اسم الطالب: $student',80,y,pageWidthPx-160,22,false)+8;
    if(test.lessonNames.isNotEmpty){
      y=_draw(canvas,'الدروس: ${test.lessonNames.join('، ')}',80,y,pageWidthPx-160,18,false)+18;
    }else{
      y+=14;
    }
    canvas.drawLine(ui.Offset(80,y),ui.Offset(pageWidthPx-80,y),ui.Paint()..color=const ui.Color(0xFFBBBBBB)..strokeWidth=2);
    y+=24;

    for(var i=0;i<qs.length;i++){
      final q=qs[i];
      y=_draw(canvas,'${startNumber+i}) ${q.question}',90,y,pageWidthPx-180,27,true);
      if(q.options.isNotEmpty){
        y+=8;
        for(final option in q.options){
          y=_draw(canvas,'○ $option',120,y,pageWidthPx-240,22,false)+3;
        }
      }else if(!includeAnswers){
        y+=10;
        canvas.drawLine(ui.Offset(120,y+28),ui.Offset(pageWidthPx-120,y+28),ui.Paint()..color=const ui.Color(0xFF777777)..strokeWidth=2);
        y+=48;
      }
      if(includeAnswers){
        y+=8;
        y=_draw(canvas,'الإجابة الصحيحة: ${q.correctAnswer}',110,y,pageWidthPx-220,23,true);
        if(includeExplanations&&q.explanation.isNotEmpty){
          y+=4;
          y=_draw(canvas,'الشرح: ${q.explanation}',110,y,pageWidthPx-220,20,false);
        }
      }
      y+=24;
    }
    final picture=recorder.endRecording();
    final image=await picture.toImage(pageWidthPx.toInt(),pageHeightPx.toInt());
    final data=await image.toByteData(format:ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  double _draw(ui.Canvas canvas,String text,double x,double y,double width,double size,bool bold){
    final p=TextPainter(
      text:TextSpan(text:text,style:TextStyle(color:const ui.Color(0xFF111111),fontSize:size,fontWeight:bold?FontWeight.bold:FontWeight.normal,height:1.35)),
      textDirection:TextDirection.rtl,
      textAlign:ui.TextAlign.right,
    )..layout(maxWidth:width);
    p.paint(canvas,ui.Offset(x,y));
    return y+p.height;
  }

  Future<void> printOrPreview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout:(_)=>bytes);
  }
  Future<void> share(Uint8List bytes,{required String filename}) async {
    await Printing.sharePdf(bytes:bytes,filename:filename);
  }
}
