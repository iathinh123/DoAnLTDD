class TransactionModel {
  String id;
  double amount;
  String category;
  String note;
  int type; // 0: chi, 1: thu, 2: vay/nợ
  DateTime date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.type,
    required this.date,
  });

  // ================= TO MAP (Lưu lên Firestore) =================
  Map<String, dynamic> toMap() {
    return {
      'amount': amount.abs(), // Luôn lưu giá trị dương trên Firestore để dễ quản lý dữ liệu gốc
      'category': category,
      'note': note,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  // ================= FROM MAP (Lấy về từ Firestore) =================
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    double amt = (map['amount'] ?? 0).toDouble();
    int tType = map['type'] ?? 0;

    if (tType == 0) {
      amt = -amt.abs();
    }
    else if (tType == 2) {
      if (map['category'] == "Trả nợ" || map['category'] == "Cho vay") {
        amt = -amt.abs();
      }
    }

    return TransactionModel(
      id: id,
      amount: amt,
      category: map['category'] ?? "Khác",
      date: _parseDate(map['date']),
      type: tType,
      note: map['note'] ?? "",
    );
  }

  // ================= HANDLE DATE (Xử lý ngày tháng) =================
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    if (value.runtimeType.toString() == 'Timestamp') {
      return value.toDate();
    }

    return DateTime.now();
  }
}