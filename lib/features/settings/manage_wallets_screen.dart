import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/finance_repository.dart';

/// Halaman Pengelolaan Dompet / Rekening
class ManageWalletsScreen extends StatelessWidget {
  const ManageWalletsScreen({super.key});

  void _showAddEditWalletDialog(BuildContext context, {WalletModel? wallet}) {
    final repo = context.read<FinanceRepository>();
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final balanceController =
        TextEditingController(text: wallet?.initialBalance.toStringAsFixed(0) ?? '0');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(wallet == null ? 'Tambah Dompet' : 'Edit Dompet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Misal: BCA, GoPay, Tunai Dompet',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0.0;
                if (name.isEmpty) return;

                if (wallet == null) {
                  await repo.addWallet(name, balance);
                } else {
                  await repo.updateWallet(wallet.id!, name, balance);
                }

                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteWallet(BuildContext context, WalletModel wallet) {
    final repo = context.read<FinanceRepository>();
    if (repo.wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 dompet aktif.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Dompet?'),
          content: Text(
            'Apakah kamu yakin ingin menghapus dompet "${wallet.name}"? Semua transaksi yang terkait dengan dompet ini juga akan terhapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await repo.deleteWallet(wallet.id!);
                if (ctx.mounted) Navigator.of(ctx).pop();
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
    final repo = context.watch<FinanceRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dompet & Rekening'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: repo.wallets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final wallet = repo.wallets[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.account_balance_wallet, color: Color(0xFF0284C7)),
              ),
              title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Saldo Saat Ini: ${CurrencyFormat.toRupiah(wallet.currentBalance)}\n'
                'Saldo Awal: ${CurrencyFormat.toRupiah(wallet.initialBalance)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showAddEditWalletDialog(context, wallet: wallet),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDeleteWallet(context, wallet),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditWalletDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
