import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'screens/splash_screen.dart';

import 'providers/partner_provider.dart';
import 'providers/house_provider.dart';
import 'providers/truck_sale_provider.dart';
import 'providers/irrigation_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/withdrawal_provider.dart';
import 'providers/accounting_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Database Helper to preload the SQLite DB
  if (!kIsWeb) {
    try {
      await DatabaseHelper.instance.database;
    } catch (e) {
      debugPrint('DB Init Error: $e');
    }
  }

  runApp(const WaterWellApp());
}

class WaterWellApp extends StatelessWidget {
  const WaterWellApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PartnerProvider()..fetchPartners()),
        ChangeNotifierProvider(create: (_) => HouseProvider()..fetchHouses()),
        ChangeNotifierProvider(create: (_) => TruckSaleProvider()..fetchSales()),
        ChangeNotifierProvider(create: (_) => IrrigationProvider()..fetchIrrigations()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..fetchExpenses()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()..fetchWithdrawals()),
        ChangeNotifierProvider(create: (_) => AccountingProvider()..calculateDashboard()),
      ],
      child: MaterialApp(
        title: 'إدارة بئر ماء',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        
        // RTL Support
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'SA'), // Arabic
        ],
        locale: const Locale('ar', 'SA'),

        home: const SplashScreen(),
      ),
    );
  }
}
