import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class PartnerProfit {
  final int partnerId;
  final String partnerName;
  final double sharePercentage;
  final double grossProfit; // Based on percentage
  final double totalWithdrawals;
  final double netOwed; // grossProfit - totalWithdrawals

  PartnerProfit({
    required this.partnerId,
    required this.partnerName,
    required this.sharePercentage,
    required this.grossProfit,
    required this.totalWithdrawals,
    required this.netOwed,
  });
}

class AccountingProvider with ChangeNotifier {
  double _totalHouseRevenue = 0;
  double _totalTruckRevenue = 0;
  double _totalIrrigationRevenue = 0;
  double _totalExpenses = 0;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  double get totalRevenue => _totalHouseRevenue + _totalTruckRevenue + _totalIrrigationRevenue;
  double get netProfit => totalRevenue - _totalExpenses;

  double get totalHouseRevenue => _totalHouseRevenue;
  double get totalTruckRevenue => _totalTruckRevenue;
  double get totalIrrigationRevenue => _totalIrrigationRevenue;
  double get totalExpenses => _totalExpenses;

  List<PartnerProfit> _partnerProfits = [];
  List<PartnerProfit> get partnerProfits => _partnerProfits;

  Future<void> calculateDashboard() async {
    _isLoading = true;
    notifyListeners();
    
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    final db = await DatabaseHelper.instance.database;

    // 1. House Revenues
    final houseQuery = await db.rawQuery('SELECT SUM(total_price) as total FROM meter_readings');
    _totalHouseRevenue = (houseQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Truck Revenues
    final truckQuery = await db.rawQuery('SELECT SUM(total_price) as total FROM truck_sales');
    _totalTruckRevenue = (truckQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Irrigation Revenues
    final irrigationQuery = await db.rawQuery('SELECT SUM(total_price) as total FROM irrigations');
    _totalIrrigationRevenue = (irrigationQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // 4. Expenses
    final expensesQuery = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    _totalExpenses = (expensesQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // 5. Partner Profits & Withdrawals
    final partners = await db.query('partners', where: 'is_active = 1');
    List<PartnerProfit> tempProfits = [];

    for (var partnerMap in partners) {
      final int partnerId = partnerMap['id'] as int;
      final String partnerName = partnerMap['name'] as String;
      final double sharePercentage = (partnerMap['share_percentage'] as num).toDouble();

      final withdrawQuery = await db.rawQuery('SELECT SUM(amount) as total FROM withdrawals WHERE partner_id = ?', [partnerId]);
      final double partnerWithdrawals = (withdrawQuery.first['total'] as num?)?.toDouble() ?? 0.0;

      final double partnerGrossProfit = netProfit * (sharePercentage / 100);
      final double partnerNetOwed = partnerGrossProfit - partnerWithdrawals;

      tempProfits.add(PartnerProfit(
        partnerId: partnerId,
        partnerName: partnerName,
        sharePercentage: sharePercentage,
        grossProfit: partnerGrossProfit,
        totalWithdrawals: partnerWithdrawals,
        netOwed: partnerNetOwed,
      ));
    }
    _partnerProfits = tempProfits;
    _isLoading = false;
    notifyListeners();
  }
}
