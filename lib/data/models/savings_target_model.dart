/// Model data target tabungan
class SavingsTargetModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String status; // 'active', 'reached', 'archived'
  final DateTime? reachedAt;
  final bool isConfirmed; // Apakah dialog tercapai sudah dijawab pengguna

  SavingsTargetModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.status = 'active',
    this.reachedAt,
    this.isConfirmed = false,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final percent = (currentAmount / targetAmount) * 100.0;
    return percent;
  }

  bool get isReached => currentAmount >= targetAmount && targetAmount > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'status': status,
      'reached_at': reachedAt?.toIso8601String(),
      'is_confirmed': isConfirmed ? 1 : 0,
    };
  }

  factory SavingsTargetModel.fromMap(Map<String, dynamic> map) {
    return SavingsTargetModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'active',
      reachedAt: map['reached_at'] != null
          ? DateTime.tryParse(map['reached_at'] as String)
          : null,
      isConfirmed: (map['is_confirmed'] as int? ?? 0) == 1,
    );
  }

  SavingsTargetModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? status,
    DateTime? reachedAt,
    bool? isConfirmed,
  }) {
    return SavingsTargetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      status: status ?? this.status,
      reachedAt: reachedAt ?? this.reachedAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}
