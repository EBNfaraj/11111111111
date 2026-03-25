import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/truck_sale_provider.dart';
import '../models/truck_sale.dart';
import '../core/utils/dialog_utils.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/number_to_words.dart';

class TrucksScreen extends StatefulWidget {
  const TrucksScreen({Key? key}) : super(key: key);

  @override
  State<TrucksScreen> createState() => _TrucksScreenState();
}

class _TrucksScreenState extends State<TrucksScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TruckSaleProvider>().fetchSales();
    });
  }

  void _showSaleDialog(BuildContext context) {
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تسجيل بيع وايتات'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'العدد'),
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'سعر الوايت الواحد'),
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                if (quantityController.text.isNotEmpty && priceController.text.isNotEmpty)
                  Builder(builder: (context) {
                    final q = int.tryParse(quantityController.text) ?? 0;
                    final p = double.tryParse(priceController.text) ?? 0;
                    final total = q * p;
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
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
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
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (quantity <= 0 || price <= 0) {
                  DialogUtils.showErrorSnackbar(context, 'الرجاء إدخال العدد والسعر بشكل صحيح');
                  return;
                }

                final sale = TruckSale(
                  quantity: quantity,
                  pricePerTruck: price,
                  date: DateTime.now().toIso8601String(),
                  notes: notesController.text,
                );

                await context.read<TruckSaleProvider>().addSale(sale);
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
        title: const Text('مبيعات الوايتات'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSaleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<TruckSaleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final filteredSales = provider.sales.where((s) => 
            (s.notes != null && s.notes!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
            s.date.contains(_searchQuery)
          ).toList();

          if (provider.sales.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد مبيعات',
              message: 'لم يتم تسجيل أي عملية بيع وايتات بعد. استخدم زر الإضافة لتبدأ التسجيل.',
              icon: Icons.local_shipping_outlined,
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
                child: filteredSales.isEmpty && _searchQuery.isNotEmpty
                  ? const Center(child: Text('لا توجد نتائج للبحث'))
                  : ListView.builder(
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = filteredSales[index];
                        final date = DateTime.parse(sale.date);
                        final dateString = DateFormat('yyyy-MM-dd HH:mm').format(date);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.local_shipping, size: 40, color: Colors.cyan),
                            title: Text('العدد: ${sale.quantity} وايت، السعر: ${sale.pricePerTruck}'),
                            subtitle: Text('تاريخ: $dateString\nالإجمالي: ${sale.calculatedTotalPrice} ر.ي'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                DialogUtils.showConfirmDelete(context, () {
                                  provider.deleteSale(sale.id!);
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
