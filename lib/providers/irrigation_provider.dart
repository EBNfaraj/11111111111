import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/irrigation.dart';

class IrrigationProvider with ChangeNotifier {
  List<Irrigation> _irrigations = [];
  bool _isLoading = false;

  List<Irrigation> get irrigations => _irrigations;
  bool get isLoading => _isLoading;

  Future<void> fetchIrrigations() async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('irrigations', orderBy: 'date DESC');
    _irrigations = result.map((json) => Irrigation.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addIrrigation(Irrigation irrigation) async {
    if (kIsWeb) {
      _irrigations.insert(0, irrigation);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('irrigations', irrigation.toMap());
    await fetchIrrigations();
  }

  Future<void> deleteIrrigation(int id) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('irrigations', where: 'id = ?', whereArgs: [id]);
    await fetchIrrigations();
  }
}
