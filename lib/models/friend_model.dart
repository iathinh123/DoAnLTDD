class FriendModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;

  FriendModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  factory FriendModel.fromMap(
      String uid,
      Map<String, dynamic> map,
      ) {
    return FriendModel(
      uid: uid,
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      avatarUrl: map["avatarUrl"] ?? "",
    );
  }
}