import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/repositories/finance_repository.dart';
import 'features/birthday/birthday_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi lokalisasi tanggal Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

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
