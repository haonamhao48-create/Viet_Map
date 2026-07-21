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

// 3. Xác thực vị trí check-in sự kiện
exports.verifyEventCheckIn = functions.firestore
  .document("event_participations/{participationId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Chỉ chạy nếu có request check-in mới gửi lên
    const hasNewRequest =
      afterData.checkin_request &&
      (!beforeData.checkin_request || 
       beforeData.checkin_request.timestamp !== afterData.checkin_request.timestamp);

    if (!hasNewRequest) {
      return null;
    }

    console.log(`Bắt đầu xác thực vị trí check-in cho User: ${afterData.user_id}, Event: ${afterData.event_id}`);
    const { latitude, longitude, evidence_url } = afterData.checkin_request;

    try {
      // 1. Lấy thông tin sự kiện
      const eventSnap = await db.collection("events").doc(afterData.event_id).get();
      if (!eventSnap.exists) {
        throw new Error("Sự kiện không tồn tại trên hệ thống.");
      }
      const eventData = eventSnap.data();
      const schoolId = eventData.school_id || eventData.schoolId;
      if (!schoolId) {
        throw new Error("Sự kiện này không có địa điểm trường học được liên kết.");
      }

      // 2. Lấy toạ độ trường học liên kết
      const schoolSnap = await db.collection("high_schools").doc(schoolId).get();
      if (!schoolSnap.exists) {
        throw new Error("Không tìm thấy thông tin trường học tương ứng.");
      }
      const schoolData = schoolSnap.data();

      let schoolLat = schoolData.latitude || schoolData.lat || schoolData.vi_do;
      let schoolLng = schoolData.longitude || schoolData.lng || schoolData.kinh_do;

      if (schoolData.location && typeof schoolData.location.latitude === 'number') {
        schoolLat = schoolData.location.latitude;
        schoolLng = schoolData.location.longitude;
      }

      if (typeof schoolLat !== 'number' || typeof schoolLng !== 'number') {
        throw new Error("Địa điểm trường học chưa cấu hình tọa độ hợp lệ trên hệ thống.");
      }

      // 3. Tính khoảng cách Haversine
      const distance = calculateHaversineDistance(latitude, longitude, schoolLat, schoolLng);
      console.log(`Khoảng cách đo được: ${distance.toFixed(1)} mét.`);

      const thresholdMeters = 200.0;

      if (distance <= thresholdMeters) {
        // Hợp lệ -> Chuyển trạng thái sang attended
        await change.after.ref.update({
          status: "attended",
          evidence_url: evidence_url,
          checkin_result: {
            status: "success",
            distance: distance,
            verified_at: admin.firestore.FieldValue.serverTimestamp()
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Xác thực thành công. User ${afterData.user_id} đã check-in thành công.`);
      } else {
        // Không hợp lệ -> Giữ nguyên status registered và cập nhật lỗi địa điểm
        await change.after.ref.update({
          status: "registered", // trả lại/giữ nguyên registered
          checkin_result: {
            status: "failed_invalid_location",
            distance: distance,
            failed_at: admin.firestore.FieldValue.serverTimestamp(),
            error_message: `Vị trí không chính xác. Bạn đang cách địa điểm ${Math.round(distance)}m (phạm vi cho phép: ${thresholdMeters}m).`
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Xác thực thất bại. Khoảng cách quá xa: ${distance.toFixed(1)}m`);
      }
    } catch (error) {
      console.error("Lỗi trong quá trình xác thực check-in:", error);
      await change.after.ref.update({
        status: "registered",
        checkin_result: {
          status: "error",
          failed_at: admin.firestore.FieldValue.serverTimestamp(),
          error_message: `Lỗi xác thực hệ thống: ${error.message || error.toString()}`
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    return null;
  });

function calculateHaversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Bán kính Trái Đất theo mét
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Khoảng cách theo mét
}
