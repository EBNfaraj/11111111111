import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/truck_sale.dart';

class TruckSaleProvider with ChangeNotifier {
  List<TruckSale> _sales = [];
  bool _isLoading = false;

  List<TruckSale> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> fetchSales() async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('truck_sales', orderBy: 'date DESC');
    _sales = result.map((json) => TruckSale.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSale(TruckSale sale) async {
    if (kIsWeb) {
      _sales.insert(0, sale);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('truck_sales', sale.toMap());
    await fetchSales();
  }

  Future<void> deleteSale(int id) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('truck_sales', where: 'id = ?', whereArgs: [id]);
    await fetchSales();
  }
}
