class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final String password;
  final String role;
  final bool isBlocked;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.avatarUrl = "",
    this.isBlocked = false,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'user',
      avatarUrl: data['avatarUrl'] ?? '',
      isBlocked: data['isBlocked'] ?? false,
    );
  }
}