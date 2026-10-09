import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'summary_service.dart';

enum _BlockType { title, point, question, example }
class _SummaryBlock {
  final _BlockType type;
  final String text;
  const _SummaryBlock(this.type, this.text);
}
class _SummaryPage {
  final StudyLessonSummary lesson;
  final List<_SummaryBlock> blocks;
  final bool continued;
  const _SummaryPage(this.lesson, this.blocks, this.continued);
}

/// Large-print A4 notes. Every selected idea is preserved across pages.
class SummaryPdfService {
  static const double pageWidthPx = 1240;
  static const double pageHeightPx = 1754;
  static const double _renderScale = 0.8;
  static const double _contentStart = 315;
  static const double _contentBottom = 1640;

  Future<Uint8List> build(StudySummary summary) async {
    if (summary.lessons.isEmpty) {
      throw StateError('اختر درسًا واحدًا على الأقل لإنشاء الملخص');
    }
    final pages = _paginateSummary(summary);
    final doc = pw.Document();
    for (var i = 0; i < pages.length; i++) {
      final png = await _renderPage(summary, pages[i],
        pageNumber: i + 1, totalPages: pages.length);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.cover),
      ));
    }
    return doc.save();
  }

  /// Diagnostic API for tests: no points, questions or examples are dropped.
  List<List<String>> paginateSummaryText(StudySummary summary) =>
      _paginateSummary(summary)
        .map((page) => page.blocks.map((block) => block.text).toList())
        .toList();

  List<_SummaryPage> _paginateSummary(StudySummary summary) {
    final pages = <_SummaryPage>[];
    for (final lesson in summary.lessons) {
      final blocks = <_SummaryBlock>[];
      if (lesson.keyPoints.isNotEmpty) {
        blocks.add(const _SummaryBlock(_BlockType.title, 'أهم الأفكار'));
        blocks.addAll(lesson.keyPoints.map(
          (text) => _SummaryBlock(_BlockType.point, text)));
      }
      if (lesson.questionsAndAnswers.isNotEmpty) {
        blocks.add(const _SummaryBlock(_BlockType.title, 'راجع نفسك'));
        blocks.addAll(lesson.questionsAndAnswers.map(
          (text) => _SummaryBlock(_BlockType.question, text)));
      }
      if (lesson.examples.isNotEmpty) {
        blocks.add(const _SummaryBlock(_BlockType.title, 'أمثلة سريعة'));
        blocks.addAll(lesson.examples.map(
          (text) => _SummaryBlock(_BlockType.example, text)));
      }
      if (blocks.isEmpty) {
        blocks.add(const _SummaryBlock(
          _BlockType.point, 'لا توجد نقاط مراجعة متاحة لهذا الدرس حاليًا.'));
      }

      var pageBlocks = <_SummaryBlock>[];
      var y = _contentStart;
      var continued = false;
      for (var i = 0; i < blocks.length; i++) {
        final block = blocks[i];
        final height = _blockHeight(block);
        final nextHeight = block.type == _BlockType.title &&
            i + 1 < blocks.length ? _blockHeight(blocks[i + 1]) : 0.0;
        if (pageBlocks.isNotEmpty &&
            y + height + nextHeight > _contentBottom) {
          pages.add(_SummaryPage(lesson, pageBlocks, continued));
          pageBlocks = <_SummaryBlock>[];
          y = _contentStart;
          continued = true;
        }
        pageBlocks.add(block);
        y += height;
      }
      if (pageBlocks.isNotEmpty) {
        pages.add(_SummaryPage(lesson, pageBlocks, continued));
      }
    }
    return pages;
  }

  double _blockHeight(_SummaryBlock block) {
    switch (block.type) {
      case _BlockType.title:
        return 76;
      case _BlockType.point:
        return _measure(block.text, pageWidthPx - 260, 29) + 22;
      case _BlockType.question:
      case _BlockType.example:
        return _measure(block.text, pageWidthPx - 230, 27) + 64;
    }
  }

  Future<Uint8List> _renderPage(StudySummary summary,
    _SummaryPage page, {required int pageNumber, required int totalPages}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder,
      const ui.Rect.fromLTWH(0, 0, pageWidthPx, pageHeightPx));
    canvas.scale(_renderScale);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, pageWidthPx, pageHeightPx),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    _watermark(canvas);

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(60, 45, pageWidthPx - 120, 235),
        const ui.Radius.circular(20)),
      ui.Paint()..color = const ui.Color(0xFF0E1228));
    _draw(canvas, 'ملخص المذاكرة • الصف الرابع', 95, 62,
      pageWidthPx - 190, 24, true,
      color: const ui.Color(0xFFE9E7FF));
    _draw(canvas, summary.subjectName, 95, 108,
      pageWidthPx - 190, 25, false,
      color: const ui.Color(0xFFE2E8F0));
    _draw(canvas,
      page.continued ? page.lesson.lessonName + ' (تابع)' : page.lesson.lessonName,
      95, 157, pageWidthPx - 190, 37, true,
      color: const ui.Color(0xFFFFFFFF));
    _draw(canvas, page.lesson.unitName, 95, 223,
      pageWidthPx - 190, 22, false,
      color: const ui.Color(0xFFD9DCEF));

    var y = _contentStart;
    for (final block in page.blocks) {
      switch (block.type) {
        case _BlockType.title:
          final color = block.text == 'أهم الأفكار'
              ? const ui.Color(0xFF5041C5)
              : block.text == 'راجع نفسك'
                  ? const ui.Color(0xFF087D58)
                  : const ui.Color(0xFF94610A);
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromLTWH(90, y, pageWidthPx - 180, 59),
              const ui.Radius.circular(13)),
            ui.Paint()..color = const ui.Color(0xFFF0EFFA));
          _draw(canvas, block.text, 108, y + 10,
            pageWidthPx - 216, 27, true, color: color);
          y += 76;
          break;
        case _BlockType.point:
          canvas.drawCircle(ui.Offset(pageWidthPx - 116, y + 19), 6,
            ui.Paint()..color = const ui.Color(0xFF6C5CE7));
          final bottom = _draw(canvas, block.text, 112, y,
            pageWidthPx - 260, 29, false);
          y = bottom + 22;
          break;
        case _BlockType.question:
        case _BlockType.example:
          final boxHeight = _measure(
            block.text, pageWidthPx - 230, 27) + 52;
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromLTWH(92, y, pageWidthPx - 184, boxHeight),
              const ui.Radius.circular(15)),
            ui.Paint()..color = block.type == _BlockType.question
                ? const ui.Color(0xFFEAF8F0)
                : const ui.Color(0xFFFFF4DA));
          _draw(canvas, block.text, 115, y + 17,
            pageWidthPx - 230, 27, false);
          y += boxHeight + 12;
          break;
      }
    }

    canvas.drawLine(
      const ui.Offset(90, 1678),
      const ui.Offset(pageWidthPx - 90, 1678),
      ui.Paint()..color = const ui.Color(0xFFE2E8F0)..strokeWidth = 2);
    _draw(canvas,
      'اختبارات رابع • ' + DateFormat('yyyy/MM/dd').format(summary.createdAt) +
        ' • صفحة ' + pageNumber.toString() + ' من ' + totalPages.toString(),
      80, 1690, pageWidthPx - 160, 19, false,
      align: ui.TextAlign.center, color: const ui.Color(0xFF64748B));

    final picture = recorder.endRecording();
    ui.Image? image;
    try {
      image = await picture.toImage(
        (pageWidthPx * _renderScale).round(),
        (pageHeightPx * _renderScale).round());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('تعذر تحويل صفحة الملخص إلى صورة');
      return Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }

  void _watermark(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(pageWidthPx / 2, pageHeightPx / 2 + 100);
    canvas.rotate(-0.24);
    _draw(canvas, 'اختبارات رابع', -430, -44, 860, 76, true,
      align: ui.TextAlign.center,
      color: const ui.Color(0x0A6C5CE7));
    canvas.restore();
  }

  double _measure(String text, double width, double size) {
    final painter = TextPainter(
      text: TextSpan(text: text,
        style: TextStyle(fontSize: size, height: 1.4)),
      textDirection: ui.TextDirection.rtl,
    )..layout(maxWidth: width);
    return painter.height;
  }

  double _draw(ui.Canvas canvas, String text, double x, double y,
    double width, double size, bool bold, {
    ui.TextAlign align = ui.TextAlign.right,
    ui.Color color = const ui.Color(0xFF14182C),
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
        color: color, fontSize: size,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        height: 1.4)),
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
