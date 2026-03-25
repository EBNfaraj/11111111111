import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/partner.dart';

class PartnerProvider with ChangeNotifier {
  List<Partner> _partners = [];
  bool _isLoading = false;

  List<Partner> get partners => _partners;
  bool get isLoading => _isLoading;

  Future<void> fetchPartners() async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('partners');
    _partners = result.map((json) => Partner.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPartner(Partner partner) async {
    if (kIsWeb) {
      _partners.add(partner);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('partners', partner.toMap());
    await fetchPartners();
  }

  Future<void> updatePartner(Partner partner) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.update('partners', partner.toMap(), where: 'id = ?', whereArgs: [partner.id]);
    await fetchPartners();
  }

  Future<void> deletePartner(int id) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('partners', where: 'id = ?', whereArgs: [id]);
    await fetchPartners();
  }
}
