import 'package:intl/intl.dart';

/// Helper pemformatan mata uang Rupiah
class CurrencyFormat {
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactRupiahFormat = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  /// Format angka ke format Rupiah standar, contoh: Rp 1.250.000
  static String toRupiah(num amount, {bool withSymbol = true}) {
    final formatted = _rupiahFormat.format(amount);
    if (!withSymbol) {
      return formatted.replaceAll('Rp', '').trim();
    }
    return formatted;
  }

  /// Format ringkas untuk grafik atau ruang sempit, contoh: Rp 1,5 jt
  static String toCompactRupiah(num amount) {
    return _compactRupiahFormat.format(amount);
  }

  /// Parsing teks angka rupiah ke double
  static double parseRupiah(String text) {
    if (text.isEmpty) return 0.0;
    // Hapus non-digit kecuali tanda minus bila ada
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }
}
