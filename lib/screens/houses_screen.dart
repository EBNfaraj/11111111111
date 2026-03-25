import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';
import '../models/house.dart';
import 'meter_readings_screen.dart';
import '../core/utils/dialog_utils.dart';
import '../core/widgets/empty_state_widget.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({Key? key}) : super(key: key);

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HouseProvider>().fetchHouses();
    });
  }

  void _showHouseDialog(BuildContext context, [House? house]) {
    final ownerController = TextEditingController(text: house?.ownerName);
    final meterController = TextEditingController(text: house?.meterNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(house == null ? 'إضافة بيت جديد' : 'تعديل بيانات البيت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ownerController,
              decoration: const InputDecoration(labelText: 'اسم صاحب البيت'),
            ),
            TextField(
              controller: meterController,
              decoration: const InputDecoration(labelText: 'رقم العداد (اختياري)'),
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
              final owner = ownerController.text.trim();
              if (owner.isEmpty) {
                DialogUtils.showErrorSnackbar(context, 'الرجاء إدخال اسم صاحب البيت');
                return;
              }

              final newHouse = House(
                id: house?.id,
                ownerName: owner,
                meterNumber: meterController.text.trim(),
              );

              if (house == null) {
                await context.read<HouseProvider>().addHouse(newHouse);
              } else {
                await context.read<HouseProvider>().updateHouse(newHouse);
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
        title: const Text('إدارة البيوت والعدادات'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHouseDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<HouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredHouses = provider.houses.where((h) => 
            h.ownerName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            (h.meterNumber != null && h.meterNumber!.toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

          if (provider.houses.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد بيوت',
              message: 'لم تقم بتسجيل أي منزل أو مزرعة بعد. استخدم زر الإضافة لتسجيل عدادات استهلاك المياه.',
              icon: Icons.home_work_outlined,
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
                    hintText: 'ابحث عن بيت أو رقم عداد...',
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
                child: filteredHouses.isEmpty && _searchQuery.isNotEmpty
                    ? const Center(child: Text('لا توجد نتائج للبحث'))
                    : ListView.builder(
                        itemCount: filteredHouses.length,
                        itemBuilder: (context, index) {
                          final house = filteredHouses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.home, color: Colors.blue, size: 30),
                              title: Text(house.ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('العداد: ${house.meterNumber ?? "غير مسجل"}'),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MeterReadingsScreen(house: house),
                                  ),
                                );
                              },
                              onLongPress: () => _showHouseDialog(context, house),
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
