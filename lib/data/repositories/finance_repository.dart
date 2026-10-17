import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/category_model.dart';
import '../models/photo_model.dart';
import '../models/profile_model.dart';
import '../models/savings_target_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Repository utama yang mengelola seluruh data aplikasi dengan ChangeNotifier
class FinanceRepository extends ChangeNotifier {
  final AppDatabase _dbHelper = AppDatabase.instance;

  ProfileModel? _profile;
  List<WalletModel> _wallets = [];
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  SavingsTargetModel? _activeSavingsTarget;
  List<SavingsTargetModel> _savingsHistory = [];

  bool _isLoading = true;
  SavingsTargetModel? _pendingReachedTarget; // Target yang memicu dialog tercapai

  ProfileModel? get profile => _profile;
  List<WalletModel> get wallets => _wallets;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  SavingsTargetModel? get activeSavingsTarget => _activeSavingsTarget;
  List<SavingsTargetModel> get savingsHistory => _savingsHistory;
  bool get isLoading => _isLoading;
  SavingsTargetModel? get pendingReachedTarget => _pendingReachedTarget;

  // ================= SALDO & RINGKASAN =================

  /// Total saldo semua dompet (Saldo Awal + Pemasukan - Pengeluaran - Setoran Tabungan)
  double get totalBalance {
    double total = 0.0;
    for (final wallet in _wallets) {
      total += wallet.currentBalance;
    }
    return total;
  }

  /// Pemasukan bulan ini
  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'income' &&
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Pengeluaran bulan ini
  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// 5 Transaksi terakhir
  List<TransactionModel> get recentTransactions {
    final list = List<TransactionModel>.from(_transactions);
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list.take(5).toList();
  }

  // ================= INISIALISASI =================

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await loadProfile();
    await loadCategories();
    await loadTransactions();
    await loadWallets(); // membutuhkan transactions untuk menghitung saldo berjalan
    await loadSavingsTargets();
    _checkSavingsTargetReached();

