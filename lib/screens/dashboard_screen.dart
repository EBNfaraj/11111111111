import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/accounting_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/backup_service.dart';
import '../core/database/database_helper.dart';
import 'partners_screen.dart';
import 'houses_screen.dart';
import 'trucks_screen.dart';
import 'irrigation_screen.dart';
import 'financials_screen.dart';
import 'reports_screen.dart';
import 'about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AccountingProvider>().calculateDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة تحكم البئر', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<AccountingProvider>().calculateDashboard();
            },
          )
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer<AccountingProvider>(
        builder: (context, accounting, child) {
          if (accounting.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              await accounting.calculateDashboard();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCurvedHeader(context, accounting),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _buildSummaryCards(context, accounting),
                        const SizedBox(height: 24),
                        _buildRevenueChart(context, accounting),
                        const SizedBox(height: 24),
                        _buildQuickAccessGrid(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context, AccountingProvider accounting) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        height: 280,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'إجمالي الأرباح الصافية',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${accounting.netProfit.toStringAsFixed(0)} ر.ي',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  'نظام إدارة البئر',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group, color: AppTheme.primaryColor),
            title: const Text('الشركاء'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_work, color: AppTheme.primaryColor),
            title: const Text('البيوت والعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HousesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: AppTheme.primaryColor),
            title: const Text('مبيعات الوايتات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrucksScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.grass, color: AppTheme.primaryColor),
            title: const Text('سقي المزارع'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IrrigationScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
            title: const Text('المالية والمصروفات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart, color: AppTheme.primaryColor),
            title: const Text('توزيع الأرباح والتقارير'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
            title: const Text('حول البرنامج'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('النسخ والمزامنة', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('أخذ نسخة احتياطية'),
            onTap: () async {
              Navigator.pop(context);
              await BackupService.backupDatabase(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text('استعادة نسخة احتياطية'),
            onTap: () async {
              Navigator.pop(context);
              await BackupService.restoreDatabase(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف جميع البيانات', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showClearDataDialog(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع البيانات؟'),
        content: const Text('سيتم حذف كافة البيانات المسجلة نهائياً (الشركاء، المبيعات، المالية). هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              if (!mounted) return;
              Navigator.pop(ctx);
              context.read<AccountingProvider>().calculateDashboard();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف جميع البيانات بنجاح')));
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AccountingProvider accounting) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'الإيرادات',
            amount: accounting.totalRevenue,
            icon: Icons.monetization_on_outlined,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'المصروفات',
            amount: accounting.totalExpenses,
            icon: Icons.money_off_csred_outlined,
            color: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context, AccountingProvider accounting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('مصادر الدخل', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (accounting.totalRevenue > 0 ? accounting.totalRevenue : 1000) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0: return const Text('بيوت');
                            case 1: return const Text('وايتات');
                            case 2: return const Text('ري');
                            default: return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: accounting.totalHouseRevenue, color: AppTheme.primaryColor, width: 25, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: accounting.totalTruckRevenue, color: AppTheme.secondaryColor, width: 25, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: accounting.totalIrrigationRevenue, color: AppTheme.primaryLight, width: 25, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('وصول سريع', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _QuickAccessCard(
              title: 'الشركاء',
              icon: Icons.group_outlined,
              color: const Color(0xFF673AB7),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnersScreen())),
            ),
            _QuickAccessCard(
              title: 'البيوت',
              icon: Icons.home_work_outlined,
              color: const Color(0xFF009688),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HousesScreen())),
            ),
            _QuickAccessCard(
              title: 'الوايتات',
              icon: Icons.local_shipping_outlined,
              color: const Color(0xFFFF9800),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrucksScreen())),
            ),
            _QuickAccessCard(
              title: 'المزارع',
              icon: Icons.grass_outlined,
              color: const Color(0xFF4CAF50),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IrrigationScreen())),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                '${amount.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(size.width * 3 / 4, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
