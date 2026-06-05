class GroupJarModel {
  final String id;
  final String name;
  final String description;
  final double target;
  final double currentAmount;
  final String createdBy;
  final bool isCompleted;

  GroupJarModel({
    required this.id,
    required this.name,
    required this.description,
    required this.target,
    required this.currentAmount,
    required this.createdBy,
    required this.isCompleted,
  });

  factory GroupJarModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return GroupJarModel(
      id: id,
      name: map["name"] ?? "",
      description: map["description"] ?? "",
      target: (map["target"] ?? 0).toDouble(),
      currentAmount:
      (map["currentAmount"] ?? 0).toDouble(),
      createdBy: map["createdBy"] ?? "",
      isCompleted:
      map["isCompleted"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "target": target,
      "currentAmount": currentAmount,
      "createdBy": createdBy,
      "isCompleted": isCompleted,
    };
  }
}