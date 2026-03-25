import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BackupService {
  static const String backupFileName = 'WaterWellBackup.db';

  static Future<void> backupDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'water_well.db');
      final File dbFile = File(path);

      if (!dbFile.existsSync()) {
        throw Exception('قاعدة البيانات غير موجودة. تأكد من إدخال بيانات أولاً.');
      }

      // We use public Downloads directory for easy access by the user
      final Directory downloadDirectory = Directory('/storage/emulated/0/Download');
      if (!downloadDirectory.existsSync()) {
        downloadDirectory.createSync(recursive: true);
      }

      final String backupPath = join(downloadDirectory.path, backupFileName);
      await dbFile.copy(backupPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم النسخ الاحتياطي بنجاح في مجلد التنزيلات: \$backupFileName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء النسخ الاحتياطي: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> restoreDatabase(BuildContext context) async {
    try {
      final downloadDirectory = Directory('/storage/emulated/0/Download');
      final String backupPath = join(downloadDirectory.path, backupFileName);
      final File backupFile = File(backupPath);

      if (!backupFile.existsSync()) {
        throw Exception('لم يتم العثور على ملف النسخ الاحتياطي (\$backupFileName) في مجلد التنزيلات.');
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'water_well.db');
      
      // Close existing DB connection if open? 
      // Sqflite handles simple overwrites alright if we just restart the app,
      // but to be safe, we overwrite the file directly.
      await backupFile.copy(path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استعادة قاعدة البيانات بنجاح! يرجى إعادة تشغيل التطبيق بالكامل لتحديث البيانات.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الاستعادة: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
