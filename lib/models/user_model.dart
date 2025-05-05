class UserModel {
  final int id;
  final String name;
  final String email;
  final String userType; // "Buyer" або "Seller"

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['username'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? '',
    );
  }
}
