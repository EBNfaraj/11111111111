import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/partner_provider.dart';
import '../models/partner.dart';
import '../core/utils/dialog_utils.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/theme/app_theme.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({Key? key}) : super(key: key);

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PartnerProvider>().fetchPartners();
    });
  }

  void _showPartnerDialog(BuildContext context, [Partner? partner]) {
    final nameController = TextEditingController(text: partner?.name);
    final percentageController = TextEditingController(text: partner?.sharePercentage.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(partner == null ? 'إضافة شريك جديد' : 'تعديل بيانات الشريك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الشريك'),
            ),
            TextField(
              controller: percentageController,
              decoration: const InputDecoration(labelText: 'نسبة الملكية (%)'),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final percentage = double.tryParse(percentageController.text.trim()) ?? 0.0;
              
              if (name.isEmpty || percentage <= 0) {
                DialogUtils.showErrorSnackbar(context, 'الرجاء إدخال بيانات صحيحة');
                return;
              }
              final newPartner = Partner(
                id: partner?.id,
                name: name,
                sharePercentage: percentage,
                isActive: true,
              );

              if (partner == null) {
                await context.read<PartnerProvider>().addPartner(newPartner);
              } else {
                await context.read<PartnerProvider>().updatePartner(newPartner);
              }
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الشركاء'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPartnerDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<PartnerProvider>(
        builder: (context, provider, child) {
          final filteredPartners = provider.partners.where((p) => p.name.contains(_searchQuery)).toList();

          if (provider.partners.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا يوجد شركاء',
              message: 'قم بإضافة شريك جديد بالضغط على زر الإضافة بالأسفل لتبدأ بتسجيل الحصص والنسب.',
              icon: Icons.group_add_outlined,
            );
          }

          // Calculate total share percentage
          final totalShare = provider.partners.fold<double>(0, (sum, p) => sum + p.sharePercentage);
          final isBalanced = (totalShare - 100.0).abs() < 0.001;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن شريك...',
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
              // Share % Indicator Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isBalanced ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBalanced ? Colors.green.shade300 : Colors.orange.shade400,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBalanced ? Icons.check_circle : Icons.warning_amber,
                          color: isBalanced ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBalanced ? 'مجموع النسب متوازن (١٠٠%)' : 'تحذير: النسب غير متوازنة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBalanced ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'مجموع النسب: ${totalShare.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBalanced ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              // ── List ──
              Expanded(
                child: filteredPartners.isEmpty && _searchQuery.isNotEmpty
                  ? const Center(child: Text('لا توجد نتائج للبحث'))
                  : ListView.builder(
                      itemCount: filteredPartners.length,
                      itemBuilder: (context, index) {
                        final p = filteredPartners[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(p.name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('نسبة الملكية: ${p.sharePercentage}%'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showPartnerDialog(context, p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    DialogUtils.showConfirmDelete(context, () {
                                      provider.deletePartner(p.id!);
                                    });
                                  },
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
}
