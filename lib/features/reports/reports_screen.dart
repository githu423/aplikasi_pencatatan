import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, custom }

/// Halaman Laporan Keuangan, Grafik Statistik, dan Ekspor PDF/CSV
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.monthly;
  DateTimeRange? _customRange;
  int _touchedPieIndex = -1;

  // Ekspor ke format CSV
  Future<void> _exportCSV(List<TransactionModel> transactions, String periodLabel) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Tanggal,Jenis,Nominal,Dompet,Kategori,Judul,Catatan,Tag,Lokasi');

    for (final tx in transactions) {
      final line = [
        tx.id ?? '',
        DateHelper.formatDateTime(tx.dateTime),
        tx.type == 'income'
            ? 'Pemasukan'
            : tx.type == 'savings_deposit'
                ? 'Setor Tabungan'
                : 'Pengeluaran',
        tx.amount.toStringAsFixed(0),
        '"${(tx.walletName ?? '').replaceAll('"', '""')}"',
        '"${(tx.categoryName ?? '').replaceAll('"', '""')}"',
        '"${tx.title.replaceAll('"', '""')}"',
        '"${(tx.notes ?? '').replaceAll('"', '""')}"',
        '"${(tx.tags ?? '').replaceAll('"', '""')}"',
        '"${(tx.location ?? '').replaceAll('"', '""')}"',
      ].join(',');
      buffer.writeln(line);
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Laporan_Keuangan_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan Keuangan ($periodLabel) dari Catatan Keuangan',
    );
  }

  // Ekspor ke Dokumen PDF Resmi Lengkap dengan Foto Bukti
  Future<void> _exportPDF(
    BuildContext context,
    List<TransactionModel> transactions,
    String periodLabel,
    double totalIncome,
    double totalExpense,
  ) async {
    final pdf = pw.Document();
    final net = totalIncome - totalExpense;

    // Baca foto-foto transaksi yang ada untuk disertakan ke PDF
    final List<Map<String, dynamic>> txWithImages = [];
    for (final tx in transactions) {
      final List<pw.MemoryImage> images = [];
      for (final p in tx.photos) {
        final f = File(p.filePath);
        if (await f.exists()) {
          try {
            final bytes = await f.readAsBytes();
            images.add(pw.MemoryImage(bytes));
          } catch (_) {}
        }
      }
      txWithImages.add({'tx': tx, 'images': images});
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Laporan Catatan Keuangan',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Periode: $periodLabel', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Text(
                  DateHelper.formatShort(DateTime.now()),
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 12),

            // Ringkasan Keuangan
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Total Pemasukan', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      CurrencyFormat.toRupiah(totalIncome),
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                    ),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Pengeluaran', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      CurrencyFormat.toRupiah(totalExpense),
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
                    ),
                  ]),
                  pw.Column(children: [
                    pw.Text('Selisih Bersih', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${net >= 0 ? "+" : ""}${CurrencyFormat.toRupiah(net)}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: net >= 0 ? PdfColors.blue700 : PdfColors.red700,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Daftar Transaksi Lengkap',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Jenis', 'Kategori', 'Dompet', 'Judul / Keterangan', 'Nominal'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              data: transactions.map((tx) {
                final isInc = tx.type == 'income';
                final isSav = tx.type == 'savings_deposit';
                return [
                  DateHelper.formatDateTime(tx.dateTime),
                  isInc ? 'Pemasukan' : isSav ? 'Tabungan' : 'Pengeluaran',
                  tx.categoryName ?? '-',
                  tx.walletName ?? 'Tunai',
                  tx.title,
                  '${isInc ? "+" : isSav ? "→" : "-"}${CurrencyFormat.toRupiah(tx.amount)}',
                ];
              }).toList(),
            ),

            // Lampiran Foto Bukti
            if (txWithImages.any((item) => (item['images'] as List).isNotEmpty)) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Lampiran Foto Bukti Transaksi',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              ...txWithImages.where((item) => (item['images'] as List).isNotEmpty).map((item) {
                final tx = item['tx'] as TransactionModel;
                final images = item['images'] as List<pw.MemoryImage>;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${tx.title} - ${CurrencyFormat.toRupiah(tx.amount)} (${DateHelper.formatDateTime(tx.dateTime)})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: images.map((img) {
                          return pw.Container(
                            width: 120,
                            height: 120,
                            child: pw.Image(img, fit: pw.BoxFit.cover),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Laporan_Catatan_Keuangan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<FinanceRepository>();

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    DateTime prevStartDate;
    DateTime prevEndDate;
    String periodLabel;

    switch (_period) {
      case ReportPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStartDate = startDate.subtract(const Duration(days: 1));
        prevEndDate = endDate.subtract(const Duration(days: 1));
        periodLabel = 'Hari Ini (${DateHelper.formatShort(now)})';
        break;
      case ReportPeriod.weekly:
        final weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day - (weekday - 1));
        endDate = DateTime(now.year, now.month, now.day + (7 - weekday), 23, 59, 59);
        prevStartDate = startDate.subtract(const Duration(days: 7));
        prevEndDate = endDate.subtract(const Duration(days: 7));
        periodLabel = 'Minggu Ini (${DateHelper.formatShort(startDate)} - ${DateHelper.formatShort(endDate)})';
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        prevStartDate = DateTime(now.year, now.month - 1, 1);
        prevEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        periodLabel = DateHelper.formatMonthYear(now);
        break;
      case ReportPeriod.yearly:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        prevStartDate = DateTime(now.year - 1, 1, 1);
        prevEndDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        periodLabel = 'Tahun ${now.year}';
        break;
      case ReportPeriod.custom:
        if (_customRange != null) {
          startDate = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
          endDate = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59);
          final diff = endDate.difference(startDate);
          prevStartDate = startDate.subtract(diff);
          prevEndDate = startDate.subtract(const Duration(seconds: 1));
          periodLabel = '${DateHelper.formatShort(startDate)} - ${DateHelper.formatShort(endDate)}';
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          prevStartDate = DateTime(now.year, now.month - 1, 1);
          prevEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          periodLabel = 'Rentang Kustom';
        }
        break;
    }

    // Filter transaksi untuk periode saat ini
    final currentPeriodTransactions = repo.transactions.where((t) {
      return !t.dateTime.isBefore(startDate) && !t.dateTime.isAfter(endDate);
    }).toList();

    // Filter transaksi untuk periode sebelumnya (untuk perbandingan)
    final prevPeriodTransactions = repo.transactions.where((t) {
      return !t.dateTime.isBefore(prevStartDate) && !t.dateTime.isAfter(prevEndDate);
    }).toList();

    // Kalkulasi Total
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryExpenseMap = {};
    final Map<String, Color> categoryColorMap = {};

    for (final tx in currentPeriodTransactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
        final catName = tx.categoryName ?? 'Lainnya';
        categoryExpenseMap[catName] = (categoryExpenseMap[catName] ?? 0.0) + tx.amount;
        if (tx.categoryColorValue != null) {
          categoryColorMap[catName] = Color(tx.categoryColorValue!);
        } else {
          categoryColorMap[catName] = Colors.teal;
        }
      }
    }

    final double netBalance = totalIncome - totalExpense;

    // Kalkulasi Periode Sebelumnya
    double prevExpense = 0;
    for (final tx in prevPeriodTransactions) {
      if (tx.type == 'expense') prevExpense += tx.amount;
    }

    double expenseChangePercent = 0;
    if (prevExpense > 0) {
      expenseChangePercent = ((totalExpense - prevExpense) / prevExpense) * 100;
    }

    // Cari Kategori Terbesar
    String topCategoryName = '-';
    double topCategoryAmount = 0;
    categoryExpenseMap.forEach((k, v) {
      if (v > topCategoryAmount) {
        topCategoryAmount = v;
        topCategoryName = k;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Statistik'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Ekspor Laporan',
            onSelected: (val) {
              if (val == 'pdf') {
                _exportPDF(context, currentPeriodTransactions, periodLabel, totalIncome, totalExpense);
              } else if (val == 'csv') {
                _exportCSV(currentPeriodTransactions, periodLabel);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Ekspor ke Dokumen PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text('Ekspor ke Lembar Kerja CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilihan Rentang Waktu
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip(ReportPeriod.daily, 'Harian'),
                  _buildPeriodChip(ReportPeriod.weekly, 'Mingguan'),
                  _buildPeriodChip(ReportPeriod.monthly, 'Bulanan'),
                  _buildPeriodChip(ReportPeriod.yearly, 'Tahunan'),
                  ChoiceChip(
                    label: Text(_period == ReportPeriod.custom && _customRange != null
                        ? '${DateHelper.formatShort(_customRange!.start)} - ${DateHelper.formatShort(_customRange!.end)}'
                        : 'Kustom'),
                    selected: _period == ReportPeriod.custom,
                    onSelected: (val) async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('id', 'ID'),
                      );
                      if (picked != null) {
                        setState(() {
                          _period = ReportPeriod.custom;
                          _customRange = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Ringkasan Periode
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Text(
                      periodLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Pemasukan',
                            CurrencyFormat.toRupiah(totalIncome),
                            const Color(0xFF10B981),
                            Icons.arrow_downward,
                          ),
                        ),
                        Container(height: 40, width: 1, color: Colors.grey.shade300),
                        Expanded(
                          child: _buildSummaryItem(
                            'Pengeluaran',
                            CurrencyFormat.toRupiah(totalExpense),
                            const Color(0xFFEF4444),
                            Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Selisih Bersih:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${netBalance >= 0 ? "+" : ""}${CurrencyFormat.toRupiah(netBalance)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: netBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Kartu Perbandingan Periode & Kategori Terbesar
            Row(
              children: [
                // Perbandingan Periode
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vs Periode Lalu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                expenseChangePercent > 0
                                    ? Icons.trending_up
                                    : expenseChangePercent < 0
                                        ? Icons.trending_down
                                        : Icons.trending_flat,
                                size: 18,
                                color: expenseChangePercent > 0 ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${expenseChangePercent >= 0 ? "+" : ""}${expenseChangePercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: expenseChangePercent > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prevExpense > 0
                                ? 'Lalu: ${CurrencyFormat.toCompactRupiah(prevExpense)}'
                                : 'Belum ada data',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Kategori Terbesar
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kategori Terbesar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            topCategoryName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topCategoryAmount > 0
                                ? CurrencyFormat.toRupiah(topCategoryAmount)
                                : 'Rp 0',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grafik Donat Pengeluaran per Kategori
            if (categoryExpenseMap.isNotEmpty) ...[
              const Text(
                'Proporsi Pengeluaran per Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex =
                                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieSections(categoryExpenseMap, categoryColorMap, totalExpense),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Legenda Kategori
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: categoryExpenseMap.entries.map((entry) {
                          final color = categoryColorMap[entry.key] ?? Colors.grey;
                          final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${entry.key} (${pct.toStringAsFixed(1)}%)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Center(
                    child: Text(
                      'Belum ada data pengeluaran pada periode ini.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(ReportPeriod period, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _period == period,
        onSelected: (val) {
          if (val) {
            setState(() {
              _period = period;
            });
          }
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> data,
    Map<String, Color> colorMap,
    double total,
  ) {
    int i = 0;
    return data.entries.map((entry) {
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final color = colorMap[entry.key] ?? Colors.teal;
      final pct = total > 0 ? (entry.value / total) * 100 : 0.0;
      i++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
