const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// 1. Gửi thông báo khi có sự cố mới được tạo
exports.notifyAdminOnNewIncident = onDocumentCreated("incidents/{incidentId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;
  const incident = snapshot.data();

  // Lấy danh sách FCM token của tất cả tài khoản có vai trò 'admin'
  const adminDocs = await admin.firestore().collection("users")
    .where("role", "==", "admin")
    .get();

  let tokens = [];
  adminDocs.forEach(doc => {
    const token = doc.data().fcmToken;
    if (token) tokens.push(token);
  });

  if (tokens.length === 0) return;

  const payload = {
    notification: {
      title: "🚨 Có sự cố mới cần xử lý!",
      body: `Loại: ${incident.category} tại ${incident.address}`,
    },
    data: {
      incidentId: event.params.incidentId,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  try {
    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: payload.notification,
      data: payload.data,
    });
    console.log("Đã gửi thông báo sự cố mới cho Admin thành công.");
  } catch (error) {
    console.error("Lỗi gửi thông báo cho Admin:", error);
  }
});

// 2. Gửi thông báo khi Admin phân công công việc cho Công nhân
exports.notifyWorkerOnAssigned = onDocumentUpdated("incidents/{incidentId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Kiểm tra xem trạng thái chuyển sang 'assigned' và có workerId mới không
  if (before.status !== "assigned" && after.status === "assigned" && after.workerId) {
    const workerDoc = await admin.firestore().collection("users").doc(after.workerId).get();
    
    if (!workerDoc.exists) return;
    const workerToken = workerDoc.data().fcmToken;

    if (!workerToken) return;

    const payload = {
      notification: {
        title: "📋 Bạn có nhiệm vụ mới!",
        body: `Hãy kiểm tra và xử lý sự cố: ${after.category} tại ${after.address}`,
      },
      data: {
        incidentId: event.params.incidentId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      await admin.messaging().send({
        token: workerToken,
        notification: payload.notification,
        data: payload.data,
      });
      console.log(`Đã gửi thông báo nhiệm vụ cho công nhân: ${after.workerId}`);
    } catch (error) {
      console.error("Lỗi gửi thông báo cho công nhân:", error);
    }
  }
});