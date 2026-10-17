import 'package:flutter/material.dart';

/// Model data kategori transaksi
class CategoryModel {
  final int? id;
  final String name;
  final String type; // 'income' atau 'expense'
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
  });

  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
      );

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'color_value': colorValue,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      iconCodePoint: map['icon_code_point'] as int? ?? Icons.category.codePoint,
      iconFontFamily: map['icon_font_family'] as String?,
      colorValue: map['color_value'] as int? ?? Colors.grey.value,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? type,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
