class ContributionModel {
  final String uid;
  final String name;
  final double amount;

  ContributionModel({
    required this.uid,
    required this.name,
    required this.amount,
  });

  factory ContributionModel.fromMap(
      Map<String, dynamic> map) {
    return ContributionModel(
      uid: map["uid"] ?? "",
      name: map["name"] ?? "",
      amount: (map["amount"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "amount": amount,
    };
  }
}