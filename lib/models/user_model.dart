class UserModel {
  final String name;
  final String email;
  final String avatarUrl;

  UserModel({
    required this.name,
    required this.email,
    this.avatarUrl = "",
  });
}