    _isLoading = false;
    notifyListeners();
  }

  // ================= PROFIL =================

  Future<void> loadProfile() async {
    final db = await _dbHelper.database;
    final res = await db.query('profil', limit: 1);
    if (res.isNotEmpty) {
      _profile = ProfileModel.fromMap(res.first);
    } else {
      // Inisialisasi profil default bila belum ada
      final defaultProfile = ProfileModel(
        name: 'Pengguna',
        birthDate: DateTime(2000, 1, 1),
      );
      final id = await db.insert('profil', defaultProfile.toMap());
      _profile = defaultProfile.copyWith(id: id);
    }
    notifyListeners();
  }

  Future<void> updateProfile(ProfileModel updated) async {
    final db = await _dbHelper.database;
    if (_profile?.id != null) {
      await db.update(
        'profil',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [_profile!.id],
      );
    } else {
      final id = await db.insert('profil', updated.toMap());
      updated = updated.copyWith(id: id);
    }
    _profile = updated;
    notifyListeners();
  }

  Future<void> updatePin(String? pinHash, bool biometricEnabled) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      pinHash: pinHash,
      biometricEnabled: biometricEnabled,
    );
    await updateProfile(updated);
  }

  Future<void> toggleMute() async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(isMuted: !_profile!.isMuted);
    await updateProfile(updated);
  }

  // ================= DOMPET =================

  Future<void> loadWallets() async {
    final db = await _dbHelper.database;
    final res = await db.query('dompet');
    
    _wallets = res.map((map) {
      final id = map['id'] as int;
      final initialBalance = (map['initial_balance'] as num?)?.toDouble() ?? 0.0;
      
      // Hitung saldo berjalan dari transaksi
      double balance = initialBalance;
      for (final tx in _transactions) {
        if (tx.walletId == id) {
          if (tx.type == 'income') {
            balance += tx.amount;
          } else if (tx.type == 'expense' || tx.type == 'savings_deposit') {
            balance -= tx.amount;
          }
        }
      }

      return WalletModel.fromMap(map, currentBalance: balance);
    }).toList();

    notifyListeners();
  }

  Future<void> addWallet(String name, double initialBalance) async {
    final db = await _dbHelper.database;
    await db.insert('dompet', {
      'name': name,
      'initial_balance': initialBalance,
    });
    await loadWallets();
  }

  Future<void> updateWallet(int id, String name, double initialBalance) async {
    final db = await _dbHelper.database;
    await db.update(
      'dompet',
      {'name': name, 'initial_balance': initialBalance},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadWallets();
  }

  Future<void> deleteWallet(int id) async {
    final db = await _dbHelper.database;
    await db.delete('dompet', where: 'id = ?', whereArgs: [id]);
    await loadTransactions();
    await loadWallets();
  }

  // ================= KATEGORI =================

  Future<void> loadCategories() async {
    final db = await _dbHelper.database;
    final res = await db.query('kategori', orderBy: 'name ASC');
    _categories = res.map((m) => CategoryModel.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert('kategori', category.toMap());
    await loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.update(
      'kategori',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await loadCategories();
    await loadTransactions();
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete('kategori', where: 'id = ?', whereArgs: [id]);
    await loadCategories();
    await loadTransactions();
  }

  // ================= TRANSAKSI & FOTO BUKTI =================

  Future<void> loadTransactions() async {
    final db = await _dbHelper.database;
    // Join dengan kategori dan dompet untuk mendapatkan nama & icon
    final res = await db.rawQuery('''
      SELECT t.*, 
             k.name AS category_name, 
             k.icon_code_point AS category_icon_code, 
             k.color_value AS category_color_value,
             d.name AS wallet_name
      FROM transaksi t
      LEFT JOIN kategori k ON t.category_id = k.id
      LEFT JOIN dompet d ON t.wallet_id = d.id
      ORDER BY t.date_time DESC
    ''');

    final photoRes = await db.query('foto_bukti');
    final Map<int, List<PhotoModel>> photoMap = {};
    for (final p in photoRes) {
      final photo = PhotoModel.fromMap(p);
      photoMap.putIfAbsent(photo.transactionId, () => []).add(photo);
    }

    _transactions = res.map((m) {
      final txId = m['id'] as int;
      final photos = photoMap[txId] ?? [];
      return TransactionModel.fromMap(m, photos: photos);
    }).toList();

    notifyListeners();
  }

  /// Tambah transaksi beserta foto bukti yang disimpan ke berkas privat
  Future<void> addTransaction(TransactionModel tx, List<String> sourcePhotoPaths) async {
    final db = await _dbHelper.database;

    final txId = await db.insert('transaksi', tx.toMap());

    // Salin foto ke direktori aplikasi
    final savedPhotos = <PhotoModel>[];
    if (sourcePhotoPaths.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      for (int i = 0; i < sourcePhotoPaths.length; i++) {
        final srcPath = sourcePhotoPaths[i];
        final srcFile = File(srcPath);
        if (await srcFile.exists()) {
          final ext = p.extension(srcPath).isNotEmpty ? p.extension(srcPath) : '.jpg';
          final newFileName = 'tx_${txId}_${DateTime.now().millisecondsSinceEpoch}_$i$ext';
          final newFilePath = p.join(photoDir.path, newFileName);
          await srcFile.copy(newFilePath);

          final photoId = await db.insert('foto_bukti', {
            'transaction_id': txId,
            'file_path': newFilePath,
          });
          savedPhotos.add(PhotoModel(
            id: photoId,
            transactionId: txId,
            filePath: newFilePath,
          ));
        }
      }
    }

    // Jika jenisnya adalah setoran tabungan, tambahkan ke target tabungan aktif
    if (tx.type == 'savings_deposit' && _activeSavingsTarget != null) {
      await updateSavingsProgress(_activeSavingsTarget!.currentAmount + tx.amount);
    }

    await loadTransactions();
    await loadWallets();
    _checkSavingsTargetReached();
  }

  /// Perbarui transaksi dan perbarui daftar foto
  Future<void> updateTransaction(
    TransactionModel tx, {
    List<String> newPhotoPaths = const [],
    List<PhotoModel> deletedPhotos = const [],
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'transaksi',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );

    // Hapus foto yang dihapus dari filesystem dan database
    for (final photo in deletedPhotos) {
      final file = File(photo.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (photo.id != null) {
        await db.delete('foto_bukti', where: 'id = ?', whereArgs: [photo.id]);
      }
    }

    // Tambah foto baru
    if (newPhotoPaths.isNotEmpty && tx.id != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      for (int i = 0; i < newPhotoPaths.length; i++) {
        final srcPath = newPhotoPaths[i];
        final srcFile = File(srcPath);
        if (await srcFile.exists()) {
          final ext = p.extension(srcPath).isNotEmpty ? p.extension(srcPath) : '.jpg';
          final newFileName = 'tx_${tx.id}_${DateTime.now().millisecondsSinceEpoch}_$i$ext';
          final newFilePath = p.join(photoDir.path, newFileName);
          await srcFile.copy(newFilePath);

          await db.insert('foto_bukti', {
            'transaction_id': tx.id,
            'file_path': newFilePath,
          });
        }
      }
    }

    await loadTransactions();
    await loadWallets();
    _checkSavingsTargetReached();
  }

  /// Hapus transaksi beserta semua file foto fisiknya
  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;

    // Cari foto yang terkait untuk dihapus fisiknya
    final photos = await db.query(
      'foto_bukti',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    for (final pRow in photos) {
      final path = pRow['file_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    // Hapus dari database (akan cascade ke foto_bukti)
    await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);

    await loadTransactions();
    await loadWallets();
  }

  // ================= TARGET TABUNGAN =================

  Future<void> loadSavingsTargets() async {
    final db = await _dbHelper.database;
    final res = await db.query('target_tabungan', orderBy: 'id DESC');

    _savingsHistory = [];
    _activeSavingsTarget = null;

    for (final map in res) {
      final target = SavingsTargetModel.fromMap(map);
      if (target.status == 'active' && _activeSavingsTarget == null) {
        _activeSavingsTarget = target;
      } else {
        _savingsHistory.add(target);
      }
    }

    notifyListeners();
  }

  Future<void> createSavingsTarget(String name, double targetAmount, {double currentAmount = 0.0}) async {
    final db = await _dbHelper.database;

    // Jika ada target aktif lama, arsipkan
    if (_activeSavingsTarget != null) {
      await db.update(
        'target_tabungan',
        {'status': 'archived'},
        where: 'id = ?',
        whereArgs: [_activeSavingsTarget!.id],
      );
    }

    final newTarget = SavingsTargetModel(
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      status: 'active',
      isConfirmed: false,
    );

    final id = await db.insert('target_tabungan', newTarget.toMap());
    _activeSavingsTarget = newTarget.copyWith(id: id);
    _pendingReachedTarget = null;
    await loadSavingsTargets();
    _checkSavingsTargetReached();
  }

  Future<void> updateSavingsProgress(double newAmount) async {
    if (_activeSavingsTarget == null) return;
    final db = await _dbHelper.database;

    final updated = _activeSavingsTarget!.copyWith(currentAmount: newAmount);
    await db.update(
      'target_tabungan',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    _activeSavingsTarget = updated;
    notifyListeners();
    _checkSavingsTargetReached();
  }

  /// Pengecekan otomatis apakah target tercapai dan belum dikonfirmasi
  void _checkSavingsTargetReached() {
    if (_activeSavingsTarget != null) {
      if (_activeSavingsTarget!.isReached && !_activeSavingsTarget!.isConfirmed) {
        _pendingReachedTarget = _activeSavingsTarget;
      } else {
        _pendingReachedTarget = null;
      }
      notifyListeners();
    }
  }

  /// Pilihan 1 Dialog: Naikkan Target Tabungan
  Future<void> raiseSavingsTarget(double newTargetAmount) async {
    if (_activeSavingsTarget == null) return;
    final db = await _dbHelper.database;

    final updated = _activeSavingsTarget!.copyWith(
      targetAmount: newTargetAmount,
      isConfirmed: true,
      reachedAt: DateTime.now(),
    );

    await db.update(
      'target_tabungan',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );

    _pendingReachedTarget = null;
    await loadSavingsTargets();
  }

  /// Pilihan 2 Dialog: Ganti Target Baru (Target lama masuk riwayat tercapai)
  Future<void> changeSavingsTarget(String newName, double newTargetAmount) async {
    if (_activeSavingsTarget == null) return;
    final db = await _dbHelper.database;

    // Tandai target lama sebagai tercapai dan terkonfirmasi
    await db.update(
      'target_tabungan',
      {
        'status': 'reached',
        'is_confirmed': 1,
        'reached_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [_activeSavingsTarget!.id],
    );

    // Buat target baru
    final newTarget = SavingsTargetModel(
      name: newName,
      targetAmount: newTargetAmount,
      currentAmount: 0.0,
      status: 'active',
      isConfirmed: false,
    );
    await db.insert('target_tabungan', newTarget.toMap());

    _pendingReachedTarget = null;
    await loadSavingsTargets();
  }

  /// Pilihan 3 Dialog: Tandai Selesai dan Pakai Uangnya
  Future<void> markCompletedAndArchive({
    double? spendAmount,
    int? spendWalletId,
    String? spendNote,
    required String newTargetName,
    required double newTargetAmount,
  }) async {
    if (_activeSavingsTarget == null) return;
    final db = await _dbHelper.database;

    // Arsipkan target lama
    await db.update(
      'target_tabungan',
      {
        'status': 'archived',
        'is_confirmed': 1,
        'reached_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [_activeSavingsTarget!.id],
    );

    // Jika pengguna mencatat pengeluaran pembelian dari target
    if (spendAmount != null && spendAmount > 0 && spendWalletId != null) {
      final tx = TransactionModel(
        type: 'expense',
        amount: spendAmount,
        walletId: spendWalletId,
        dateTime: DateTime.now(),
        title: 'Membeli ${_activeSavingsTarget!.name}',
        notes: spendNote ?? 'Realisasi pencapaian target tabungan',
      );
      await addTransaction(tx, []);
    }

    // Buat target baru
    final newTarget = SavingsTargetModel(
      name: newTargetName,
      targetAmount: newTargetAmount,
      currentAmount: 0.0,
      status: 'active',
      isConfirmed: false,
    );
    await db.insert('target_tabungan', newTarget.toMap());

    _pendingReachedTarget = null;
    await loadSavingsTargets();
  }

  void clearPendingReachedTarget() {
    _pendingReachedTarget = null;
    notifyListeners();
  }
}
