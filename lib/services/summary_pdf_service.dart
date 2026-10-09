import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'summary_service.dart';

class SummaryPdfService {
  static const double pageWidthPx = 1240;
  static const double pageHeightPx = 1754;
  static const double _renderScale = 0.72;

  Future<Uint8List> build(StudySummary summary) async {
    final doc = pw.Document();
    for (var i = 0; i < summary.lessons.length; i++) {
      final png = await _renderPage(
        summary,
        summary.lessons[i],
        pageNumber: i + 1,
        totalPages: summary.lessons.length,
      );
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.cover),
        ),
      );
    }
    return doc.save();
  }

  Future<Uint8List> _renderPage(
    StudySummary summary,
    StudyLessonSummary lesson, {
    required int pageNumber,
    required int totalPages,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      const ui.Rect.fromLTWH(0, 0, pageWidthPx, pageHeightPx),
    );
    canvas.scale(_renderScale);

    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, pageWidthPx, pageHeightPx),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    _watermark(canvas);

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(58, 42, pageWidthPx - 116, 220),
        const ui.Radius.circular(26),
      ),
      ui.Paint()..color = const ui.Color(0xFF0E1228),
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(88, 67, 170, 48),
        const ui.Radius.circular(16),
      ),
      ui.Paint()..color = const ui.Color(0xFF6C5CE7),
    );
    _draw(
      canvas,
      'ملخص للمذاكرة',
      98,
      77,
      150,
      18,
      true,
      align: ui.TextAlign.center,
      color: const ui.Color(0xFFFFFFFF),
    );
    _draw(
      canvas,
      summary.subjectName,
      88,
      132,
      pageWidthPx - 176,
      22,
      false,
      color: const ui.Color(0xFFB9BED4),
    );
    _draw(
      canvas,
      lesson.lessonName,
      88,
      173,
      pageWidthPx - 176,
      31,
      true,
      color: const ui.Color(0xFFFFFFFF),
    );
    _draw(
      canvas,
      lesson.unitName,
      88,
      220,
      pageWidthPx - 176,
      17,
      false,
      color: const ui.Color(0xFFD9DCEF),
    );

    double y = 300;
    y = _sectionTitle(canvas, 'أهم الأفكار', y, const ui.Color(0xFF6C5CE7));
    for (final point in lesson.keyPoints) {
      y = _bullet(canvas, point, y);
    }

    if (lesson.questionsAndAnswers.isNotEmpty && y < 1140) {
      y += 16;
      y = _sectionTitle(canvas, 'راجع نفسك', y, const ui.Color(0xFF20B486));
      for (final item in lesson.questionsAndAnswers.take(3)) {
        if (y > 1390) break;
        y = _card(canvas, item, y, const ui.Color(0xFFE9F9F1));
      }
    }

    if (lesson.examples.isNotEmpty && y < 1280) {
      y += 12;
      y = _sectionTitle(canvas, 'أمثلة سريعة', y, const ui.Color(0xFFF5B942));
      for (final item in lesson.examples.take(2)) {
        if (y > 1450) break;
        y = _card(canvas, item, y, const ui.Color(0xFFFFF4D8));
      }
    }

    final date = DateFormat('yyyy/MM/dd').format(summary.createdAt);
    _draw(
      canvas,
      'اختبارات رابع • $date • صفحة $pageNumber من $totalPages',
      80,
      pageHeightPx - 62,
      pageWidthPx - 160,
      15,
      false,
      align: ui.TextAlign.center,
      color: const ui.Color(0xFF747991),
    );

    final picture = recorder.endRecording();
    ui.Image? image;
    try {
      image = await picture.toImage(
        (pageWidthPx * _renderScale).round(),
        (pageHeightPx * _renderScale).round(),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('تعذر تحويل صفحة الملخص إلى صورة');
      return Uint8List.fromList(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }

  double _sectionTitle(
    ui.Canvas canvas,
    String title,
    double y,
    ui.Color color,
  ) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(pageWidthPx - 1110, y, 1020, 52),
        const ui.Radius.circular(16),
      ),
      ui.Paint()..color = color.withOpacity(.10),
    );
    _draw(
      canvas,
      title,
      105,
      y + 11,
      pageWidthPx - 210,
      22,
      true,
      color: color,
    );
    return y + 68;
  }

  double _bullet(ui.Canvas canvas, String text, double y) {
    canvas.drawCircle(
      ui.Offset(pageWidthPx - 112, y + 15),
      6,
      ui.Paint()..color = const ui.Color(0xFF6C5CE7),
    );
    final bottom = _draw(
      canvas,
      text,
      100,
      y,
      pageWidthPx - 245,
      19,
      false,
    );
    return bottom + 13;
  }

  double _card(ui.Canvas canvas, String text, double y, ui.Color bg) {
    final height = _measure(text, pageWidthPx - 260, 17) + 34;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(92, y, pageWidthPx - 184, height),
        const ui.Radius.circular(16),
      ),
      ui.Paint()..color = bg,
    );
    _draw(canvas, text, 112, y + 15, pageWidthPx - 224, 17, false);
    return y + height + 10;
  }

  void _watermark(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(pageWidthPx / 2, pageHeightPx / 2 + 100);
    canvas.rotate(-0.24);
    _draw(
      canvas,
      'اختبارات رابع',
      -430,
      -44,
      860,
      76,
      true,
      align: ui.TextAlign.center,
      color: const ui.Color(0x0D6C5CE7),
    );
    canvas.restore();
  }

  double _measure(String text, double width, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, height: 1.45),
      ),
      textDirection: ui.TextDirection.rtl,
    )..layout(maxWidth: width);
    return painter.height;
  }

  double _draw(
    ui.Canvas canvas,
    String text,
    double x,
    double y,
    double width,
    double size,
    bool bold, {
    ui.TextAlign align = ui.TextAlign.right,
    ui.Color color = const ui.Color(0xFF14182C),
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          height: 1.4,
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: align,
    )..layout(maxWidth: width);
    painter.paint(canvas, ui.Offset(x, y));
    return y + painter.height;
  }

  Future<void> preview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> share(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'ملخص_المذاكرة.pdf');
  }
}
