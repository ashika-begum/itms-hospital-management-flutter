import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class AdminUserCreator {
  static String _generateUsername(String name, String role) {
    final cleanName = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final rnd = Random().nextInt(900) + 100;
    return "${role}_$cleanName$rnd";
  }

  static String generateTempPassword() {
    const chars = "AaBbCcDdEeFfGgHhIiJj1234567890@#\$!";
    final rnd = Random();
    return List.generate(10, (i) => chars[rnd.nextInt(chars.length)]).join();
  }

  static Future<Map<String, String>> createUser({
    required String name,
    required String phone,
    required String role,
    String? personalEmail,
  }) async {
    FirebaseApp secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: "SecondaryApp",
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      secondaryApp = Firebase.app("SecondaryApp");
    }

    final username = _generateUsername(name, role);
    final authEmail = "$username@itms.local";
    final tempPassword = generateTempPassword();

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: authEmail,
      password: tempPassword,
    );

    await FirebaseFirestore.instance
        .collection("users")
        .doc(cred.user!.uid)
        .set({
      "name": name,
      "username": username,
      "authEmail": authEmail,
      "phone": phone,
      "role": role,
      "forcePasswordChange": true,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await secondaryAuth.signOut();
    await secondaryApp.delete();

    return {
      "username": username,
      "password": tempPassword,
      "phone": phone,
    };
  }
}
