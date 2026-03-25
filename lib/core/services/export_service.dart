import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../providers/accounting_provider.dart';

class ExportService {
  static Future<void> generatePdfReport(BuildContext context, AccountingProvider accounting) async {
    final pdf = pw.Document();

    // Load Cairo font for Arabic text support
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('تقرير الأرباح والتوزيع - نظام إدارة البئر', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: fontBold))),
              pw.SizedBox(height: 20),
              
              // Total Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey300)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('الخلاصة المالية:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: fontBold)),
                    pw.Divider(),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('إجمالي الدخل:'),
                      pw.Text('${accounting.totalRevenue.toStringAsFixed(2)} ر.ي', style: const pw.TextStyle(color: PdfColors.green800)),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('إجمالي المصروفات:'),
                      pw.Text('${accounting.totalExpenses.toStringAsFixed(2)} ر.ي', style: const pw.TextStyle(color: PdfColors.red800)),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Divider(),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('صافي الدخل القابل للتوزيع:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold)),
                      pw.Text('${accounting.netProfit.toStringAsFixed(2)} ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800, font: fontBold)),
                    ]),
                  ]
                )
              ),
              pw.SizedBox(height: 20),

              // Partners Breakdown
              pw.Text('أنصبة الشركاء:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: fontBold)),
              pw.Divider(),
              ...accounting.partnerProfits.map((p) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${p.partnerName} (${p.sharePercentage}%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, font: fontBold)),
                    pw.SizedBox(height: 5),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('النصيب الكلي:'),
                      pw.Text('${p.grossProfit.toStringAsFixed(2)} ر.ي', style: const pw.TextStyle(color: PdfColors.green800)),
                    ]),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('السحوبات السابقة:'),
                      pw.Text('- ${p.totalWithdrawals.toStringAsFixed(2)} ر.ي', style: const pw.TextStyle(color: PdfColors.red800)),
                    ]),
                    pw.SizedBox(height: 2),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('الرصيد المستحق الدفع:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold)),
                      pw.Text(
                        '${p.netOwed.toStringAsFixed(2)} ر.ي',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: p.netOwed >= 0 ? PdfColors.blue800 : PdfColors.red800, font: fontBold)
                      ),
                    ]),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey300),
                  ]
                )
              )).toList(),
            ]
          );
        },
      ),
    );

    // Save or Print
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Water_Well_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء طباعة التقرير: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> exportToExcel(BuildContext context, AccountingProvider accounting) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['الأنصبة'];
      excel.setDefaultSheet('الأنصبة');

      // Headers
      sheetObject.appendRow([
        TextCellValue('اسم الشريك'),
        TextCellValue('نسبة الملكية (%)'),
        TextCellValue('النصيب الكلي (ر.ي)'),
        TextCellValue('السحوبات السابقة (ر.ي)'),
        TextCellValue('الرصيد المستحق (ر.ي)'),
      ]);

      for (var p in accounting.partnerProfits) {
        sheetObject.appendRow([
          TextCellValue(p.partnerName),
          DoubleCellValue(p.sharePercentage),
          DoubleCellValue(p.grossProfit),
          DoubleCellValue(p.totalWithdrawals),
          DoubleCellValue(p.netOwed),
        ]);
      }

      // Add Summary Rows
      sheetObject.appendRow([TextCellValue('')]);
      sheetObject.appendRow([
        TextCellValue('إجمالي الدخل:'),
        DoubleCellValue(accounting.totalRevenue),
      ]);
      sheetObject.appendRow([
        TextCellValue('المصروفات:'),
        DoubleCellValue(accounting.totalExpenses),
      ]);
      sheetObject.appendRow([
        TextCellValue('صافي الدخل القابل للتوزيع:'),
        DoubleCellValue(accounting.netProfit),
      ]);

      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'Water_Well_Accounting_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      final String filePath = '${directory.path}/$fileName';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تصدير ملف الإكسل بنجاح: \$filePath')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير الإكسل: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
