class UserRole {
  UserRole._();

  static const user = 'user';
  static const admin = 'admin';

  static bool isAdmin(String? role) =>
      role?.trim().toLowerCase() == admin;

  static bool isUser(String? role) =>
      role?.trim().toLowerCase() == user;

  static String homeRouteFor(String? role) {
    if (isAdmin(role)) return '/admin';
    return '/home';
  }
}
