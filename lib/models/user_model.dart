class UserModel {
  final String name;
  final String email;
  final String avatarUrl;
  final String password;
  final String role;
  UserModel({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.avatarUrl = "",
  });
}