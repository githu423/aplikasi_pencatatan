import 'package:intl/intl.dart';

/// Helper pemformatan mata uang Rupiah - lazy dengan fallback
class CurrencyFormat {
  static NumberFormat? _rupiahFormat;
  static NumberFormat? _compactRupiahFormat;

  static NumberFormat _getRupiah() {
    if (_rupiahFormat != null) return _rupiahFormat!;
    for (final locale in ['id_ID', 'id', null]) {
      try {
        _rupiahFormat = locale == null
            ? NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0)
            : NumberFormat.currency(locale: locale, symbol: 'Rp ', decimalDigits: 0);
        return _rupiahFormat!;
      } catch (_) {
        continue;
      }
    }
    // fallback terakhir: tanpa locale
    _rupiahFormat = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    return _rupiahFormat!;
  }

  static NumberFormat _getCompact() {
    if (_compactRupiahFormat != null) return _compactRupiahFormat!;
    for (final locale in ['id_ID', 'id', null]) {
      try {
        _compactRupiahFormat = locale == null
            ? NumberFormat.compactCurrency(symbol: 'Rp ', decimalDigits: 1)
            : NumberFormat.compactCurrency(locale: locale, symbol: 'Rp ', decimalDigits: 1);
        return _compactRupiahFormat!;
      } catch (_) {
        continue;
      }
    }
    _compactRupiahFormat = NumberFormat.compactCurrency(symbol: 'Rp ', decimalDigits: 1);
    return _compactRupiahFormat!;
  }

  /// Format angka ke format Rupiah standar, contoh: Rp 1.250.000
  static String toRupiah(num amount, {bool withSymbol = true}) {
    try {
      final formatted = _getRupiah().format(amount);
      if (!withSymbol) {
        return formatted.replaceAll('Rp', '').trim();
      }
      return formatted;
    } catch (_) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  /// Format ringkas untuk grafik atau ruang sempit, contoh: Rp 1,5 jt
  static String toCompactRupiah(num amount) {
    try {
      return _getCompact().format(amount);
    } catch (_) {
      return 'Rp $amount';
    }
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
