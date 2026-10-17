import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/database.dart';

/// Layanan Pencadangan (Backup) dan Pemulihan (Restore) 100% Offline via ZIP
class BackupService {
  /// Ekspor seluruh data (Database SQLite, Pengaturan SharedPreferences, dan Foto Bukti) ke file ZIP
  static Future<String?> exportBackup() async {
    try {
      final archive = Archive();

      // 1. Ambil file database SQLite
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, 'catatan_keuangan.db'));
      if (await dbFile.exists()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile('catatan_keuangan.db', dbBytes.length, dbBytes));
      }

      // 2. Ambil seluruh SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final Map<String, dynamic> prefsMap = {};
      for (final key in allKeys) {
        prefsMap[key] = prefs.get(key);
      }
      final prefsJson = jsonEncode(prefsMap);
      final prefsBytes = utf8.encode(prefsJson);
      archive.addFile(ArchiveFile('preferences.json', prefsBytes.length, prefsBytes));

      // 3. Ambil seluruh foto bukti di direktori receipt_photos
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (await photosDir.exists()) {
        final photoEntities = photosDir.listSync();
        for (final entity in photoEntities) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            final photoBytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile('receipt_photos/$fileName', photoBytes.length, photoBytes));
          }
        }
      }

      // 4. Kompresi ke format ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final zipFilePath = p.join(tempDir.path, 'Catatan_Keuangan_Backup_$nowStr.zip');
      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipBytes);

      // Bagikan file ZIP
      await Share.shareXFiles(
        [XFile(zipFilePath)],
        text: 'Berkas Cadangan Catatan Keuangan ($nowStr)',
      );

      // Simpan tanggal terakhir backup
      final prefsInst = await SharedPreferences.getInstance();
      await prefsInst.setString('last_backup_date', DateTime.now().toIso8601String());

      return zipFilePath;
    } catch (e) {
      return null;
    }
  }

  /// Impor / Pulihkan data dari file ZIP yang dipilih pengguna
  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final backupFilePath = result.files.single.path!;
      final backupFile = File(backupFilePath);
      final bytes = await backupFile.readAsBytes();

      final archive = ZipDecoder().decodeBytes(bytes);

      // Tutup koneksi database terlebih dahulu sebelum menimpa
      await AppDatabase.instance.close();

      final dbPath = await getDatabasesPath();
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          if (filename == 'catatan_keuangan.db') {
            final targetDbFile = File(p.join(dbPath, 'catatan_keuangan.db'));
            await targetDbFile.writeAsBytes(data, flush: true);
          } else if (filename == 'preferences.json') {
            final jsonStr = utf8.decode(data);
            final Map<String, dynamic> prefsMap = jsonDecode(jsonStr);
            final prefs = await SharedPreferences.getInstance();
            for (final entry in prefsMap.entries) {
              if (entry.value is bool) {
                await prefs.setBool(entry.key, entry.value as bool);
              } else if (entry.value is int) {
                await prefs.setInt(entry.key, entry.value as int);
              } else if (entry.value is double) {
                await prefs.setDouble(entry.key, entry.value as double);
              } else if (entry.value is String) {
                await prefs.setString(entry.key, entry.value as String);
              }
            }
          } else if (filename.startsWith('receipt_photos/')) {
            final photoName = p.basename(filename);
            final targetPhoto = File(p.join(photosDir.path, photoName));
            await targetPhoto.writeAsBytes(data, flush: true);
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Periksa apakah pengingat bulanan harus ditampilkan
  static Future<bool> shouldShowMonthlyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString('last_backup_date');
    if (lastBackupStr == null) return true; // Belum pernah backup

    final lastDate = DateTime.tryParse(lastBackupStr);
    if (lastDate == null) return true;

    final diff = DateTime.now().difference(lastDate).inDays;
    return diff >= 30; // Sudah lebih dari 30 hari
  }
}
