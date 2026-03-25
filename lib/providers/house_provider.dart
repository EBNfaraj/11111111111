import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/house.dart';
import '../models/meter_reading.dart';

class HouseProvider with ChangeNotifier {
  List<House> _houses = [];
  List<MeterReading> _meterReadings = [];
  bool _isLoading = false;

  List<House> get houses => _houses;
  List<MeterReading> get meterReadings => _meterReadings;
  bool get isLoading => _isLoading;

  Future<void> fetchHouses() async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('houses');
    _houses = result.map((json) => House.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHouse(House house) async {
    if (kIsWeb) {
      _houses.add(house);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('houses', house.toMap());
    await fetchHouses();
  }

  Future<void> updateHouse(House house) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.update('houses', house.toMap(), where: 'id = ?', whereArgs: [house.id]);
    await fetchHouses();
  }

  Future<void> deleteHouse(int id) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('houses', where: 'id = ?', whereArgs: [id]);
    await fetchHouses();
  }

  // Meter Readings Logic
  Future<void> fetchMeterReadings(int houseId) async {
    _isLoading = true;
    notifyListeners();
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'meter_readings',
      where: 'house_id = ?',
      whereArgs: [houseId],
      orderBy: 'date DESC',
    );
    _meterReadings = result.map((json) => MeterReading.fromMap(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMeterReading(MeterReading reading) async {
    if (kIsWeb) {
      _meterReadings.insert(0, reading);
      notifyListeners();
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('meter_readings', reading.toMap());
    await fetchMeterReadings(reading.houseId);
  }

  Future<void> deleteMeterReading(int readingId, int houseId) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('meter_readings', where: 'id = ?', whereArgs: [readingId]);
    await fetchMeterReadings(houseId);
  }
}
