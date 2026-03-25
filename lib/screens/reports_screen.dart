import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accounting_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/export_service.dart';
import '../core/widgets/empty_state_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AccountingProvider>().calculateDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توزيع الأرباح والتقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
            onPressed: () {
              ExportService.generatePdfReport(context, context.read<AccountingProvider>());
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'تصدير Excel',
            onPressed: () {
              ExportService.exportToExcel(context, context.read<AccountingProvider>());
            },
          ),
        ],
      ),
      body: Consumer<AccountingProvider>(
        builder: (context, accounting, child) {
          if (accounting.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accounting.partnerProfits.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد أرباح',
              message: 'لم يتم تسجيل أي تفاصيل للشركاء أو الأرباح بعد.',
              icon: Icons.pie_chart_outline,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTotalSummaryCard(context, accounting),
                const SizedBox(height: 16),
                Text(
                  'أنصبة الشركاء',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...accounting.partnerProfits.map((p) => _buildPartnerProfitCard(p)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalSummaryCard(BuildContext context, AccountingProvider accounting) {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الدخل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${accounting.totalRevenue.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي المصروفات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${accounting.totalExpenses.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('صافي الدخل القابل للتوزيع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${accounting.netProfit.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerProfitCard(PartnerProfit p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.partnerName} (${p.sharePercentage}%)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('النصيب الكلي:'),
                Text('${p.grossProfit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('السحوبات السابقة:'),
                Text('- ${p.totalWithdrawals.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الرصيد المستحق الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${p.netOwed.toStringAsFixed(2)} ر.ي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: p.netOwed >= 0 ? Colors.blue : Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
