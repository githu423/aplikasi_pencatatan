import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/photo_viewer_dialog.dart';
import 'transaction_form_screen.dart';

/// Halaman Detail Lengkap Transaksi
class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: const Text(
            'Apakah kamu yakin ingin menghapus catatan transaksi ini beserta semua foto bukti terkait? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final repo = context.read<FinanceRepository>();
                await repo.deleteTransaction(transaction.id!);
                if (ctx.mounted) Navigator.of(ctx).pop(); // Tutup dialog
                if (context.mounted) Navigator.of(context).pop(); // Kembali dari detail
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<FinanceRepository>();

    // Ambil data transaksi terkini dari repository jika baru di-edit
    final currentTx = repo.transactions.firstWhere(
      (t) => t.id == transaction.id,
      orElse: () => transaction,
    );

    final isIncome = currentTx.type == 'income';
    final isSavings = currentTx.type == 'savings_deposit';
    final typeColor = isIncome
        ? const Color(0xFF10B981)
        : isSavings
            ? const Color(0xFF8B5CF6)
            : const Color(0xFFEF4444);

    final typeLabel = isIncome
        ? 'Pemasukan'
        : isSavings
            ? 'Setor Tabungan'
            : 'Pengeluaran';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Transaksi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TransactionFormScreen(initialTransaction: currentTx),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Transaksi',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Ringkasan Atas
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${isIncome ? "+" : isSavings ? "→" : "-"}${CurrencyFormat.toRupiah(currentTx.amount)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTx.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detail Info
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRowItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Waktu Transaksi',
                      value: DateHelper.formatDateTime(currentTx.dateTime),
                    ),
                    const Divider(),
                    _buildRowItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Dompet / Rekening',
                      value: currentTx.walletName ?? 'Tunai',
                    ),
                    if (currentTx.categoryName != null) ...[
                      const Divider(),
                      _buildRowItem(
                        icon: currentTx.categoryIconCode != null
                            ? IconData(currentTx.categoryIconCode!, fontFamily: 'MaterialIcons')
                            : Icons.category_outlined,
                        iconColor: currentTx.categoryColorValue != null
                            ? Color(currentTx.categoryColorValue!)
                            : null,
                        label: 'Kategori',
                        value: currentTx.categoryName!,
                      ),
                    ],
                    if (currentTx.location != null && currentTx.location!.isNotEmpty) ...[
                      const Divider(),
                      _buildRowItem(
                        icon: Icons.storefront_outlined,
                        label: 'Lokasi / Toko',
                        value: currentTx.location!,
                      ),
                    ],
                    if (currentTx.tags != null && currentTx.tags!.isNotEmpty) ...[
                      const Divider(),
                      _buildRowItem(
                        icon: Icons.label_outline,
                        label: 'Tag',
                        value: currentTx.tags!,
                      ),
                    ],
                    if (currentTx.notes != null && currentTx.notes!.isNotEmpty) ...[
                      const Divider(),
                      _buildRowItem(
                        icon: Icons.notes_outlined,
                        label: 'Catatan',
                        value: currentTx.notes!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Foto Bukti
            if (currentTx.photos.isNotEmpty) ...[
              const Text(
                'Foto Bukti / Struk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: currentTx.photos.length,
                itemBuilder: (context, index) {
                  final photo = currentTx.photos[index];
                  final file = File(photo.filePath);
                  return GestureDetector(
                    onTap: () => PhotoViewerDialog.show(context, photo.filePath),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: file.existsSync()
                          ? Image.file(file, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
