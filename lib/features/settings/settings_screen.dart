import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../birthday/birthday_manager.dart';
import '../savings/savings_screen.dart';
import 'backup_service.dart';
import 'manage_categories_screen.dart';
import 'manage_wallets_screen.dart';

/// Halaman Pengaturan Aplikasi
class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;

  const SettingsScreen({super.key, required this.onThemeModeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showBackupReminder = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkReminder();
    _checkBiometrics();
  }

  Future<void> _checkReminder() async {
    final show = await BackupService.shouldShowMonthlyReminder();
    if (mounted) {
      setState(() {
        _showBackupReminder = show;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final can = await _localAuth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _canCheckBiometrics = can;
        });
      }
    } catch (_) {}
  }

  void _editProfileDialog(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    final profile = repo.profile;
    final nameController = TextEditingController(text: profile?.name ?? '');
    DateTime birthDate = profile?.birthDate ?? DateTime(2000, 1, 1);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Profil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Panggilan'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: birthDate,
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                        locale: const Locale('id', 'ID'),
                      );
                      if (picked != null) {
                        setDialogState(() => birthDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateHelper.formatFull(birthDate)),
                          const Icon(Icons.calendar_month, size: 20),
                        ],
                      ),
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
                    if (name.isEmpty) return;

                    final updated = (profile ?? ProfileModel(name: name, birthDate: birthDate)).copyWith(
                      name: name,
                      birthDate: birthDate,
                    );
                    await repo.updateProfile(updated);

                    // Re-evaluasi ulang tahun
                    if (ctx.mounted) {
                      context.read<BirthdayManager>().evaluateBirthday(updated);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _setupPinDialog(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    final pinController = TextEditingController();
    final profile = repo.profile;
    final hasPin = profile?.pinHash != null && profile!.pinHash!.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(hasPin ? 'Ubah atau Hapus PIN' : 'Pasang PIN Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasPin
                    ? 'Masukkan PIN baru (4-6 digit) atau kosongkan untuk menghapus PIN.'
                    : 'Masukkan 4-6 digit angka untuk mengunci aplikasi.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru',
                  prefixIcon: Icon(Icons.pin),
                ),
              ),
            ],
          ),
          actions: [
            if (hasPin)
              TextButton(
                onPressed: () async {
                  await repo.updatePin(null, false);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Hapus PIN', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.length < 4 || pin.length > 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN harus 4 sampai 6 digit!')),
                  );
                  return;
                }

                final hash = sha256.convert(utf8.encode(pin)).toString();
                await repo.updatePin(hash, profile?.biometricEnabled ?? false);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Simpan PIN'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performRestore(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Data Cadangan?'),
        content: const Text(
          'Memulihkan data dari file ZIP akan menimpa seluruh catatan transaksi, dompet, dan foto saat ini dengan data dari berkas cadangan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Pulihkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await BackupService.importBackup();
    if (context.mounted) {
      if (success) {
        final repo = context.read<FinanceRepository>();
        await repo.initialize();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan dari cadangan!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemulihan dibatalkan atau file tidak valid.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<FinanceRepository>();
    final profile = repo.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Banner Pengingat Bulanan Backup
          if (_showBackupReminder)
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.amber.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    const Icon(Icons.backup_outlined, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sudah backup bulan ini?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Cadangkan seluruh data dan foto agar aman saat ganti perangkat.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _showBackupReminder = false),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Profil
          _buildSectionHeader('Profil Pengguna'),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(
                profile?.name ?? 'Pengguna',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Lahir: ${profile != null ? DateHelper.formatFull(profile.birthDate) : "-"}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editProfileDialog(context),
            ),
          ),

          const SizedBox(height: 16),

          // Pengelolaan Data Keuangan
          _buildSectionHeader('Data & Target'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: Colors.teal),
                  title: const Text('Kelola Kategori'),
                  subtitle: const Text('Kustomisasi nama, ikon, dan warna kategori'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
                  title: const Text('Kelola Dompet & Rekening'),
                  subtitle: const Text('Atur rekening dan saldo awal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageWalletsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings_outlined, color: Colors.purple),
                  title: const Text('Target Tabungan & Riwayat'),
                  subtitle: const Text('Lihat progress target dan riwayat pencapaian'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Keamanan
          _buildSectionHeader('Keamanan Aplikasi'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.indigo),
                  title: const Text('Kunci PIN'),
                  subtitle: Text(
                    profile?.pinHash != null ? 'PIN Aktif' : 'Tidak aktif',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _setupPinDialog(context),
                ),
                if (_canCheckBiometrics && profile?.pinHash != null) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: Colors.indigo),
                    title: const Text('Buka dengan Sidik Jari'),
                    value: profile?.biometricEnabled ?? false,
                    onChanged: (val) async {
                      await repo.updatePin(profile?.pinHash, val);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tampilan & Format
          _buildSectionHeader('Tampilan & Format'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Tema Tampilan'),
                  subtitle: Text(
                    profile?.themeMode == 'light'
                        ? 'Terang'
                        : profile?.themeMode == 'dark'
                            ? 'Gelap'
                            : 'Mengikuti Sistem',
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (mode) async {
                      final updated = profile?.copyWith(themeMode: mode);
                      if (updated != null) {
                        await repo.updateProfile(updated);
                        if (mode == 'light') {
                          widget.onThemeModeChanged(ThemeMode.light);
                        } else if (mode == 'dark') {
                          widget.onThemeModeChanged(ThemeMode.dark);
                        } else {
                          widget.onThemeModeChanged(ThemeMode.system);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'system', child: Text('Mengikuti Sistem')),
                      PopupMenuItem(value: 'light', child: Text('Terang')),
                      PopupMenuItem(value: 'dark', child: Text('Gelap')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Format Mata Uang'),
                  subtitle: const Text('Rupiah Indonesia (IDR)'),
                  trailing: Text(
                    CurrencyFormat.toRupiah(1250000),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Backup & Restore
          _buildSectionHeader('Cadangan & Pemulihan (ZIP 100% Offline)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.green),
                  title: const Text('Ekspor Cadangan (ZIP)'),
                  subtitle: const Text('Simpan seluruh database, pengaturan, dan foto bukti'),
                  onTap: () async {
                    final path = await BackupService.exportBackup();
                    if (path != null && context.mounted) {
                      setState(() => _showBackupReminder = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cadangan berhasil diekspor!')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
                  title: const Text('Pulihkan Cadangan (ZIP)'),
                  subtitle: const Text('Pulihkan data dari berkas cadangan ZIP'),
                  onTap: () => _performRestore(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}\n100% Offline & Menjaga Privasi Datamu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
