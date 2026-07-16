import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../utils/role_navigation.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  String? _errorMessage;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuart);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuart));

    // Delay micro pour laisser le premier frame se poser
    Timer(const Duration(milliseconds: 60), () {
      if (mounted) _animCtrl.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authLoadingProvider.notifier).state = false;

      if (AuthNavigation.isSigningOut) return;
      final authUser = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      if (authUser != null && profile != null) {
        navigateAfterLogin(context, ref);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  static const _tealDark = Color(0xFF0F766E);
  static const _inkDark = Color(0xFF0B1F1E);
  static const _white70 = Color(0xB3FFFFFF);
  static const _white40 = Color(0x66FFFFFF);

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;

    ref.listen<AsyncValue<AppUserModel?>>(currentUserProfileProvider, (
      previous,
      next,
    ) {
      if (!mounted || AuthNavigation.isSigningOut) return;

      final profile = next.valueOrNull;
      if (profile == null) return;

      final wasLoggedOut = previous?.valueOrNull == null;
      if (!wasLoggedOut) return;

      navigateAfterLogin(context, ref);
    });

    return Scaffold(
      backgroundColor: _inkDark,
      body: Row(
        children: [
          // ── Left panel: map image + teal overlay ──────────────────────
          if (!isMobile)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/data/vietnam_map_editorial_login.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Darker bottom-to-top fade so text at bottom pops
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _tealDark.withValues(alpha: 0.92),
                            _tealDark.withValues(alpha: 0.62),
                            Colors.black.withValues(alpha: 0.18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo mark
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'VIETMAP GIS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Accent rule
                          Container(
                            width: 40,
                            height: 3,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'HỆ THỐNG KHẢO SÁT\nBẢN ĐỒ THPT\nVIỆT NAM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: const Text(
                              'Số hóa dữ liệu thực địa hành chính cấp xã/phường. '
                              'Ghi chép nhật ký viếng thăm, đồng bộ thời gian thực '
                              'và quản lý tài nguyên khảo sát trực quan.',
                              style: TextStyle(
                                color: _white70,
                                fontSize: 15,
                                height: 1.65,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),

                          const Spacer(),

                          const Text(
                            '© Dự án Bản đồ Khảo sát THPT Việt Nam',
                            style: TextStyle(
                              color: _white40,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Right panel: login form ────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              color: _inkDark,
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isMobile)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.map_rounded,
                                      color: _tealDark,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'VIETMAP GIS',
                                      style: TextStyle(
                                        color: _tealDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox.shrink(),
                              const Text(
                                'v1.0.0',
                                style: TextStyle(
                                  color: Color(0x4DFFFFFF),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Login block
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Icon badge
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _tealDark.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _tealDark.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 32,
                                        color: _tealDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Heading
                                  const Text(
                                    'ĐĂNG NHẬP\nHỆ THỐNG',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 30,
                                      height: 1.1,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Accent divider
                                  Container(
                                    width: 32,
                                    height: 2,
                                    color: _tealDark,
                                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                                  ),

                                  // Subtitle
                                  const Text(
                                    'Sử dụng tài khoản Google công vụ được cấp phép để bắt đầu quy trình làm việc thực địa.',
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Error banner
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33FF4444),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0x55FF4444),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: Color(0xFFFF6B6B),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                color: Color(0xFFFFAAAA),
                                                fontSize: 13,
                                                height: 1.45,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // ── Google sign-in button ──────────────
                                  _GoogleSignInButton(
                                    isLoading: isLoading,
                                    onPressed: _signIn,
                                  ),

                                  const SizedBox(height: 16),

                                  // Separator info
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'TÀI KHOẢN CÔNG VỤ',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            fontSize: 10,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Footer
                          Center(
                            child: Text(
                              'Liên hệ hỗ trợ: admin@vietmap.gov.vn',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _errorMessage = null);
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is PlatformException) {
      final details = '${error.message ?? ''} ${error.details ?? ''}';
      if (details.contains('ApiException: 10')) {
        return 'Cấu hình Google chưa đúng (lỗi 10). Kiểm tra SHA-1 trên Firebase Console và OAuth Consent.';
      }
      return 'Lỗi đăng nhập Google: ${error.message ?? error.code}';
    }
    if (error is FirebaseAuthException) {
      return error.message ?? 'Lỗi xác thực Firebase: ${error.code}';
    }
    final message = error.toString();
    if (message.contains('GOOGLE_WEB_CLIENT_ID') || message.contains('.env')) {
      return 'Hệ thống chưa được cấu hình Client ID. Kiểm tra lại tệp cấu hình môi trường.';
    }
    if (message.contains('network')) {
      return 'Lỗi kết nối mạng. Kiểm tra lại đường truyền internet và thử lại.';
    }
    return 'Lỗi không xác định: $message';
  }
}

// ── Extracted sign-in button with hover state ──────────────────────────────

class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _hovered = false;

  static const _teal = Color(0xFF0F766E);
  static const _tealLight = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.isLoading
          ? SystemMouseCursors.wait
          : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutQuart,
        decoration: BoxDecoration(
          color: _hovered && !widget.isLoading ? _tealLight : _teal,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered && !widget.isLoading
              ? [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google G logo via SVG-equivalent coloured circles
                        _GoogleGIcon(),
                        const SizedBox(width: 12),
                        const Text(
                          'Đăng nhập bằng Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // White background circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white,
    );

    // Google coloured quadrants (simplified)
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue (top-right quadrant arc, simplified as colored segments)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        -1.57, 1.57, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        0, 1.57, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        1.57, 1.57, true, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        3.14, 1.57, true, paint);

    // White inner circle to create donut + G bar
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.50,
      Paint()..color = Colors.white,
    );

    // G bar (right side horizontal rectangle)
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.13, r * 0.72, r * 0.27),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
