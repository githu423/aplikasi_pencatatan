import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/app_mascot.dart';
import '../dashboard/dashboard_screen.dart';

/// Layar Onboarding / Setup Awal Aplikasi
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  DateTime _birthDate = DateTime(2000, 1, 1);
  final TextEditingController _targetNameController = TextEditingController(text: 'Dana Darurat');
  final TextEditingController _targetAmountController = TextEditingController(text: '1000000');
  final TextEditingController _initialBalanceController = TextEditingController(text: '0');

  // Keamanan
  bool _enablePin = false;
  final TextEditingController _pinController = TextEditingController();
  bool _canCheckBiometrics = false;
  bool _enableBiometrics = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetNameController.dispose();
    _targetAmountController.dispose();
    _initialBalanceController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<FinanceRepository>();

    // Hash PIN jika diaktifkan
    String? pinHash;
    if (_enablePin && _pinController.text.length >= 4) {
      pinHash = sha256.convert(utf8.encode(_pinController.text)).toString();
    }

    // 1. Simpan Profil
    final profile = ProfileModel(
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      pinHash: pinHash,
      biometricEnabled: _enableBiometrics,
    );
    await repo.updateProfile(profile);

    // 2. Set Saldo Awal Dompet Pertama (Tunai)
    final initialBalance = double.tryParse(_initialBalanceController.text) ?? 0.0;
    if (repo.wallets.isNotEmpty && initialBalance > 0) {
      final firstWallet = repo.wallets.first;
      await repo.updateWallet(firstWallet.id!, firstWallet.name, initialBalance);
    }

    // 3. Buat Target Tabungan Awal
    final targetName = _targetNameController.text.trim();
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 1000000.0;
    await repo.createSavingsTarget(targetName, targetAmount);

    // 4. Tandai Onboarding Selesai di SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingCompleted, true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const AppMascot(
                  size: 96,
                  mood: MascotMood.happy,
                  isDancing: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Selamat Datang!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aplikasi Catatan Keuangan Pribadi 100% Offline.\nIsi data awalmu untuk memulai perjalanan finansial sehat.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Card 1: Identitas
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Identitas Kamu',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Panggilan',
                            hintText: 'Contoh: Budi',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Silakan isi nama panggilan kamu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () => _selectBirthDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Lahir',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateHelper.formatFull(_birthDate)),
                                const Icon(Icons.calendar_month_outlined, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Keuangan & Target
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Target & Saldo Awal',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _targetNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Target Tabungan',
                            hintText: 'Misal: Beli Laptop, Liburan',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama target tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _targetAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nominal Target Tabungan (Rp)',
                            prefixIcon: Icon(Icons.monetization_on_outlined),
                            prefixText: 'Rp ',
                          ),
                          validator: (val) {
                            if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                              return 'Nominal target harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _initialBalanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Saldo Awal Tunai (Opsional)',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                            prefixText: 'Rp ',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 3: Keamanan Kunci PIN & Biometrik (Opsional)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Kunci Aplikasi (Opsional)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Aktifkan Kunci PIN'),
                          subtitle: const Text('Kunci aplikasi dengan 4-6 digit angka saat dibuka'),
                          value: _enablePin,
                          onChanged: (val) => setState(() => _enablePin = val),
                        ),
                        if (_enablePin) ...[
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'PIN (4 - 6 digit angka)',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                            validator: (val) {
                              if (_enablePin && (val == null || val.length < 4 || val.length > 6)) {
                                return 'PIN harus terdiri dari 4 sampai 6 digit';
                              }
                              return null;
                            },
                          ),
                          if (_canCheckBiometrics) ...[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Gunakan Sidik Jari / Biometrik'),
                              subtitle: const Text('Buka kunci lebih cepat dengan sensor sidik jari'),
                              value: _enableBiometrics,
                              onChanged: (val) => setState(() => _enableBiometrics = val),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Mulai
                ElevatedButton(
                  onPressed: _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Mulai Sekarang', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
