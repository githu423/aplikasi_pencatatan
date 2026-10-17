import 'photo_model.dart';

/// Model data transaksi keuangan
class TransactionModel {
  final int? id;
  final String type; // 'income', 'expense', 'savings_deposit'
  final double amount;
  final int? categoryId;
  final String? categoryName;
  final int? categoryIconCode;
  final int? categoryColorValue;
  final int walletId;
  final String? walletName;
  final DateTime dateTime;
  final String title;
  final String? notes;
  final String? tags;
  final String? location;
  final List<PhotoModel> photos;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    this.categoryId,
    this.categoryName,
    this.categoryIconCode,
    this.categoryColorValue,
    required this.walletId,
    this.walletName,
    required this.dateTime,
    required this.title,
    this.notes,
    this.tags,
    this.location,
    this.photos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'wallet_id': walletId,
      'date_time': dateTime.toIso8601String(),
      'title': title,
      'notes': notes,
      'tags': tags,
      'location': location,
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    List<PhotoModel> photos = const [],
  }) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      categoryIconCode: map['category_icon_code'] as int?,
      categoryColorValue: map['category_color_value'] as int?,
      walletId: map['wallet_id'] as int? ?? 1,
      walletName: map['wallet_name'] as String?,
      dateTime: map['date_time'] != null
          ? DateTime.tryParse(map['date_time'] as String) ?? DateTime.now()
          : DateTime.now(),
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String?,
      tags: map['tags'] as String?,
      location: map['location'] as String?,
      photos: photos,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    double? amount,
    int? categoryId,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorValue,
    int? walletId,
    String? walletName,
    DateTime? dateTime,
    String? title,
    String? notes,
    String? tags,
    String? location,
    List<PhotoModel>? photos,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      dateTime: dateTime ?? this.dateTime,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      photos: photos ?? this.photos,
    );
  }
}
