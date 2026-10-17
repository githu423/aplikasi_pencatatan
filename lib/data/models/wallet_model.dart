/// Model data dompet / rekening
class WalletModel {
  final int? id;
  final String name;
  final double initialBalance;
  final double currentBalance;

  WalletModel({
    this.id,
    required this.name,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map, {double currentBalance = 0.0}) {
    return WalletModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: currentBalance,
    );
  }

  WalletModel copyWith({
    int? id,
    String? name,
    double? initialBalance,
    double? currentBalance,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
