/**
 * Firebase Cloud Functions (v1 – Callable)
 * ITMS – Admin User Management
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// =============================================================
// 🔐 HELPER: CHECK ADMIN ROLE
// =============================================================
async function ensureAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Not authenticated"
    );
  }

  const adminUid = context.auth.uid;
  const adminDoc = await admin
    .firestore()
    .collection("users")
    .doc(adminUid)
    .get();

  if (!adminDoc.exists || adminDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin access only"
    );
  }
}

// =============================================================
// 🔑 HELPER: GENERATE TEMP PASSWORD
// =============================================================
function generateTempPassword() {
  const chars =
    "AaBbCcDdEeFfGgHhIiJjKkLlMm1234567890@#\$!";
  let pass = "";
  for (let i = 0; i < 10; i++) {
    pass += chars.charAt(
      Math.floor(Math.random() * chars.length)
    );
  }
  return pass;
}

// =============================================================
// 👤 ADMIN CREATE USER
// =============================================================
exports.adminCreateUser = functions.https.onCall(
  async (data, context) => {
    await ensureAdmin(context);

    const { username, role, personalEmail, phone } = data;

    if (!username || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Username and role are required"
      );
    }

    const authEmail = `${username}@itms.local`;
    const tempPassword = generateTempPassword();

    // 🔐 Create Firebase Auth user
    const userRecord = await admin.auth().createUser({
      email: authEmail,
      password: tempPassword,
    });

    // 🗄 Save Firestore user profile
    await admin.firestore().collection("users").doc(userRecord.uid).set({
      username: username,
      authEmail: authEmail,
      role: role,
      phone: phone || null,
      email: personalEmail || null, // optional personal email
      forcePasswordChange: true,
      active: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: context.auth.uid,
    });

    return {
      uid: userRecord.uid,
      username: username,
      tempPassword: tempPassword, // ⚠️ show ONCE in admin UI
    };
  }
);

// =============================================================
// 🔄 ADMIN RESET PASSWORD
// =============================================================
exports.adminResetPassword = functions.https.onCall(
  async (data, context) => {
    await ensureAdmin(context);

    const { userUid } = data;

    if (!userUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "User UID required"
      );
    }

    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userUid)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User not found"
      );
    }

    const authEmail = userDoc.data().authEmail;
    const tempPassword = generateTempPassword();

    // 🔐 Update Firebase Auth password
    const userRecord = await admin
      .auth()
      .getUserByEmail(authEmail);

    await admin.auth().updateUser(userRecord.uid, {
      password: tempPassword,
    });

    // 🔁 Force password change again
    await admin.firestore().collection("users").doc(userUid).update({
      forcePasswordChange: true,
      passwordResetAt: admin.firestore.FieldValue.serverTimestamp(),
      passwordResetBy: context.auth.uid,
    });

    return {
      tempPassword, // ⚠️ admin sends via WhatsApp
    };
  }
);
