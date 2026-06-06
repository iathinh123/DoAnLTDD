class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String note;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.note,
  });

  double get percent => targetAmount > 0 ? currentAmount / targetAmount : 0;
  double get remaining => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() => {
    "title": title,
    "targetAmount": targetAmount,
    "currentAmount": currentAmount,
    "deadline": deadline.toIso8601String(),
    "note": note,
  };

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> map) =>
      SavingsGoal(
        id: id,
        title: map["title"] ?? "",
        targetAmount: (map["targetAmount"] as num).toDouble(),
        currentAmount: (map["currentAmount"] as num).toDouble(),
        deadline: DateTime.parse(map["deadline"]),
        note: map["note"] ?? "",
      );
}