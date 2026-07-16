/// Cờ điều hướng khi đang đăng xuất.
///
/// Cho phép tạm thời ở `/login` dù Firebase vẫn còn session,
/// để GoRouter dispose `/home` (MapScreen) trước khi auth = null.
class AuthNavigation {
  AuthNavigation._();

  static bool isSigningOut = false;
}
