class AppUser {
  final String uid;
  final String username;
  final String role;
  final String? phone;
  final bool forcePasswordChange;
  final bool active;

  AppUser({
    required this.uid,
    required this.username,
    required this.role,
    this.phone,
    required this.forcePasswordChange,
    required this.active,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      username: data["username"],
      role: data["role"],
      phone: data["phone"],
      forcePasswordChange: data["forcePasswordChange"] ?? false,
      active: data["active"] ?? true,
    );
  }
}
