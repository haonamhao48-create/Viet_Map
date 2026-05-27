/// Các hằng số toàn cục của ứng dụng Viet Map.
///
/// Tập trung tất cả magic numbers, breakpoints, padding values
/// vào một nơi để dễ bảo trì và nhất quán toàn app.
library;

/// Breakpoints cho responsive layout.
class AppBreakpoints {
  AppBreakpoints._();

  /// Màn hình nhỏ hơn giá trị này được coi là mobile.
  static const double mobile = 600;

  /// Màn hình nhỏ hơn giá trị này được coi là tablet.
  static const double tablet = 1024;
}

/// Padding/spacing chuẩn trong toàn app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Border radius chuẩn.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Thời gian animation chuẩn.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
