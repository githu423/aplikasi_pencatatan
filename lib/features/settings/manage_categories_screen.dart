import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/finance_repository.dart';

/// Halaman Pengelolaan Kategori Pengeluaran & Pemasukan
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<IconData> _availableIcons = [
    Icons.restaurant_outlined,
    Icons.directions_car_outlined,
    Icons.shopping_bag_outlined,
    Icons.receipt_long_outlined,
    Icons.school_outlined,
    Icons.sports_esports_outlined,
    Icons.medical_services_outlined,
    Icons.flight_takeoff_outlined,
    Icons.home_outlined,
    Icons.fitness_center_outlined,
    Icons.pets_outlined,
    Icons.coffee_outlined,
    Icons.local_gas_station_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.payments_outlined,
    Icons.card_giftcard_outlined,
    Icons.storefront_outlined,
    Icons.savings_outlined,
    Icons.work_outline,
    Icons.more_horiz_outlined,
  ];

  final List<Color> _availableColors = [
    const Color(0xFFEF4444),
    const Color(0xFFF97316),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF14B8A6),
    const Color(0xFF06B6D4),
    const Color(0xFF3B82F6),
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF64748B),
    const Color(0xFF475569),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditDialog(BuildContext context, {CategoryModel? category, required String defaultType}) {
    final repo = context.read<FinanceRepository>();
    final nameController = TextEditingController(text: category?.name ?? '');
    IconData selectedIcon = category?.icon ?? _availableIcons.first;
    Color selectedColor = category?.color ?? _availableColors.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'Misal: Kopi & Nongkrong',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 130,
                      width: double.maxFinite,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _availableIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _availableIcons[index];
                          final isSelected = icon == selectedIcon;
                          return InkWell(
                            onTap: () => setDialogState(() => selectedIcon = icon),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? selectedColor.withOpacity(0.2) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? selectedColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(icon, color: isSelected ? selectedColor : Colors.grey.shade700),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pilih Warna:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = color.toARGB32() == selectedColor.toARGB32();
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = color),
                          shape: const CircleBorder(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    if (category == null) {
                      final newCat = CategoryModel(
                        name: name,
                        type: defaultType,
                        iconCodePoint: selectedIcon.codePoint,
                        iconFontFamily: selectedIcon.fontFamily,
                        colorValue: selectedColor.toARGB32(),
                      );
                      await repo.addCategory(newCat);
                    } else {
                      final updated = category.copyWith(
                        name: name,
                        iconCodePoint: selectedIcon.codePoint,
                        iconFontFamily: selectedIcon.fontFamily,
                        colorValue: selectedColor.toARGB32(),
                      );
                      await repo.updateCategory(updated);
                    }

                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Kategori?'),
          content: Text(
            'Apakah kamu yakin ingin menghapus kategori "${cat.name}"? Transaksi dengan kategori ini akan tetap aman namun kategorinya akan menjadi tidak terdefinisi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final repo = context.read<FinanceRepository>();
                await repo.deleteCategory(cat.id!);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();

    final expenseCategories = repo.categories.where((c) => c.type == 'expense').toList();
    final incomeCategories = repo.categories.where((c) => c.type == 'income').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(expenseCategories, 'expense'),
          _buildCategoryList(incomeCategories, 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentType = _tabController.index == 0 ? 'expense' : 'income';
          _showAddEditDialog(context, defaultType: currentType);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, String type) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cat.color.withOpacity(0.15),
              child: Icon(cat.icon, color: cat.color),
            ),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showAddEditDialog(context, category: cat, defaultType: type),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _confirmDeleteCategory(context, cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
