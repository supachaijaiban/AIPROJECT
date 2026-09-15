enum UserRole { user, approver, admin }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.user,
  );
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String department;
  final UserRole role;
  final double allowanceTotal;
  final double allowanceRemaining;
  final List<String> allowedCategories;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.allowanceTotal,
    required this.allowanceRemaining,
    required this.allowedCategories,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      department: map['department'] as String? ?? '',
      role: userRoleFromString(map['role'] as String? ?? 'user'),
      allowanceTotal: (map['allowance_total'] as num?)?.toDouble() ?? 0,
      allowanceRemaining: (map['allowance_remaining'] as num?)?.toDouble() ?? 0,
      allowedCategories: List<String>.from(map['allowed_categories'] as List? ?? const []),
    );
  }
}
