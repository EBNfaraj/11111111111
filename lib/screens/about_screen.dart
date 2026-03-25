import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول البرنامج'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo / Icon placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'بئر الماء (نظام محاسبي)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const Text(
              'الإصدار 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'نظام متكامل لإدارة آبار المياه، مبيعات الشاحنات، الري، وعدادات المنازل مع توزيع آلي للأرباح بين الشركاء.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            _buildInfoTile(Icons.person, 'المطور', 'اسصالح فرج'),
            _buildInfoTile(Icons.phone, 'للتواصل والاستفسار', '+967 770 344 025'),
            _buildInfoTile(Icons.email, 'البريد الإلكتروني', 'dev@example.com'),
            const SizedBox(height: 40),
            const Text(
              'حقوق الطبع محفوظة © 2026',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}
