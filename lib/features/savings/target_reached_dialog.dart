import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../data/models/savings_target_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/app_mascot.dart';

/// Dialog Modal Wajib saat Target Tabungan Tercapai (Tidak bisa ditutup sebelum memilih)
class TargetReachedDialog extends StatefulWidget {
  final SavingsTargetModel target;

  const TargetReachedDialog({super.key, required this.target});

  static Future<void> show(BuildContext context, SavingsTargetModel target) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TargetReachedDialog(target: target),
    );
  }

  @override
  State<TargetReachedDialog> createState() => _TargetReachedDialogState();
}

class _TargetReachedDialogState extends State<TargetReachedDialog> {
  late ConfettiController _confettiController;
  int _selectedOption = 0; // 0: menu utama, 1: naikkan target, 2: ganti target, 3: pakai uang

  // Controllers Pilihan 1: Naikkan target
  final TextEditingController _raiseAmountController = TextEditingController();

  // Controllers Pilihan 2: Ganti target
  final TextEditingController _newTargetNameController = TextEditingController();
  final TextEditingController _newTargetAmountController = TextEditingController();

  // Controllers Pilihan 3: Belanja dan buat target baru
  final TextEditingController _spendAmountController = TextEditingController();
  final TextEditingController _spendNoteController = TextEditingController();
  int? _spendWalletId;
  final TextEditingController _postSpendNewTargetName = TextEditingController();
  final TextEditingController _postSpendNewTargetAmount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5))..play();

    // Default nilai naikkan target (+25% dari target lama)
    final suggestedRaise = (widget.target.targetAmount * 1.25).roundToDouble();
    _raiseAmountController.text = suggestedRaise.toStringAsFixed(0);
    _spendAmountController.text = widget.target.targetAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _raiseAmountController.dispose();
    _newTargetNameController.dispose();
    _newTargetAmountController.dispose();
    _spendAmountController.dispose();
    _spendNoteController.dispose();
    _postSpendNewTargetName.dispose();
    _postSpendNewTargetAmount.dispose();
    super.dispose();
  }

  // Aksi 1: Naikkan target
  void _submitRaiseTarget() {
    final amount = double.tryParse(_raiseAmountController.text) ?? 0.0;
    if (amount <= widget.target.targetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target baru harus lebih besar dari target sebelumnya!')),
      );
      return;
    }

    final repo = context.read<FinanceRepository>();
    repo.raiseSavingsTarget(amount);
    Navigator.of(context).pop();
  }

  // Aksi 2: Ganti target
  void _submitChangeTarget() {
    final name = _newTargetNameController.text.trim();
    final amount = double.tryParse(_newTargetAmountController.text) ?? 0.0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama target dan nominal baru harus diisi dengan benar!')),
      );
      return;
    }

    final repo = context.read<FinanceRepository>();
    repo.changeSavingsTarget(name, amount);
    Navigator.of(context).pop();
  }

  // Aksi 3: Tandai selesai dan pakai uangnya
  void _submitSpendAndArchive() {
    final repo = context.read<FinanceRepository>();
    final spendAmount = double.tryParse(_spendAmountController.text);
    final newTargetName = _postSpendNewTargetName.text.trim();
    final newTargetAmount = double.tryParse(_postSpendNewTargetAmount.text) ?? 0.0;

    if (newTargetName.isEmpty || newTargetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama dan nominal target tabungan baru!')),
      );
      return;
    }

    final walletId = _spendWalletId ?? (repo.wallets.isNotEmpty ? repo.wallets.first.id : 1);

    repo.markCompletedAndArchive(
      spendAmount: spendAmount,
      spendWalletId: walletId,
      spendNote: _spendNoteController.text.trim(),
      newTargetName: newTargetName,
      newTargetAmount: newTargetAmount,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<FinanceRepository>();

    return PopScope(
      canPop: false, // Tidak bisa ditutup lewat tombol back fisik/gestur
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppMascot(
                    size: 96,
                    mood: MascotMood.celebrating,
                    isDancing: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎉 Target Tabungan Tercapai! 🎉',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target "${widget.target.name}" sebesar ${CurrencyFormat.toRupiah(widget.target.targetAmount)} telah berhasil terkumpul ${CurrencyFormat.toRupiah(widget.target.currentAmount)}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Menu Pilihan
                  if (_selectedOption == 0) ...[
                    Text(
                      'Mau lanjut ke mana?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      icon: Icons.trending_up,
                      color: Colors.green,
                      title: 'Naikkan Target',
                      subtitle: 'Lanjutkan tabungan ini dengan nominal target yang lebih besar',
                      onTap: () => setState(() => _selectedOption = 1),
                    ),
                    const SizedBox(height: 10),
                    _buildOptionCard(
                      icon: Icons.flag_outlined,
                      color: Colors.blue,
                      title: 'Ganti Target Baru',
                      subtitle: 'Arsipkan pencapaian ini dan buat target baru dari nol',
                      onTap: () => setState(() => _selectedOption = 2),
                    ),
                    const SizedBox(height: 10),
                    _buildOptionCard(
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.purple,
                      title: 'Tandai Selesai & Pakai Uangnya',
                      subtitle: 'Belanjakan tabungan untuk target ini lalu buat target baru',
                      onTap: () {
                        if (repo.wallets.isNotEmpty) {
                          _spendWalletId = repo.wallets.first.id;
                        }
                        setState(() => _selectedOption = 3);
                      },
                    ),
                  ],

                  // Form Pilihan 1: Naikkan Target
                  if (_selectedOption == 1) ...[
                    Text(
                      'Naikkan Nominal Target',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _raiseAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Target Baru (Rp)',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('+25%'),
                          onPressed: () {
                            final val = (widget.target.targetAmount * 1.25).roundToDouble();
                            _raiseAmountController.text = val.toStringAsFixed(0);
                          },
                        ),
                        ActionChip(
                          label: const Text('+50%'),
                          onPressed: () {
                            final val = (widget.target.targetAmount * 1.50).roundToDouble();
                            _raiseAmountController.text = val.toStringAsFixed(0);
                          },
                        ),
                        ActionChip(
                          label: const Text('2x Lipat'),
                          onPressed: () {
                            final val = (widget.target.targetAmount * 2.0).roundToDouble();
                            _raiseAmountController.text = val.toStringAsFixed(0);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _selectedOption = 0),
                          child: const Text('Kembali'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _submitRaiseTarget,
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                  ],

                  // Form Pilihan 2: Ganti Target
                  if (_selectedOption == 2) ...[
                    Text(
                      'Buat Target Baru',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newTargetNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Target Baru (misal: Beli Laptop)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newTargetAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Target (Rp)',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _selectedOption = 0),
                          child: const Text('Kembali'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _submitChangeTarget,
                          child: const Text('Mulai Target Baru'),
                        ),
                      ],
                    ),
                  ],

                  // Form Pilihan 3: Pakai Uangnya & Target Baru
                  if (_selectedOption == 3) ...[
                    Text(
                      'Belanjakan & Buat Target Baru',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _spendAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal yang Dibelanjakan (Rp)',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _spendWalletId,
                      items: repo.wallets.map((w) {
                        return DropdownMenuItem<int>(
                          value: w.id,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _spendWalletId = val),
                      decoration: const InputDecoration(labelText: 'Sumber Dompet'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _spendNoteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Belanja (Opsional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Target Tabungan Berikutnya:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _postSpendNewTargetName,
                      decoration: const InputDecoration(
                        labelText: 'Nama Target Selanjutnya',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _postSpendNewTargetAmount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Target Baru (Rp)',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _selectedOption = 0),
                          child: const Text('Kembali'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _submitSpendAndArchive,
                          child: const Text('Konfirmasi & Selesai'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
            colors: const [Colors.amber, Colors.green, Colors.pink, Colors.blue],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
