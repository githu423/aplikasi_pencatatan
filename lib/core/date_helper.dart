import 'package:intl/intl.dart';

/// Helper tanggal dan kalkulasi ulang tahun
/// DateFormat dibuat lazy dengan fallback agar tidak melempar LocaleDataException saat startup.
class DateHelper {
  static DateFormat? _dateFormatFull;
  static DateFormat? _dateFormatShort;
  static DateFormat? _dateTimeFormat;
  static DateFormat? _timeFormat;
  static DateFormat? _dayAndDateFormat;
  static DateFormat? _monthYearFormat;

  static DateFormat _getOrCreate(DateFormat? current, String pattern) {
    if (current != null) return current;
    // Coba id_ID dulu, fallback ke id, lalu tanpa locale
    for (final locale in ['id_ID', 'id', null]) {
      try {
        return locale == null ? DateFormat(pattern) : DateFormat(pattern, locale);
      } catch (_) {
        continue;
      }
    }
    return DateFormat(pattern);
  }

  static DateFormat get _full => _dateFormatFull ??= _getOrCreate(_dateFormatFull, 'd MMMM yyyy');
  static DateFormat get _short => _dateFormatShort ??= _getOrCreate(_dateFormatShort, 'd MMM yyyy');
  static DateFormat get _dateTime => _dateTimeFormat ??= _getOrCreate(_dateTimeFormat, 'd MMM yyyy, HH:mm');
  static DateFormat get _time => _timeFormat ??= _getOrCreate(_timeFormat, 'HH:mm');
  static DateFormat get _dayDate => _dayAndDateFormat ??= _getOrCreate(_dayAndDateFormat, 'EEEE, d MMMM yyyy');
  static DateFormat get _monthYear => _monthYearFormat ??= _getOrCreate(_monthYearFormat, 'MMMM yyyy');

  /// Contoh: 17 Oktober 2026
  static String formatFull(DateTime date) {
    try {
      return _full.format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Contoh: 17 Okt 2026
  static String formatShort(DateTime date) {
    try {
      return _short.format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Contoh: 17 Okt 2026, 14:30
  static String formatDateTime(DateTime date) {
    try {
      return _dateTime.format(date);
    } catch (_) {
      return date.toIso8601String();
    }
  }

  /// Contoh: 14:30
  static String formatTime(DateTime date) {
    try {
      return _time.format(date);
    } catch (_) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Contoh: Sabtu, 17 Oktober 2026
  static String formatDayAndDate(DateTime date) {
    try {
      return _dayDate.format(date);
    } catch (_) {
      return formatFull(date);
    }
  }

  /// Contoh: Oktober 2026
  static String formatMonthYear(DateTime date) {
    try {
      return _monthYear.format(date);
    } catch (_) {
      return '${date.month}/${date.year}';
    }
  }

  /// Memeriksa apakah suatu tahun adalah tahun kabisat
  static bool isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    return year % 4 == 0;
  }

  /// Memeriksa apakah hari ini adalah ulang tahun pengguna.
  /// Menangani kasus khusus 29 Februari: jika tahun sekarang bukan tahun kabisat, dirayakan pada 28 Februari.
  static bool isBirthdayToday(DateTime birthDate, {DateTime? today}) {
    final now = today ?? DateTime.now();

    // Kasus 29 Februari
    if (birthDate.month == 2 && birthDate.day == 29) {
      if (isLeapYear(now.year)) {
        return now.month == 2 && now.day == 29;
      } else {
        // Tahun non-kabisat: rayakan pada 28 Februari
        return now.month == 2 && now.day == 28;
      }
    }

    return now.month == birthDate.month && now.day == birthDate.day;
  }

  /// Menghitung usia pengguna saat ini
  static int calculateAge(DateTime birthDate, {DateTime? today}) {
    final now = today ?? DateTime.now();
    int age = now.year - birthDate.year;

    // Periksa apakah ulang tahun tahun ini sudah lewat atau belum
    DateTime birthdayThisYear;
    if (birthDate.month == 2 && birthDate.day == 29 && !isLeapYear(now.year)) {
      birthdayThisYear = DateTime(now.year, 2, 28);
    } else {
      birthdayThisYear = DateTime(now.year, birthDate.month, birthDate.day);
    }

    final todayStart = DateTime(now.year, now.month, now.day);
    if (todayStart.isBefore(birthdayThisYear)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  /// Menghitung berapa hari lagi menuju ulang tahun berikutnya
  static int daysUntilNextBirthday(DateTime birthDate, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    DateTime nextBirthday;
    if (birthDate.month == 2 && birthDate.day == 29 && !isLeapYear(now.year)) {
      nextBirthday = DateTime(now.year, 2, 28);
    } else {
      nextBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    }

    if (nextBirthday.isBefore(todayStart)) {
      // Sudah lewat tahun ini, hitung untuk tahun depan
      final nextYear = now.year + 1;
      if (birthDate.month == 2 && birthDate.day == 29 && !isLeapYear(nextYear)) {
        nextBirthday = DateTime(nextYear, 2, 28);
      } else {
        nextBirthday = DateTime(nextYear, birthDate.month, birthDate.day);
      }
    }

    final difference = nextBirthday.difference(todayStart).inDays;
    return difference;
  }
}
