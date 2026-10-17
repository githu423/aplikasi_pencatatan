import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/app_mascot.dart';
import '../../widgets/empty_state.dart';
import '../birthday/birthday_manager.dart';
import '../birthday/birthday_mascot_widget.dart';
import '../birthday/candle_blowing_screen.dart';
import '../reports/reports_screen.dart';
import '../savings/savings_screen.dart';
import '../savings/target_reached_dialog.dart';
import '../settings/settings_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import '../transactions/transaction_form_screen.dart';
import '../transactions/transaction_history_screen.dart';

/// Halaman Utama Navigasi (5 Tab) & Tampilan Dashboard
class DashboardScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;

  const DashboardScreen({super.key, this.onThemeModeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isTrend30Days = false; // toggle 7 hari vs 30 hari

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTargetReachedDialog();
    });
  }

  void _checkTargetReachedDialog() {
    final repo = context.read<FinanceRepository>();
    if (repo.pendingReachedTarget != null) {
      TargetReachedDialog.show(context, repo.pendingReachedTarget!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();

    // Listener otomatis jika transaksi baru memicu target tercapai
    if (repo.pendingReachedTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTargetReachedDialog();
      });
    }

    final pages = [
      _buildDashboardHome(context),
      const TransactionHistoryScreen(),
      const SizedBox.shrink(), // Placeholder untuk tombol tengah (+)
      const ReportsScreen(),
      SettingsScreen(
        onThemeModeChanged: widget.onThemeModeChanged ?? (_) {},
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          pages[_currentIndex == 2 ? 0 : _currentIndex],
          // Maskot mengambang di pojok layar jika hari ini ulang tahun
          const BirthdayMascotCornerWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            // Tombol tambah cepat di tengah
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionFormScreen(),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF0D9488),
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
            label: 'Tambah',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<FinanceRepository>();
    final bday = context.watch<BirthdayManager>();

    final profile = repo.profile;
    final target = repo.activeSavingsTarget;
    final recentTxs = repo.recentTransactions;

    // Hitung pengeluaran per kategori bulan ini untuk grafik donat
    final now = DateTime.now();
    final thisMonthExpenses = repo.transactions.where((t) =>
        t.type == 'expense' &&
        t.dateTime.year == now.year &&
        t.dateTime.month == now.month).toList();

    final Map<String, double> catExpenseMap = {};
    final Map<String, Color> catColorMap = {};
    for (final tx in thisMonthExpenses) {
      final name = tx.categoryName ?? 'Lainnya';
      catExpenseMap[name] = (catExpenseMap[name] ?? 0.0) + tx.amount;
      if (tx.categoryColorValue != null) {
        catColorMap[name] = Color(tx.categoryColorValue!);
      } else {
        catColorMap[name] = theme.colorScheme.primary;
      }
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await repo.initialize();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil & Maskot Teman di Hari Biasa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${profile?.name ?? "Pengguna"} 👋',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateHelper.formatDayAndDate(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),

                  // Maskot Teman di Hari Biasa (Hitung Mundur Ulang Tahun)
                  if (!bday.isBirthdayToday)
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🎂 ${bday.daysUntilBirthday} hari lagi menuju ulang tahunmu!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${bday.daysUntilBirthday} hr lagi 🎂',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const AppMascot(size: 40, mood: MascotMood.normal),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Banner Ulang Tahun Hari H
              if (bday.isBirthdayToday) ...[
                Card(
                  elevation: 2,
                  color: const Color(0xFFFDF2F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF472B6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const AppMascot(
                          size: 56,
                          mood: MascotMood.celebrating,
                          isDancing: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Ulang Tahun ke-${bday.currentAge}, ${profile?.name}!',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9D174D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bday.currentGreeting,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFBE185D)),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CandleBlowingScreen(
                                        userName: profile?.name ?? 'Kawan',
                                        age: bday.currentAge,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '🎂 Tiup Lilin Kue Ulang Tahun →',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9D174D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Kartu Saldo Besar
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saldo Bebas',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormat.toRupiah(repo.totalBalance),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFF10B981),
                                    child: Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pemasukan', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                      Text(
                                        CurrencyFormat.toCompactRupiah(repo.monthlyIncome),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 24, width: 1, color: Colors.white24),
                            Expanded(
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFFEF4444),
                                    child: Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                      Text(
                                        CurrencyFormat.toCompactRupiah(repo.monthlyExpense),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Kartu Progress Target Tabungan
              if (target != null)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SavingsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.savings_outlined, color: Color(0xFF8B5CF6), size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    target.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Text(
                                '${target.progressPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (target.progressPercentage / 100.0).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.15),
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${CurrencyFormat.toRupiah(target.currentAmount)} dari ${CurrencyFormat.toRupiah(target.targetAmount)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const Text(
                                'Kelola →',
                                style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Grafik Donat Pengeluaran Bulan Ini
              if (catExpenseMap.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pengeluaran Bulan Ini',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormat.toRupiah(repo.monthlyExpense),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: PieChart(
                            PieChartData(
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 36,
                              sections: catExpenseMap.entries.map((entry) {
                                final color = catColorMap[entry.key] ?? Colors.teal;
                                final pct = repo.monthlyExpense > 0
                                    ? (entry.value / repo.monthlyExpense) * 100
                                    : 0.0;
                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value,
                                  title: '${pct.toStringAsFixed(0)}%',
                                  radius: 40,
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: catExpenseMap.entries.map((entry) {
                            final color = catColorMap[entry.key] ?? Colors.teal;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(entry.key, style: const TextStyle(fontSize: 11)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Grafik Tren 7 atau 30 Hari
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tren Pengeluaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _buildTrendToggleChip('7 Hari', !_isTrend30Days, () {
                        setState(() => _isTrend30Days = false);
                      }),
                      const SizedBox(width: 6),
                      _buildTrendToggleChip('30 Hari', _isTrend30Days, () {
                        setState(() => _isTrend30Days = true);
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 18, top: 18, bottom: 12),
                  child: SizedBox(
                    height: 170,
                    child: _buildTrendChart(repo.transactions, _isTrend30Days ? 30 : 7),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5 Transaksi Terakhir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terakhir',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 1; // Pindah ke tab Riwayat
                      });
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (recentTxs.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum Ada Transaksi',
                  message: 'Tekan tombol (+) di bawah untuk mencatat transaksi pertamamu.',
                )
              else
                ...recentTxs.map((tx) => _buildRecentTxItem(context, tx)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<TransactionModel> transactions, int daysCount) {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    double maxY = 10000;

    for (int i = daysCount - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayTxs = transactions.where((t) =>
          t.type == 'expense' &&
          t.dateTime.year == day.year &&
          t.dateTime.month == day.month &&
          t.dateTime.day == day.day);

      final total = dayTxs.fold(0.0, (sum, item) => sum + item.amount);
      if (total > maxY) maxY = total;

      barGroups.add(
        BarChartGroupData(
          x: daysCount - 1 - i,
          barRods: [
            BarChartRodData(
              toY: total,
              color: const Color(0xFFEF4444),
              width: daysCount > 15 ? 4 : 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                CurrencyFormat.toCompactRupiah(rod.toY),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                return Text(
                  CurrencyFormat.toCompactRupiah(val),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: daysCount <= 7,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                final day = now.subtract(Duration(days: (daysCount - 1) - idx));
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${day.day}/${day.month}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 3).clamp(1.0, double.infinity),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildRecentTxItem(BuildContext context, TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final isSavings = tx.type == 'savings_deposit';
    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : isSavings
            ? const Color(0xFF8B5CF6)
            : const Color(0xFFEF4444);

    final iconData = tx.categoryIconCode != null
        ? IconData(tx.categoryIconCode!, fontFamily: 'MaterialIcons')
        : (isIncome ? Icons.call_received : Icons.call_made);

    final iconColor = tx.categoryColorValue != null ? Color(tx.categoryColorValue!) : amountColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: tx),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${DateHelper.formatShort(tx.dateTime)} • ${tx.walletName ?? "Tunai"}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? "+" : isSavings ? "→" : "-"}${CurrencyFormat.toRupiah(tx.amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ),
    );
  }
}
