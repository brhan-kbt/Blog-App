class UserRef {
  final int id;
  final String name;
  final String email;

  const UserRef({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserRef.fromJson(Map<String, dynamic> json) {
    return UserRef(
      id: json['id'] as int,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
