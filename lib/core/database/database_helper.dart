import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_well.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version for 'category' in expenses
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT "أخرى"');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
      CREATE TABLE partners (
        id $idType,
        name $textType,
        share_percentage $numType,
        is_active $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE houses (
        id $idType,
        owner_name $textType,
        meter_number TEXT,
        is_active $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE meter_readings (
        id $idType,
        house_id $intType,
        previous_reading $intType,
        current_reading $intType,
        price_per_unit $numType,
        consumption $numType,
        total_price $numType,
        date $textType,
        FOREIGN KEY (house_id) REFERENCES houses (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE truck_sales (
        id $idType,
        quantity $intType,
        price_per_truck $numType,
        total_price $numType,
        date $textType,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE irrigations (
        id $idType,
        date $textType,
        hours $numType,
        price_per_hour $numType,
        total_price $numType,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        category $textType,
        description TEXT,
        amount $numType,
        date $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE withdrawals (
        id $idType,
        partner_id INTEGER,
        amount $numType,
        date $textType,
        notes TEXT,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('withdrawals');
    await db.delete('expenses');
    await db.delete('irrigations');
    await db.delete('truck_sales');
    await db.delete('meter_readings');
    await db.delete('houses');
    await db.delete('partners');
  }
}
