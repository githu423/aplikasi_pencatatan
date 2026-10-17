import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants.dart';

/// Pengelola Database SQLite Lokal
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('catatan_keuangan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Aktifkan foreign key cascade
    await db.execute('PRAGMA foreign_keys = ON');
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
        type TEXT NOT NULL, -- 'income' atau 'expense'
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, -- 'income', 'expense', 'savings_deposit'
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
        status TEXT NOT NULL DEFAULT 'active', -- 'active', 'reached', 'archived'
        reached_at TEXT,
        is_confirmed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed Data Awal
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed Dompet Default
    for (final wallet in AppConstants.defaultWallets) {
      await db.insert('dompet', {
        'name': wallet['name'],
        'initial_balance': wallet['initialBalance'],
      });
    }

    // Seed Kategori Pengeluaran
    for (final cat in AppConstants.defaultExpenseCategories) {
      await db.insert('kategori', {
        'name': cat['name'],
        'type': 'expense',
        'icon_code_point': cat['icon'].codePoint,
        'icon_font_family': cat['icon'].fontFamily,
        'color_value': cat['color'].value,
      });
    }

    // Seed Kategori Pemasukan
    for (final cat in AppConstants.defaultIncomeCategories) {
      await db.insert('kategori', {
        'name': cat['name'],
        'type': 'income',
        'icon_code_point': cat['icon'].codePoint,
        'icon_font_family': cat['icon'].fontFamily,
        'color_value': cat['color'].value,
      });
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
    }
  }
}
