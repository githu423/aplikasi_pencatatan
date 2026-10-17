import 'package:flutter/material.dart';

/// Konstanta utama aplikasi Catatan Keuangan
class AppConstants {
  static const String appName = 'Catatan Keuangan';
  static const String appVersion = '1.0.0';
  static const String androidPackageName = 'com.abi.catatankeuangan';

  // Kunci SharedPreferences
  static const String prefOnboardingCompleted = 'onboarding_completed';
  static const String prefPinHash = 'user_pin_hash';
  static const String prefBiometricEnabled = 'biometric_enabled';
  static const String prefThemeMode = 'theme_mode'; // 'system', 'light', 'dark'
  static const String prefIsMuted = 'is_muted';
  static const String prefLastBackupDate = 'last_backup_date';

  // Pilihan Variasi Ucapan Ulang Tahun
  static const List<String> birthdayGreetings = [
    'Semoga sehat selalu, panjang umur, dan rezekinya makin melimpah!',
    'Tahun baru usia baru, semoga semua mimpi dan target tabunganmu tercapai!',
    'Selamat merayakan hari istimewamu! Tetap semangat dan bahagia selalu.',
    'Hari ini harimu! Semoga selalu diberkahi kebahagiaan dan kesuksesan.',
    'Selamat ulang tahun! Makin bijak mengelola keuangan dan makin sukses!',
  ];

  // Daftar Kategori Awal Pengeluaran
  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {
      'name': 'Makan & Minum',
      'icon': Icons.restaurant_outlined,
      'color': Color(0xFFEF4444),
    },
    {
      'name': 'Transportasi',
      'icon': Icons.directions_car_outlined,
      'color': Color(0xFFF97316),
    },
    {
      'name': 'Belanja',
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFEC4899),
    },
    {
      'name': 'Tagihan & Utilitas',
      'icon': Icons.receipt_long_outlined,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Pendidikan',
      'icon': Icons.school_outlined,
      'color': Color(0xFF3B82F6),
    },
    {
      'name': 'Hiburan',
      'icon': Icons.sports_esports_outlined,
      'color': Color(0xFF06B6D4),
    },
    {
      'name': 'Kesehatan',
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'name': 'Lainnya',
      'icon': Icons.more_horiz_outlined,
      'color': Color(0xFF64748B),
    },
  ];

  // Daftar Kategori Awal Pemasukan
  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {
      'name': 'Gaji',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'name': 'Uang Saku',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF14B8A6),
    },
    {
      'name': 'Hadiah & Bonus',
      'icon': Icons.card_giftcard_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'name': 'Usaha & Bisnis',
      'icon': Icons.storefront_outlined,
      'color': Color(0xFF6366F1),
    },
    {
      'name': 'Lainnya',
      'icon': Icons.savings_outlined,
      'color': Color(0xFF64748B),
    },
  ];

  // Dompet Awal
  static const List<Map<String, dynamic>> defaultWallets = [
    {'name': 'Tunai', 'initialBalance': 0.0},
    {'name': 'Bank', 'initialBalance': 0.0},
    {'name': 'E-Wallet', 'initialBalance': 0.0},
  ];
}
