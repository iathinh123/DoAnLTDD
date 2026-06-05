class GroupMessageModel {
  final String senderId;
  final String senderName;
  final String message;

  GroupMessageModel({
    required this.senderId,
    required this.senderName,
    required this.message,
  });

  factory GroupMessageModel.fromMap(
      Map<String, dynamic> map) {
    return GroupMessageModel(
      senderId: map["senderId"] ?? "",
      senderName: map["senderName"] ?? "",
      message: map["message"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "senderName": senderName,
      "message": message,
    };
  }
}