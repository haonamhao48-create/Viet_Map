const admin = require("firebase-admin");
const serviceAccount = require("../../vietmap-9c90d-firebase-adminsdk-fbsvc-63f4a3c23a.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function check() {
  console.log("=== KIỂM TRA FIRESTORE DATA ===");

  // 1. Kiểm tra users
  const usersSnap = await db.collection("users").get();
  console.log(`\nTổng số users trong Firestore: ${usersSnap.size}`);
  usersSnap.forEach(doc => {
    const data = doc.data();
    console.log(`- User ID: ${doc.id}`);
    console.log(`  Full Name: ${data.fullName || "N/A"}`);
    console.log(`  Email: ${data.email || "N/A"}`);
    console.log(`  Role: ${data.role || "N/A"}`);
    console.log(`  FCM Token: ${data.fcmToken ? (data.fcmToken.substring(0, 15) + "...") : "TRỐNG 🔴"}`);
  });

  // 2. Kiểm tra notification_requests
  const reqsSnap = await db.collection("notification_requests").orderBy("createdAt", "desc").limit(5).get();
  console.log(`\n5 yêu cầu thông báo gần đây nhất:`);
  reqsSnap.forEach(doc => {
    const data = doc.data();
    console.log(`- Request ID: ${doc.id}`);
    console.log(`  Title: ${data.title}`);
    console.log(`  Status: ${data.status} ${data.status === "no_tokens" ? "🔴 (Không có Token)" : "🟢"}`);
    console.log(`  Audience: ${data.audienceType}`);
    if (data.sentCount !== undefined) console.log(`  Sent Count: ${data.sentCount}`);
    if (data.errorMessage) console.log(`  Error: ${data.errorMessage}`);
  });

  process.exit(0);
}

check().catch(err => {
  console.error("Lỗi:", err);
  process.exit(1);
});
