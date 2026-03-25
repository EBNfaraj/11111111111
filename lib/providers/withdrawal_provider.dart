import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/withdrawal.dart';

class WithdrawalProvider with ChangeNotifier {
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = false;

  List<Withdrawal> get withdrawals => _withdrawals;
  bool get isLoading => _isLoading;

  Future<void> fetchWithdrawals() async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('withdrawals', orderBy: 'date DESC');
    _withdrawals = result.map((json) => Withdrawal.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWithdrawal(Withdrawal withdrawal) async {
    if (kIsWeb) {
      _withdrawals.insert(0, withdrawal);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('withdrawals', withdrawal.toMap());
    await fetchWithdrawals();
  }

  Future<void> deleteWithdrawal(int id) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('withdrawals', where: 'id = ?', whereArgs: [id]);
    await fetchWithdrawals();
  }
}
