import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants.dart';

/// Pengelola Database SQLite Lokal
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  Future<Database>? _opening;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Cegah double open
    _opening ??= _initDB('catatan_keuangan.db').timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Timeout membuka database (15 detik)');
      },
    );
    try {
      _database = await _opening!;
      return _database!;
    } catch (e) {
      // Reset agar retry bisa dilakukan
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Timeout getDatabasesPath'),
    );
    final path = join(dbPath, filePath);

    try {
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onConfigure: _configureDB,
      );
    } catch (e) {
      debugPrint('Gagal openDatabase: $e');
      // Jika file korup, coba hapus dan buka ulang sekali
      if (e.toString().contains('database disk image is malformed') ||
          e.toString().contains('file is not a database') ||
          e.toString().contains('database is locked')) {
        try {
          await deleteDatabase(path);
          debugPrint('Database korup dihapus, mencoba buka ulang');
          return await openDatabase(
            path,
            version: 1,
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
            onConfigure: _configureDB,
          );
        } catch (e2) {
          debugPrint('Retry gagal: $e2');
        }
      }
      rethrow;
    }
  }

  Future<void> _configureDB(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      debugPrint('Pragma foreign_keys gagal: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel Profil
    await db.execute('''
      CREATE TABLE profil (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        pin_hash TEXT,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        theme_mode TEXT NOT NULL DEFAULT 'system',
        is_muted INTEGER NOT NULL DEFAULT 0,
        last_backup_date TEXT
      )
    ''');

    // Tabel Dompet
    await db.execute('''
      CREATE TABLE dompet (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Tabel Kategori
    await db.execute('''
      CREATE TABLE kategori (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER,
        wallet_id INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT,
        tags TEXT,
        location TEXT,
        FOREIGN KEY (category_id) REFERENCES kategori (id) ON DELETE SET NULL,
        FOREIGN KEY (wallet_id) REFERENCES dompet (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Foto Bukti
    await db.execute('''
      CREATE TABLE foto_bukti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transaksi (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Target Tabungan
    await db.execute('''
      CREATE TABLE target_tabungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'active',
        reached_at TEXT,
        is_confirmed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed Data Awal
    await _seedInitialData(db);
  }

  Map<String, dynamic> _categoryRow(Map<String, dynamic> src, String type) {
    int iconCode = 0;
    String? fontFamily;
    int colorVal = 0xFF64748B;
    try {
      final icon = src['icon'];
      if (icon is IconData) {
        iconCode = icon.codePoint;
        fontFamily = icon.fontFamily;
      } else if (src['icon_code_point'] is int) {
        iconCode = src['icon_code_point'] as int;
        fontFamily = src['icon_font_family'] as String?;
      }
    } catch (_) {}
    try {
      final c = src['color'];
      if (c is Color) {
        colorVal = c.toARGB32();
      } else if (c is int) {
        colorVal = c;
      }
    } catch (_) {}
    if (iconCode == 0) iconCode = Icons.category.codePoint;

    return {
      'name': src['name'] as String? ?? 'Kategori',
      'type': type,
      'icon_code_point': iconCode,
      'icon_font_family': fontFamily,
      'color_value': colorVal,
    };
  }

  Future<void> _seedInitialData(Database db) async {
    try {
      // Seed Dompet Default
      for (final wallet in AppConstants.defaultWallets) {
        try {
          await db.insert('dompet', {
            'name': wallet['name'],
            'initial_balance': wallet['initialBalance'],
          });
        } catch (e) {
          debugPrint('Seed wallet gagal ${wallet['name']}: $e');
        }
      }

      // Seed Kategori Pengeluaran
      for (final cat in AppConstants.defaultExpenseCategories) {
        try {
          await db.insert('kategori', _categoryRow(cat, 'expense'));
        } catch (e) {
          debugPrint('Seed kategori expense gagal ${cat['name']}: $e');
        }
      }

      // Seed Kategori Pemasukan
      for (final cat in AppConstants.defaultIncomeCategories) {
        try {
          await db.insert('kategori', _categoryRow(cat, 'income'));
        } catch (e) {
          debugPrint('Seed kategori income gagal ${cat['name']}: $e');
        }
      }
    } catch (e, st) {
      debugPrint('Seed initial data error: $e\n$st');
      // Jangan lempar agar onCreate tetap sukses walau seed sebagian gagal
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Tempat penanganan migrasi skema di masa depan tanpa menghilangkan data pengguna
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _opening = null;
    }
  }

  // Untuk retry layar error
  void resetForRetry() {
    _opening = null;
  }
}
