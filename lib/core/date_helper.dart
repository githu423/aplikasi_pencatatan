import 'package:intl/intl.dart';

/// Helper tanggal dan kalkulasi ulang tahun
class DateHelper {
  static final DateFormat _dateFormatFull = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _dateFormatShort = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dayAndDateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');

  /// Contoh: 17 Oktober 2026
  static String formatFull(DateTime date) {
    return _dateFormatFull.format(date);
  }

  /// Contoh: 17 Okt 2026
  static String formatShort(DateTime date) {
    return _dateFormatShort.format(date);
  }

  /// Contoh: 17 Okt 2026, 14:30
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Contoh: 14:30
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Contoh: Sabtu, 17 Oktober 2026
  static String formatDayAndDate(DateTime date) {
    return _dayAndDateFormat.format(date);
  }

  /// Contoh: Oktober 2026
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
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
