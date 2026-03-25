import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/irrigation_provider.dart';
import '../models/irrigation.dart';
import '../core/utils/dialog_utils.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/number_to_words.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({Key? key}) : super(key: key);

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<IrrigationProvider>().fetchIrrigations();
    });
  }

  void _showIrrigationDialog(BuildContext context) {
    final hoursController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تسجيل عملية سقي'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'عدد الساعات'),
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'سعر الساعة'),
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                if (hoursController.text.isNotEmpty && priceController.text.isNotEmpty)
                  Builder(builder: (context) {
                    final h = double.tryParse(hoursController.text) ?? 0;
                    final p = double.tryParse(priceController.text) ?? 0;
                    final total = h * p;
                    if (total <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        children: [
                          Text('إجمالي المبلغ: ${total.toStringAsFixed(0)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            NumberToWords.convertWithCurrency(total),
                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات (الجهة / المزرعة)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final hours = double.tryParse(hoursController.text) ?? 0.0;
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (hours <= 0 || price <= 0) {
                  DialogUtils.showErrorSnackbar(context, 'الرجاء إدخال الساعات والسعر بشكل صحيح');
                  return;
                }

                final irrigation = Irrigation(
                  hours: hours,
                  pricePerHour: price,
                  date: DateTime.now().toIso8601String(),
                  notes: notesController.text,
                );

                await context.read<IrrigationProvider>().addIrrigation(irrigation);
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
        title: const Text('سقي الأراضي والمزارع'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIrrigationDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<IrrigationProvider>(
        builder: (context, provider, child) {
          final filteredIrrigations = provider.irrigations.where((i) => 
            (i.notes != null && i.notes!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
            i.date.contains(_searchQuery)
          ).toList();

          if (provider.irrigations.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد عمليات سقي',
              message: 'لم يتم تسجيل أي عملية سقي للأراضي بعد. يمكنك البدء بإضافة عملية جديدة.',
              icon: Icons.water_outlined,
            );
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث في الملاحظات أو التاريخ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () {
                            _searchController.clear();
                            setState(() { _searchQuery = ''; });
                          }
                        ) 
                      : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() { _searchQuery = val; });
                  },
                ),
              ),
              Expanded(
                child: filteredIrrigations.isEmpty && _searchQuery.isNotEmpty
                  ? const Center(child: Text('لا توجد نتائج للبحث'))
                  : ListView.builder(
                      itemCount: filteredIrrigations.length,
                      itemBuilder: (context, index) {
                        final irrigation = filteredIrrigations[index];
                        final date = DateTime.parse(irrigation.date);
                        final dateString = DateFormat('yyyy-MM-dd HH:mm').format(date);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.waves, size: 40, color: Colors.blue),
                            title: Text('الساعات: ${irrigation.hours}، سعر الساعة: ${irrigation.pricePerHour}'),
                            subtitle: Text('تاريخ: $dateString\nالإجمالي: ${irrigation.calculatedTotalPrice} ر.ي'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                DialogUtils.showConfirmDelete(context, () {
                                  provider.deleteIrrigation(irrigation.id!);
                                });
                              },
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
}
