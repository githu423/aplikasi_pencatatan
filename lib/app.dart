import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/finance_repository.dart';
import 'features/birthday/birthday_manager.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/pin_lock_screen.dart';

/// Widget Utama Aplikasi yang mengatur Tema, Routing, dan Status Lifecycle
class CatatanKeuanganApp extends StatefulWidget {
  const CatatanKeuanganApp({super.key});

  @override
  State<CatatanKeuanganApp> createState() => _CatatanKeuanganAppState();
}

class _CatatanKeuanganAppState extends State<CatatanKeuanganApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoadingInitial = true;
  bool _isOnboardingDone = false;
  bool _isLocked = false;

  String? _startupError;
  String? _startupStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Jalankan setelah frame pertama agar context aman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        final repo = context.read<FinanceRepository>();
        context.read<BirthdayManager>().evaluateBirthday(repo.profile);
      } catch (e, st) {
        debugPrint('evaluateBirthday on resume gagal: $e\n$st');
      }

      // Kunci kembali jika PIN diaktifkan
      try {
        final repo = context.read<FinanceRepository>();
        if (repo.profile?.pinHash != null && repo.profile!.pinHash!.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isLocked = true;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _bootstrapApp() async {
    try {
      await _doBootstrap().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Timeout inisialisasi aplikasi (20 detik). Periksa database atau plugin.');
        },
      );
    } catch (e, st) {
      debugPrint('Bootstrap gagal: $e\n$st');
      if (!mounted) return;
      setState(() {
        _startupError = e.toString();
        _startupStack = st.toString().length > 2000 ? st.toString().substring(0, 2000) : st.toString();
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _doBootstrap() async {
    // SharedPreferences dengan timeout
    final prefs = await SharedPreferences.getInstance()
        .timeout(const Duration(seconds: 5), onTimeout: () {
      throw TimeoutException('Timeout SharedPreferences');
    });
    final onboardingDone = prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;

    if (!mounted) return;

    // Muat data utama repository
    final repo = context.read<FinanceRepository>();
    await repo.initialize();

    // Periksa status ulang tahun - jangan blokir bootstrap
    if (mounted) {
      try {
        context.read<BirthdayManager>().evaluateBirthday(repo.profile);
      } catch (e, st) {
        debugPrint('evaluateBirthday gagal: $e\n$st');
      }
    }

    // Setel Tema
    final savedTheme = repo.profile?.themeMode ?? 'system';
    ThemeMode initialMode = ThemeMode.system;
    if (savedTheme == 'light') {
      initialMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      initialMode = ThemeMode.dark;
    }

    final hasPin = repo.profile?.pinHash != null && repo.profile!.pinHash!.isNotEmpty;

    if (mounted) {
      setState(() {
        _themeMode = initialMode;
        _isOnboardingDone = onboardingDone;
        _isLocked = hasPin;
        _isLoadingInitial = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoadingInitial = true;
      _startupError = null;
      _startupStack = null;
    });
    _bootstrapApp();
  }

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _unlockApp() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _buildHomeWidget(),
    );
  }

  Widget _buildHomeWidget() {
    if (_isLoadingInitial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Tampilkan layar error jika bootstrap gagal (bukan spinner selamanya)
    if (_startupError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gagal memuat aplikasi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat aplikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: SelectableText(
                  _startupError!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              if (_startupStack != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    _startupStack!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF424242)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pesan error ini membantu melacak penyebab. Screenshot layar ini jika masih gagal.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 1. Tampilkan onboarding bila baru pertama kali buka
    if (!_isOnboardingDone) {
      return const OnboardingScreen();
    }

    final repo = context.watch<FinanceRepository>();
    final profile = repo.profile;

    // 2. Kunci PIN jika aktif
    if (_isLocked && profile?.pinHash != null && profile!.pinHash!.isNotEmpty) {
      return PinLockScreen(
        correctPinHash: profile.pinHash!,
        biometricEnabled: profile.biometricEnabled,
        onSuccess: _unlockApp,
      );
    }

    // 3. Masuk ke Dashboard Utama
    return DashboardScreen(
      onThemeModeChanged: _onThemeModeChanged,
    );
  }
}
