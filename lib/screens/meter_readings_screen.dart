import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/house_provider.dart';
import '../models/house.dart';
import '../models/meter_reading.dart';
import '../core/utils/dialog_utils.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/number_to_words.dart';

class MeterReadingsScreen extends StatefulWidget {
  final House house;
  const MeterReadingsScreen({Key? key, required this.house}) : super(key: key);

  @override
  State<MeterReadingsScreen> createState() => _MeterReadingsScreenState();
}

class _MeterReadingsScreenState extends State<MeterReadingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.house.id != null) {
        context.read<HouseProvider>().fetchMeterReadings(widget.house.id!);
      }
    });
  }

  void _showReadingDialog(BuildContext context, HouseProvider provider) {
    final prevController = TextEditingController();
    final currController = TextEditingController();
    final priceController = TextEditingController(text: '1.5');

    if (provider.meterReadings.isNotEmpty) {
      prevController.text = provider.meterReadings.first.currentReading.toString();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('إضافة قراءة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prevController,
                  decoration: const InputDecoration(labelText: 'القراءة السابقة'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: currController,
                  decoration: const InputDecoration(labelText: 'القراءة الحالية'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'سعر الوحدة'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                if (prevController.text.isNotEmpty && currController.text.isNotEmpty)
                  Builder(builder: (context) {
                    final prev = double.tryParse(prevController.text) ?? 0;
                    final curr = double.tryParse(currController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    final consumption = curr - prev;
                    final total = consumption * price;
                    if (consumption < 0) return const Text('القراءة الحالية يجب أن تكون أكبر من السابقة', style: TextStyle(color: Colors.red, fontSize: 12));
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Text('الاستهلاك: $consumption وحدة', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('الإجمالي: ${total.toStringAsFixed(0)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text(
                            NumberToWords.convertWithCurrency(total),
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final prev = int.tryParse(prevController.text) ?? 0;
                final curr = int.tryParse(currController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0.0;

                if (curr < prev) {
                  DialogUtils.showErrorSnackbar(context, 'القراءة الحالية أقل من السابقة');
                  return;
                }

                final reading = MeterReading(
                  houseId: widget.house.id!,
                  previousReading: prev,
                  currentReading: curr,
                  pricePerUnit: price,
                  date: DateTime.now().toIso8601String(),
                );

                await provider.addMeterReading(reading);
                if (!mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عداد: ${widget.house.ownerName}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReadingDialog(context, context.read<HouseProvider>()),
        child: const Icon(Icons.add),
      ),
      body: Consumer<HouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.meterReadings.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد قراءات',
              message: 'لم يتم تسجيل أي قراءات لهذا العداد بعد.',
              icon: Icons.speed_outlined,
            );
          }

          final totalConsumption = provider.meterReadings.fold<double>(0, (sum, r) => sum + r.calculatedConsumption);
          final totalAmount = provider.meterReadings.fold<double>(0, (sum, r) => sum + r.calculatedTotalPrice);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('إجمالي الاستهلاك', '${totalConsumption.toStringAsFixed(0)} وحدة', Icons.water_drop),
                    _buildSummaryItem('إجمالي المبلغ', '${totalAmount.toStringAsFixed(0)} ر.ي', Icons.payments),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.meterReadings.length,
                  itemBuilder: (context, index) {
                    final reading = provider.meterReadings[index];
                    final date = DateTime.parse(reading.date);
                    final dateString = DateFormat('yyyy-MM-dd').format(date);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                        ),
                        title: Text('استهلاك: ${reading.calculatedConsumption.toStringAsFixed(0)} وحدة', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('تاريخ: $dateString  |  ${reading.previousReading} ← ${reading.currentReading}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${reading.calculatedTotalPrice.toStringAsFixed(0)} ر.ي',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => DialogUtils.showConfirmDelete(context, () => provider.deleteMeterReading(reading.id!, widget.house.id!)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
