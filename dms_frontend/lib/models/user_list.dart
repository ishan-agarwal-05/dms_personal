// lib/models/user.dart
class User {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String status;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.status,
  });

  // Factory constructor to create a User object from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  // Helper to convert User object to JSON map (useful if you send data back)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'status': status,
    };
  }
}
