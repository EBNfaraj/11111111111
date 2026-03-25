import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    _expenses = result.map((json) => Expense.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    if (kIsWeb) {
      _expenses.insert(0, expense);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('expenses', expense.toMap());
    await fetchExpenses();
  }

  Future<void> deleteExpense(int id) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await fetchExpenses();
  }
}
