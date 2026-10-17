import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/currency_format.dart';
import '../../core/date_helper.dart';
import '../../data/models/category_model.dart';
import '../../data/models/photo_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/photo_viewer_dialog.dart';

/// Formulir Tambah dan Edit Transaksi (Pemasukan, Pengeluaran, Setor Tabungan)
class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? initialTransaction;

  const TransactionFormScreen({super.key, this.initialTransaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType; // 'expense', 'income', 'savings_deposit'
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  CategoryModel? _selectedCategory;
  WalletModel? _selectedWallet;
  DateTime _selectedDateTime = DateTime.now();

  // Foto bukti
  final List<String> _newPhotoPaths = []; // Foto baru dari kamera/galeri
  final List<PhotoModel> _existingPhotos = []; // Foto lama jika mode edit
  final List<PhotoModel> _deletedPhotos = []; // Foto lama yang dihapus pengguna

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    if (tx != null) {
      _selectedType = tx.type;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _titleController.text = tx.title;
      _notesController.text = tx.notes ?? '';
      _tagsController.text = tx.tags ?? '';
      _locationController.text = tx.location ?? '';
      _selectedDateTime = tx.dateTime;
      _existingPhotos.addAll(tx.photos);
    } else {
      _selectedType = 'expense';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSelections();
    });
  }

  void _initSelections() {
    final repo = context.read<FinanceRepository>();
    final tx = widget.initialTransaction;

    if (tx != null) {
      if (tx.categoryId != null) {
        final matches = repo.categories.where((c) => c.id == tx.categoryId);
        if (matches.isNotEmpty) {
          _selectedCategory = matches.first;
        }
      }
      final walletMatches = repo.wallets.where((w) => w.id == tx.walletId);
      if (walletMatches.isNotEmpty) {
        _selectedWallet = walletMatches.first;
      }
    } else {
      // Default kategori pertama yang sesuai
      _setDefaultCategoryForType(_selectedType);
      if (repo.wallets.isNotEmpty) {
        _selectedWallet = repo.wallets.first;
      }
    }
    setState(() {});
  }

  void _setDefaultCategoryForType(String type) {
    final repo = context.read<FinanceRepository>();
    final matchingCategories = repo.categories.where((c) => c.type == type).toList();
    if (matchingCategories.isNotEmpty) {
      _selectedCategory = matchingCategories.first;
    } else {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Kompres otomatis resolusi dan kualitas gambar saat diambil
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newPhotoPaths.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    final repo = context.read<FinanceRepository>();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final title = _titleController.text.trim();

    final tx = TransactionModel(
      id: widget.initialTransaction?.id,
      type: _selectedType,
      amount: amount,
      categoryId: _selectedCategory?.id,
      walletId: _selectedWallet!.id!,
      dateTime: _selectedDateTime,
      title: title,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    );

    if (widget.initialTransaction == null) {
      // Transaksi baru
      await repo.addTransaction(tx, _newPhotoPaths);
    } else {
      // Perbarui transaksi yang ada
      await repo.updateTransaction(
        tx,
        newPhotoPaths: _newPhotoPaths,
        deletedPhotos: _deletedPhotos,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<FinanceRepository>();
    final isEditing = widget.initialTransaction != null;

    final typeColor = _selectedType == 'income'
        ? const Color(0xFF10B981)
        : _selectedType == 'savings_deposit'
            ? const Color(0xFF8B5CF6)
            : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaksi' : 'Catat Transaksi'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Jenis Transaksi
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTypeButton('expense', 'Pengeluaran', const Color(0xFFEF4444)),
                    _buildTypeButton('income', 'Pemasukan', const Color(0xFF10B981)),
                    _buildTypeButton('savings_deposit', 'Setor Tabungan', const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nominal Input Besar
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nominal Transaksi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        autofocus: !isEditing,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                        decoration: const InputDecoration(
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '0',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nominal wajib diisi';
                          }
                          final num = double.tryParse(val);
                          if (num == null || num <= 0) {
                            return 'Nominal harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Judul Transaksi
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul / Keperluan',
                  hintText: 'Misal: Nasi Padang Siang, Bensin, Gaji Pokok',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul transaksi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Kategori (Hanya jika bukan savings_deposit)
              if (_selectedType != 'savings_deposit') ...[
                DropdownButtonFormField<CategoryModel>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: repo.categories
                      .where((c) => c.type == _selectedType)
                      .map((cat) {
                    return DropdownMenuItem<CategoryModel>(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, color: cat.color, size: 20),
                          const SizedBox(width: 10),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  validator: (val) {
                    if (val == null && _selectedType != 'savings_deposit') {
                      return 'Pilih salah satu kategori';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Pilihan Dompet
              DropdownButtonFormField<WalletModel>(
                value: _selectedWallet,
                decoration: const InputDecoration(
                  labelText: 'Dompet / Rekening',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: repo.wallets.map((w) {
                  return DropdownMenuItem<WalletModel>(
                    value: w,
                    child: Text('${w.name} (Saldo: ${CurrencyFormat.toRupiah(w.currentBalance)})'),
                  );
                }).toList(),
                onChanged: (w) {
                  setState(() {
                    _selectedWallet = w;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Tanggal & Waktu
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal & Waktu',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateHelper.formatDateTime(_selectedDateTime)),
                      const Icon(Icons.access_time, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Lokasi / Toko
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Toko (Opsional)',
                  hintText: 'Misal: Superindo, SPBU Shell, Tokopedia',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Tag
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tag (Opsional, pisahkan koma)',
                  hintText: 'Misal: bulanan, liburan, darurat',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 14),

              // Catatan Detail
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Foto Bukti Transaksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto Bukti / Struk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        tooltip: 'Ambil dari Kamera',
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        tooltip: 'Pilih dari Galeri',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Daftar Foto Pratinjau
              if (_existingPhotos.isEmpty && _newPhotoPaths.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey),
                      SizedBox(height: 6),
                      Text('Belum ada foto bukti yang dilampirkan', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Foto Lama (mode edit)
                    ..._existingPhotos.map((p) {
                      return _buildPhotoThumbnail(
                        path: p.filePath,
                        onDelete: () {
                          setState(() {
                            _existingPhotos.remove(p);
                            _deletedPhotos.add(p);
                          });
                        },
                      );
                    }),
                    // Foto Baru
                    ..._newPhotoPaths.map((p) {
                      return _buildPhotoThumbnail(
                        path: p,
                        onDelete: () {
                          setState(() {
                            _newPhotoPaths.remove(p);
                          });
                        },
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  isEditing ? 'Simpan Perubahan' : 'Catat Transaksi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _setDefaultCategoryForType(type);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail({required String path, required VoidCallback onDelete}) {
    final file = File(path);
    return Stack(
      children: [
        GestureDetector(
          onTap: () => PhotoViewerDialog.show(context, path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80,
              height: 80,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
                    ),
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
