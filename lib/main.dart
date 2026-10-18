import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/repositories/finance_repository.dart';
import 'features/birthday/birthday_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tangkap error global agar tidak hilang diam-diam
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error\n$stack');
    return true;
  };

  // Inisialisasi lokalisasi tanggal Bahasa Indonesia dengan timeout + fallback
  // Jika locale id_ID gagal, coba 'id', jika masih gagal lanjutkan tanpa locale agar spinner tidak hang.
  try {
    await initializeDateFormatting('id_ID', null)
        .timeout(const Duration(seconds: 5));
    debugPrint('Locale id_ID loaded');
  } catch (e, st) {
    debugPrint('Gagal load locale id_ID: $e');
    try {
      await initializeDateFormatting('id', null)
          .timeout(const Duration(seconds: 3));
      debugPrint('Locale id fallback loaded');
    } catch (e2, st2) {
      debugPrint('Gagal load locale fallback: $e2\n$st2');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceRepository()),
        ChangeNotifierProvider(create: (_) => BirthdayManager()),
      ],
      child: const CatatanKeuanganApp(),
    ),
  );
}
