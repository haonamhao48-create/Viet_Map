import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app/router.dart';
import '../../app/widgets/top_notification.dart';

/// Kênh thông báo quan trọng cao — dùng cho tất cả thông báo đẩy từ hệ thống
const AndroidNotificationChannel _highImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel', // phải khớp với AndroidManifest và Cloud Functions
  'Thông báo hệ thống',
  description: 'Kênh nhận các thông báo đẩy từ VietMap Admin.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Hàm xử lý khi nhận thông báo đẩy chạy ngầm (Background/Terminated).
  // Cần là hàm top-level hoặc static được đánh dấu @pragma('vm:entry-point').
  debugPrint('[FCM] Nhận tin nhắn chạy ngầm: \${message.messageId}');
  if (message.notification != null) {
    debugPrint('[FCM] Tiêu đề tin nhắn ngầm: \${message.notification!.title}');
    debugPrint('[FCM] Nội dung tin nhắn ngầm: \${message.notification!.body}');
  }
}

class NotificationService {
  NotificationService._();

  static String? _token;
  static String? get fcmToken => _token;

  static FirebaseMessaging? get _messaging {
    if (isSupported) {
      try {
        return FirebaseMessaging.instance;
      } catch (e) {
        debugPrint('[FCM] Không thể truy cập FirebaseMessaging.instance: $e');
      }
    }
    return null;
  }

  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<void> saveTokenToFirestore(String userId) async {
    if (!isSupported) return;
    try {
      final token = _token ?? await _messaging?.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FCM] Đã cập nhật token lên Firestore cho user $userId.');
      }
    } catch (e) {
      debugPrint('[FCM] Lỗi lưu token lên Firestore (có thể user chưa có document): $e');
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    try {
      // Luôn điều hướng về trang Hộp thư thông báo khi nhấn vào thông báo đẩy
      debugPrint('[FCM] Điều hướng về trang thông báo /notifications');
      appRouter.push('/notifications');
    } catch (e) {
      debugPrint('[FCM] Lỗi điều hướng từ thông báo: $e');
    }
  }

  /// Hiển thị thông báo dưới dạng system notification (Heads-up banner)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Thông báo hệ thống',
          channelDescription: 'Kênh nhận các thông báo đẩy từ VietMap Admin.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: '/notifications', // Điều hướng về trang thông báo khi nhấn
    );
  }

  static Future<void> initialize() async {
    if (!isSupported) {
      debugPrint('[FCM] Nền tảng này không được hỗ trợ Cloud Messaging.');
      return;
    }

    try {
      final messaging = _messaging;
      if (messaging == null) return;

      // 1. Đăng ký background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Tạo Android Notification Channel (BẮT BUỘC từ Android 8.0+)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(_highImportanceChannel);
        debugPrint('[FCM] Đã tạo Android Notification Channel: ${_highImportanceChannel.id}');
      }

      // Khởi tạo flutter_local_notifications
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Khi user nhấn vào local notification (foreground) → vào trang thông báo
          debugPrint('[LocalNotif] Nhấn vào local notification, điều hướng /notifications');
          try {
            appRouter.push('/notifications');
          } catch (e) {
            debugPrint('[LocalNotif] Lỗi điều hướng: $e');
          }
        },
      );

      // 3. Yêu cầu quyền thông báo (iOS/Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Trạng thái cấp quyền thông báo: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 4. Lấy token FCM
        final token = await messaging.getToken();
        _token = token;
        debugPrint('[FCM] Token thiết bị: $token');

        // Đồng bộ token lên Firestore nếu đã đăng nhập sẵn
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await saveTokenToFirestore(currentUser.uid);
        }
      }

      // Lắng nghe thay đổi token
      messaging.onTokenRefresh.listen((newToken) async {
        _token = newToken;
        debugPrint('[FCM] Token được làm mới: $newToken');
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await saveTokenToFirestore(currentUser.uid);
        }
      });

      // 5. Lắng nghe tin nhắn khi ứng dụng đang chạy ở FOREGROUND
      //    → Hiển thị system notification (heads-up banner) VÀ in-app banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('[FCM] Nhận tin nhắn ở foreground: ${message.messageId}');

        // Hiển thị system heads-up notification trên thanh trạng thái
        await _showLocalNotification(message);

        // Đồng thời hiển thị in-app banner nếu có context
        final notification = message.notification;
        if (notification != null) {
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            TopNotification.show(
              context,
              '${notification.title ?? "Thông báo"}: ${notification.body ?? ""}',
            );
          }
        }
      });

      // 6. Lắng nghe khi người dùng nhấn vào thông báo từ chế độ Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Người dùng đã nhấn vào thông báo: ${message.messageId}');
        _handleMessageNavigation(message);
      });

      // 7. Xử lý khi app mở từ trạng thái bị tắt hoàn toàn (Terminated)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App được mở từ tin nhắn khởi tạo: ${initialMessage.messageId}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageNavigation(initialMessage);
        });
      }

    } catch (e) {
      debugPrint('[FCM] Khởi tạo dịch vụ thông báo thất bại: $e');
    }
  }
}
