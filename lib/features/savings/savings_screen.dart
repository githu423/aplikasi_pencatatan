import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/savings_target_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/empty_state.dart';

/// Halaman Target Tabungan & Riwayat Pencapaian
class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Dialog Setor Tabungan Cepat
  void _showDepositDialog(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    if (repo.activeSavingsTarget == null) return;

    final amountController = TextEditingController();
    int? selectedWalletId =
        repo.wallets.isNotEmpty ? repo.wallets.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Setor ke Tabungan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Setoran (Rp)',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: selectedWalletId,
                    items: repo.wallets.map((w) {
                      return DropdownMenuItem<int>(
                        value: w.id,
                        child: Text('${w.name} (${CurrencyFormat.toRupiah(w.currentBalance)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedWalletId = val),
                    decoration: const InputDecoration(labelText: 'Dari Dompet'),
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
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount <= 0 || selectedWalletId == null) return;

                    final tx = TransactionModel(
                      type: 'savings_deposit',
                      amount: amount,
                      walletId: selectedWalletId!,
                      dateTime: DateTime.now(),
                      title: 'Setor Tabungan: ${repo.activeSavingsTarget!.name}',
                      notes: 'Alokasi dana ke target tabungan',
                    );

                    await repo.addTransaction(tx, []);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Setor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog Edit Target Aktif
  void _showEditTargetDialog(BuildContext context, SavingsTargetModel? current) {
    final repo = context.read<FinanceRepository>();
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController =
        TextEditingController(text: current?.targetAmount.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(current == null ? 'Buat Target Baru' : 'Edit Target Tabungan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Target',
                  hintText: 'Misal: Tabungan Liburan, Beli HP',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Nominal (Rp)',
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
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (name.isEmpty || amount <= 0) return;

                await repo.createSavingsTarget(name, amount);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final target = repo.activeSavingsTarget;
    final history = repo.savingsHistory;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Target Aktif'),
            Tab(text: 'Riwayat Tercapai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Target Aktif
          target == null
              ? EmptyStateWidget(
                  icon: Icons.savings_outlined,
                  title: 'Belum Ada Target Tabungan',
                  message: 'Buat target tabungan pertamamu untuk memotivasi pengelolaan keuanganmu!',
                  actionLabel: 'Buat Target Baru',
                  onAction: () => _showEditTargetDialog(context, null),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      target.name,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit Target',
                                    onPressed: () => _showEditTargetDialog(context, target),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Lingkaran Progress Persentase
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: CircularProgressIndicator(
                                      value: (target.progressPercentage / 100.0).clamp(0.0, 1.0),
                                      strokeWidth: 14,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                      color: target.progressPercentage >= 100
                                          ? Colors.green
                                          : theme.colorScheme.primary,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${target.progressPercentage.toStringAsFixed(1)}%',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const Text(
                                        'Terkumpul',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Terkumpul',
                                    CurrencyFormat.toRupiah(target.currentAmount),
                                    Colors.green,
                                  ),
                                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                                  _buildStatItem(
                                    'Target',
                                    CurrencyFormat.toRupiah(target.targetAmount),
                                    theme.colorScheme.primary,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              Text(
                                target.targetAmount > target.currentAmount
                                    ? 'Kurang ${CurrencyFormat.toRupiah(target.targetAmount - target.currentAmount)} lagi untuk mencapai impianmu!'
                                    : '✨ Target ini telah terpenuhi! ✨',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: target.targetAmount > target.currentAmount
                                      ? Colors.grey.shade600
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showDepositDialog(context),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Setor Tabungan Sekarang'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),

          // Tab 2: Riwayat Target Tercapai
          history.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.emoji_events_outlined,
                  title: 'Belum Ada Riwayat Target',
                  message: 'Target tabungan yang telah kamu capai akan diarsipkan rapi di sini.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.withOpacity(0.15),
                          child: const Icon(Icons.emoji_events, color: Colors.amber),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tercapai: ${item.reachedAt != null ? DateHelper.formatShort(item.reachedAt!) : "Sebelumnya"}\n'
                          'Terkumpul: ${CurrencyFormat.toRupiah(item.currentAmount)} dari ${CurrencyFormat.toRupiah(item.targetAmount)}',
                        ),
                        trailing: Chip(
                          label: Text(
                            item.status == 'reached' ? 'Tercapai' : 'Diarsipkan',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: item.status == 'reached'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
