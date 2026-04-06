import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------------------------------
  // LOGIN + CHECK DEFAULT (FORCE PASSWORD CHANGE)
  // -------------------------------------------------------------
  Future<bool> loginAndCheckDefault(String authEmail, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: authEmail,
      password: password,
    );

    final userDoc = await _db.collection("users").doc(cred.user!.uid).get();

    // If true → redirect to change password
    return userDoc.data()?["forcePasswordChange"] ?? false;
  }

  // -------------------------------------------------------------
  // UPDATE OWN PASSWORD (AFTER FIRST LOGIN)
  // -------------------------------------------------------------
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser!;
    final email = user.email!;

    final credential = EmailAuthProvider.credential(
      email: email,
      password: oldPassword,
    );

    // Re-authenticate
    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);

    // Clear force flag
    await _db.collection("users").doc(user.uid).update({
      "forcePasswordChange": false,
      "passwordUpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  // -------------------------------------------------------------
  // LOGOUT
  // -------------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }
}
