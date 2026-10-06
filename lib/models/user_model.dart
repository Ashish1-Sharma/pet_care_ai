class UserModel {
  final int id;
  final String name;
  final String email;
  final String profileImage;
  final int remainingScans;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.remainingScans,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',
      remainingScans: json['remainingScans'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'remainingScans': remainingScans,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? profileImage,
    int? remainingScans,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      remainingScans: remainingScans ?? this.remainingScans,
    );
  }
}
