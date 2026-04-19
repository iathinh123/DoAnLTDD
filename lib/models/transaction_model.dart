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

  // ================= TO MAP =================
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'note': note,
      'type': type,
      'date': date.toIso8601String(), // lưu dạng String
    };
  }

  // ================= FROM MAP =================
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    double amt = (map['amount'] ?? 0).toDouble();

    // Kiểm tra nếu là loại Vay/Nợ (type 2)
    if (map['type'] == 2) {
      // Nếu là "Trả nợ" hoặc "Cho vay" -> Ép thành số âm để Chart hiện xuống dưới
      if (map['category'] == "Trả nợ" || map['category'] == "Cho vay") {
        amt = -amt;
      }
    }

    return TransactionModel(
      id: id,
      amount: amt,
      category: map['category'] ?? "Khác",
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      type: map['type'] ?? 0,
      note: map['note'] ?? "",
    );
  }

  // ================= HANDLE DATE =================
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    // Nếu là String
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    // Nếu là Timestamp (Firestore)
    if (value.runtimeType.toString() == 'Timestamp') {
      return value.toDate();
    }

    return DateTime.now();
  }
}