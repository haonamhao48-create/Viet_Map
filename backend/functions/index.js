const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// 1. Tự động gửi thông báo khi có sự kiện (events) mới được đăng tải
exports.sendAutomaticEventNotification = functions.firestore
  .document("events/{eventId}")
  .onCreate(async (snapshot, context) => {
    const eventData = snapshot.data();
    const eventId = context.params.eventId;
    console.log(`Phát hiện sự kiện mới: ${eventData.title} (ID: ${eventId})`);

    try {
      // Lấy toàn bộ tokens từ collection users
      const usersSnapshot = await db.collection("users")
        .where("fcmToken", "!=", "")
        .get();

      const tokens = [];
      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.fcmToken) {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("Không tìm thấy thiết bị nào có đăng ký FCM token.");
        return;
      }

      console.log(`Đang gửi thông báo sự kiện mới đến ${tokens.length} thiết bị.`);

      const message = {
        notification: {
          title: "Sự kiện tuyển sinh mới!",
          body: `Sự kiện "${eventData.title}" vừa được đăng tải. Nhấn để xem chi tiết!`,
        },
        android: {
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            priority: "high",
          },
        },
        data: {
          route: `/admin/events/${eventId}/participants`, // Deep link điều hướng
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Gửi thành công: ${response.successCount}, Thất bại: ${response.failureCount}`);
    } catch (error) {
      console.error("Lỗi khi gửi thông báo sự kiện mới:", error);
    }
  });

// 2. Xử lý yêu cầu gửi thông báo từ Admin Mobile App
exports.sendAdminNotification = functions.firestore
  .document("notification_requests/{requestId}")
  .onCreate(async (snapshot, context) => {
    const requestData = snapshot.data();
    const requestId = context.params.requestId;

    if (requestData.status !== "pending") {
      console.log(`Yêu cầu ${requestId} không ở trạng thái pending.`);
      return;
    }

    console.log(`Bắt đầu xử lý yêu cầu gửi thông báo từ Admin: ${requestData.title}`);

    try {
      let tokens = [];

      // Tìm kiếm Token dựa theo Đối tượng nhận (audienceType)
      if (requestData.audienceType === "all") {
        // Gửi cho tất cả mọi người
        const usersSnapshot = await db.collection("users")
          .where("fcmToken", "!=", "")
          .get();
        usersSnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.fcmToken) {
            tokens.push(data.fcmToken);
          }
        });
      } else if (requestData.audienceType === "event" && requestData.targetEventId) {
        // Gửi cho người tham dự sự kiện cụ thể
        const targetEventId = requestData.targetEventId;
        console.log(`Tìm token của người tham gia sự kiện: ${targetEventId}`);

        const participationsSnapshot = await db.collection("event_participations")
          .where("eventId", "==", targetEventId)
          .where("status", "==", "registered")
          .get();

        const userIds = [];
        participationsSnapshot.forEach((doc) => {
          const pData = doc.data();
          const uid = pData.userId || pData.user_id;
          if (uid) userIds.push(uid);
        });

        if (userIds.length > 0) {
          // Firestore giới hạn truy vấn 'in' tối đa 30 phần tử. Phân trang chunk 30.
          const chunks = [];
          for (let i = 0; i < userIds.length; i += 30) {
            chunks.push(userIds.slice(i, i + 30));
          }

          for (const chunk of chunks) {
            const usersSnapshot = await db.collection("users")
              .where(admin.firestore.FieldPath.documentId(), "in", chunk)
              .get();
            usersSnapshot.forEach((doc) => {
              const uData = doc.data();
              if (uData.fcmToken) tokens.push(uData.fcmToken);
            });
          }
        }
      }

      // Loại bỏ token trùng lặp
      tokens = [...new Set(tokens)];

      if (tokens.length === 0) {
        console.log("Không có thiết bị mục tiêu nào để gửi thông báo.");
        await snapshot.ref.update({
          status: "no_tokens",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      console.log(`Gửi thông báo Admin đến ${tokens.length} thiết bị.`);

      const message = {
        notification: {
          title: requestData.title,
          body: requestData.body,
        },
        android: {
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            priority: "high",
          },
        },
        data: {
          route: requestData.route || "/home",
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`Kết quả: thành công ${response.successCount}, thất bại ${response.failureCount}`);

      await snapshot.ref.update({
        status: "sent",
        sentCount: response.successCount,
        failureCount: response.failureCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (error) {
      console.error(`Lỗi khi xử lý yêu cầu gửi thông báo ${requestId}:`, error);
      await snapshot.ref.update({
        status: "error",
        errorMessage: error.message || error.toString(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
