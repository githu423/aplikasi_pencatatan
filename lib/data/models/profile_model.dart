/// Model data profil pengguna
class ProfileModel {
  final int? id;
  final String name;
  final DateTime birthDate;
  final String? pinHash;
  final bool biometricEnabled;
  final String themeMode; // 'system', 'light', 'dark'
  final bool isMuted;
  final DateTime? lastBackupDate;

  ProfileModel({
    this.id,
    required this.name,
    required this.birthDate,
    this.pinHash,
    this.biometricEnabled = false,
    this.themeMode = 'system',
    this.isMuted = false,
    this.lastBackupDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate.toIso8601String(),
      'pin_hash': pinHash,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'theme_mode': themeMode,
      'is_muted': isMuted ? 1 : 0,
      'last_backup_date': lastBackupDate?.toIso8601String(),
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Pengguna',
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'] as String) ?? DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1),
      pinHash: map['pin_hash'] as String?,
      biometricEnabled: (map['biometric_enabled'] as int? ?? 0) == 1,
      themeMode: map['theme_mode'] as String? ?? 'system',
      isMuted: (map['is_muted'] as int? ?? 0) == 1,
      lastBackupDate: map['last_backup_date'] != null
          ? DateTime.tryParse(map['last_backup_date'] as String)
          : null,
    );
  }

  ProfileModel copyWith({
    int? id,
    String? name,
    DateTime? birthDate,
    String? pinHash,
    bool? biometricEnabled,
    String? themeMode,
    bool? isMuted,
    DateTime? lastBackupDate,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      pinHash: pinHash ?? this.pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themeMode: themeMode ?? this.themeMode,
      isMuted: isMuted ?? this.isMuted,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }
}
