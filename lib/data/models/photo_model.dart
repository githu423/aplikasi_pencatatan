/// Model data foto bukti transaksi
class PhotoModel {
  final int? id;
  final int transactionId;
  final String filePath;

  PhotoModel({
    this.id,
    required this.transactionId,
    required this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'file_path': filePath,
    };
  }

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int? ?? 0,
      filePath: map['file_path'] as String? ?? '',
    );
  }

  PhotoModel copyWith({
    int? id,
    int? transactionId,
    String? filePath,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      filePath: filePath ?? this.filePath,
    );
  }
}
