import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/date_helper.dart';
import '../../data/models/profile_model.dart';

/// Manager logika ulang tahun yang memantau tanggal dan menghitung status event
class BirthdayManager extends ChangeNotifier {
  bool _isBirthdayToday = false;
  int _currentAge = 0;
  int _daysUntilBirthday = 0;
  String _currentGreeting = '';

  bool get isBirthdayToday => _isBirthdayToday;
  int get currentAge => _currentAge;
  int get daysUntilBirthday => _daysUntilBirthday;
  String get currentGreeting => _currentGreeting;

  void evaluateBirthday(ProfileModel? profile) {
    if (profile == null) return;

    final birthDate = profile.birthDate;
    final now = DateTime.now();

    final wasBirthday = _isBirthdayToday;
    _isBirthdayToday = DateHelper.isBirthdayToday(birthDate, today: now);
    _currentAge = DateHelper.calculateAge(birthDate, today: now);
    _daysUntilBirthday = DateHelper.daysUntilNextBirthday(birthDate, today: now);

    if (_isBirthdayToday) {
      if (_currentGreeting.isEmpty || !wasBirthday) {
        final rand = Random();
        final template = AppConstants.birthdayGreetings[
            rand.nextInt(AppConstants.birthdayGreetings.length)];
        _currentGreeting = 'Selamat ulang tahun ke-$_currentAge, ${profile.name}! $template';
      }
    } else {
      _currentGreeting = '';
    }

    notifyListeners();
  }
}
