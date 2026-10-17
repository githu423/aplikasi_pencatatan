import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/empty_state.dart';
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';

/// Halaman Riwayat Transaksi dengan Filter & Pencarian Lengkap
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'all'; // 'all', 'expense', 'income', 'savings_deposit'
  int? _selectedCategoryId;
  int? _selectedWalletId;
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    final repo = context.read<FinanceRepository>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Transaksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedType = 'all';
                            _selectedCategoryId = null;
                            _selectedWalletId = null;
                            _selectedDateRange = null;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Jenis Transaksi
                  const Text('Jenis Transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChoiceChip('all', 'Semua', _selectedType, (val) {
                        setModalState(() => _selectedType = val);
                      }),
                      _buildChoiceChip('expense', 'Pengeluaran', _selectedType, (val) {
                        setModalState(() => _selectedType = val);
                      }),
                      _buildChoiceChip('income', 'Pemasukan', _selectedType, (val) {
                        setModalState(() => _selectedType = val);
                      }),
                      _buildChoiceChip('savings_deposit', 'Setoran Tabungan', _selectedType, (val) {
                        setModalState(() => _selectedType = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dompet
                  const Text('Dompet / Rekening', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedWalletId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Dompet')),
                      ...repo.wallets.map((w) => DropdownMenuItem<int?>(
                            value: w.id,
                            child: Text(w.name),
                          )),
                    ],
                    onChanged: (val) => setModalState(() => _selectedWalletId = val),
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Kategori')),
                      ...repo.categories.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(c.icon, size: 18, color: c.color),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (val) => setModalState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Terapkan Filter'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip(
    String value,
    String label,
    String current,
    Function(String) onSelected,
  ) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final query = _searchController.text.trim().toLowerCase();

    // Terapkan Filter Transaksi
    final filtered = repo.transactions.where((tx) {
      // Filter Jenis
      if (_selectedType != 'all' && tx.type != _selectedType) return false;

      // Filter Dompet
      if (_selectedWalletId != null && tx.walletId != _selectedWalletId) return false;

      // Filter Kategori
      if (_selectedCategoryId != null && tx.categoryId != _selectedCategoryId) return false;

      // Filter Rentang Tanggal
      if (_selectedDateRange != null) {
        final txDate = DateTime(tx.dateTime.year, tx.dateTime.month, tx.dateTime.day);
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
      }

      // Filter Kata Kunci
      if (query.isNotEmpty) {
        final titleMatch = tx.title.toLowerCase().contains(query);
        final notesMatch = (tx.notes ?? '').toLowerCase().contains(query);
        final tagsMatch = (tx.tags ?? '').toLowerCase().contains(query);
        final locMatch = (tx.location ?? '').toLowerCase().contains(query);
        final catMatch = (tx.categoryName ?? '').toLowerCase().contains(query);
        if (!titleMatch && !notesMatch && !tagsMatch && !locMatch && !catMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Kelompokkan Transaksi Berdasarkan Tanggal (Hari)
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(tx.dateTime);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_outlined),
                if (_selectedType != 'all' ||
                    _selectedCategoryId != null ||
                    _selectedWalletId != null ||
                    _selectedDateRange != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter',
            onPressed: () => _showFilterModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bar Pencarian & Filter Cepat Tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _pickDateRange(context),
                  icon: Icon(
                    _selectedDateRange != null ? Icons.event_available : Icons.date_range,
                    color: _selectedDateRange != null ? Theme.of(context).colorScheme.primary : null,
                  ),
                  tooltip: 'Pilih Rentang Tanggal',
                ),
              ],
            ),
          ),

          // Tanda Filter Aktif jika ada
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      '${DateHelper.formatShort(_selectedDateRange!.start)} - ${DateHelper.formatShort(_selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => setState(() => _selectedDateRange = null),
                  ),
                ],
              ),
            ),

          // Daftar Transaksi Terkelompok
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.search_off_outlined,
                    title: 'Tidak Ada Transaksi',
                    message: query.isNotEmpty ||
                            _selectedType != 'all' ||
                            _selectedCategoryId != null ||
                            _selectedWalletId != null ||
                            _selectedDateRange != null
                        ? 'Tidak ada transaksi yang cocok dengan kriteria filter yang dipilih.'
                        : 'Belum ada transaksi, yuk catat yang pertama!',
                    actionLabel: query.isEmpty && _selectedType == 'all'
                        ? 'Catat Transaksi'
                        : null,
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransactionFormScreen(),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDates[index];
                      final items = grouped[dateKey]!;
                      final date = DateTime.parse(dateKey);

                      // Hitung total pemasukan dan pengeluaran hari tersebut
                      double dayIncome = 0;
                      double dayExpense = 0;
                      for (final item in items) {
                        if (item.type == 'income') {
                          dayIncome += item.amount;
                        } else if (item.type == 'expense') {
                          dayExpense += item.amount;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Tanggal
                          Padding(
                            padding: const EdgeInsets.only(top: 14.0, bottom: 6.0, left: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateHelper.formatDayAndDate(date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (dayIncome > 0)
                                      Text(
                                        '+${CurrencyFormat.toCompactRupiah(dayIncome)} ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    if (dayExpense > 0)
                                      Text(
                                        '-${CurrencyFormat.toCompactRupiah(dayExpense)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Kartu Transaksi di hari tersebut
                          ...items.map((tx) => _buildTransactionCard(context, tx)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final isSavings = tx.type == 'savings_deposit';
    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : isSavings
            ? const Color(0xFF8B5CF6)
            : const Color(0xFFEF4444);

    final iconData = tx.categoryIconCode != null
        ? IconData(tx.categoryIconCode!, fontFamily: 'MaterialIcons')
        : (isIncome
            ? Icons.call_received
            : isSavings
                ? Icons.savings_outlined
                : Icons.call_made);

    final iconColor = tx.categoryColorValue != null
        ? Color(tx.categoryColorValue!)
        : amountColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: tx),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(iconData, color: iconColor, size: 22),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              tx.walletName ?? 'Tunai',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (tx.categoryName != null) ...[
              Text(' • ', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              Flexible(
                child: Text(
                  tx.categoryName!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (tx.photos.isNotEmpty) ...[
              const SizedBox(width: 4),
              const Icon(Icons.attachment, size: 14, color: Colors.grey),
            ],
          ],
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
