import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // ✅ LAZY getter (Web-safe)
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ---------------------------------------------------------
  // Save / update user role (SAFE – no overwrite)
  // ---------------------------------------------------------
  Future<void> saveUserRole(String uid, String role) async {
    await _db.collection("users").doc(uid).set({
      "role": role,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------
  // Fetch only user role
  // ---------------------------------------------------------
  Future<String?> getUserRole(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    return snap.data()?["role"];
  }

  // ---------------------------------------------------------
  // Get full user document (AuthWrapper / routing)
  // ---------------------------------------------------------
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _db.collection("users").doc(uid).get();
  }
}
