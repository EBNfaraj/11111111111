import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/withdrawal_provider.dart';
import '../providers/partner_provider.dart';
import '../models/expense.dart';
import '../models/withdrawal.dart';
import '../core/utils/dialog_utils.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/number_to_words.dart';

class FinancialsScreen extends StatelessWidget {
  const FinancialsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإدارة المالية والمصروفات'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'المصروفات', icon: Icon(Icons.money_off_csred)),
              Tab(text: 'السحوبات', icon: Icon(Icons.account_balance_wallet)),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelColor: Colors.white70,
            labelColor: Colors.white,
          ),
        ),
        body: const TabBarView(
          children: [
            _ExpensesTab(),
            _WithdrawalsTab(),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  EXPENSES TAB
// ──────────────────────────────────────────────
class _ExpensesTab extends StatefulWidget {
  const _ExpensesTab({Key? key}) : super(key: key);

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ExpenseProvider>().fetchExpenses());
  }

  void _showExpenseDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'محروقات';
    final categories = ['محروقات', 'صيانة', 'رواتب', 'كهرباء', 'مواد', 'أخرى'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('إضافة مصروف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'الوصف / ملاحظات'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'القيمة (ر.ي)'),
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                if (amountController.text.isNotEmpty)
                  Builder(builder: (context) {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        NumberToWords.convertWithCurrency(amount),
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
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
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) {
                  DialogUtils.showErrorSnackbar(context, 'الرجاء إدخال قيمة المصروف بشكل صحيح');
                  return;
                }
                await context.read<ExpenseProvider>().addExpense(
                  Expense(
                    category: selectedCategory,
                    description: descController.text.isEmpty ? null : descController.text,
                    amount: amount,
                    date: DateTime.now().toIso8601String(),
                  ),
                );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(context),
        label: const Text('إضافة مصروف'),
        icon: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredExpenses = provider.expenses.where((e) => 
            e.category.contains(_searchQuery) || 
            (e.description != null && e.description!.toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

          if (provider.expenses.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد مصروفات',
              message: 'لم يتم تسجيل أي مصروفات تشغيلية بعد.',
              icon: Icons.money_off_csred_outlined,
            );
          }

          final total = provider.expenses.fold<double>(0, (s, e) => s + e.amount);

          return Column(
            children: [
              // Summary Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.errorColor, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إجمالي المصروفات', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${total.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Icon(Icons.trending_down, color: Colors.white30, size: 40),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث في المصروفات...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: filteredExpenses.isEmpty && _searchQuery.isNotEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final e = filteredExpenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50, 
                                child: const Icon(Icons.receipt_long, color: Colors.red)
                              ),
                              title: Text(e.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${e.description ?? ""} \n${DateFormat('yyyy-MM-dd').format(DateTime.parse(e.date))}'),
                              trailing: Text('${e.amount.toStringAsFixed(0)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              onLongPress: () {
                                DialogUtils.showConfirmDelete(context, () => provider.deleteExpense(e.id!));
                              },
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

// ──────────────────────────────────────────────
//  WITHDRAWALS TAB
// ──────────────────────────────────────────────
class _WithdrawalsTab extends StatefulWidget {
  const _WithdrawalsTab({Key? key}) : super(key: key);

  @override
  State<_WithdrawalsTab> createState() => _WithdrawalsTabState();
}

class _WithdrawalsTabState extends State<_WithdrawalsTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<WithdrawalProvider>().fetchWithdrawals());
    Future.microtask(() => context.read<PartnerProvider>().fetchPartners());
  }

  void _showWithdrawalDialog(BuildContext context) {
    int? selectedPartnerId;
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final partners = context.watch<PartnerProvider>().partners;
          return AlertDialog(
            title: const Text('إضافة سحب مالي'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    value: selectedPartnerId,
                    decoration: const InputDecoration(labelText: 'المسحوب له (الشريك / العامل)'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('عامل / مصروف عام')),
                      ...partners.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (v) => setState(() => selectedPartnerId = v),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'المبلغ المسحوب (ر.ي)'),
                    keyboardType: TextInputType.text,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (amountController.text.isNotEmpty)
                    Builder(builder: (context) {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          NumberToWords.convertWithCurrency(amount),
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount <= 0) {
                    DialogUtils.showErrorSnackbar(context, 'الرجاء إدخال المبلغ بشكل صحيح');
                    return;
                  }
                  await context.read<WithdrawalProvider>().addWithdrawal(
                    Withdrawal(
                      partnerId: selectedPartnerId,
                      amount: amount,
                      date: DateTime.now().toIso8601String(),
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    ),
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWithdrawalDialog(context),
        label: const Text('إضافة سحب'),
        icon: const Icon(Icons.add),
      ),
      body: Consumer2<WithdrawalProvider, PartnerProvider>(
        builder: (context, provider, partnerProvider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredWithdrawals = provider.withdrawals.where((w) {
            final partnerName = w.partnerId == null 
              ? 'عامل' 
              : partnerProvider.partners.where((p) => p.id == w.partnerId).map((p) => p.name).firstOrNull ?? '';
            return partnerName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                   (w.notes != null && w.notes!.toLowerCase().contains(_searchQuery.toLowerCase()));
          }).toList();

          if (provider.withdrawals.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد سحوبات',
              message: 'لم يتم تسجيل أي عمليات سحب مالي بعد.',
              icon: Icons.account_balance_wallet_outlined,
            );
          }

          final total = provider.withdrawals.fold<double>(0, (s, w) => s + w.amount);

          return Column(
            children: [
              // Summary Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إجمالي السحوبات', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${total.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Icon(Icons.account_balance, color: Colors.white30, size: 40),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث في السحوبات...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: filteredWithdrawals.isEmpty && _searchQuery.isNotEmpty
                  ? const Center(child: Text('لا توجد نتائج'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredWithdrawals.length,
                      itemBuilder: (context, index) {
                        final w = filteredWithdrawals[index];
                        final partnerName = w.partnerId == null
                            ? 'عامل / مصروف عام'
                            : partnerProvider.partners.where((p) => p.id == w.partnerId).map((p) => p.name).firstOrNull ?? 'شريك (محذوف)';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: w.partnerId != null ? Colors.blue.shade50 : Colors.orange.shade50, 
                                child: Icon(w.partnerId != null ? Icons.person : Icons.engineering, color: w.partnerId != null ? Colors.blue : Colors.orange)
                            ),
                            title: Text(partnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${DateFormat('yyyy-MM-dd').format(DateTime.parse(w.date))} \n${w.notes ?? ""}'),
                            trailing: Text('${w.amount.toStringAsFixed(0)} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            onLongPress: () {
                              DialogUtils.showConfirmDelete(context, () => provider.deleteWithdrawal(w.id!));
                            },
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
