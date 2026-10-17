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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi aktif kembali dari latar belakang, periksa ulang tanggal ulang tahun
      final repo = context.read<FinanceRepository>();
      context.read<BirthdayManager>().evaluateBirthday(repo.profile);

      // Kunci kembali jika PIN diaktifkan
      if (repo.profile?.pinHash != null && repo.profile!.pinHash!.isNotEmpty) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  Future<void> _bootstrapApp() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;

    // Muat data utama repository
    final repo = context.read<FinanceRepository>();
    await repo.initialize();

    // Periksa status ulang tahun
    if (mounted) {
      context.read<BirthdayManager>().evaluateBirthday(repo.profile);
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
