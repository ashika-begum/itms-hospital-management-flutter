import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// AUTH SCREENS
import 'screens/auth/login_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/auth/role_missing_screen.dart';

// ADMIN
import 'admin_panel/admin_dashboard.dart';

// NURSE
import 'screens/nurse/nurse_dashboard.dart';

// PORTER
import 'screens/porter/porter_dashboard.dart';

// COMMON
import 'screens/common/loading.dart';

// SERVICES
import 'services/firestore_service.dart';

// THEME
import 'theme/app_colors.dart';

// FIREBASE OPTIONS
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/foundation.dart';
import 'screens/common/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ALWAYS initialize Firebase ONCE (all platforms)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ App Check (AFTER Firebase init)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // emulator
    webProvider: ReCaptchaV3Provider(
      '6Le49TwsAAAAAIPuAdtOHUKOssd9nKSUoNXV1oqB',
    ),
  );

  runApp(const TransportApp());
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Inpatient Transport System",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.lightBlue,
        fontFamily: "Poppins",
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),

      // 🔐 SINGLE ENTRY POINT
      home: const SplashScreen(),

      // 🚫 ONLY PUBLIC ROUTES (NO DASHBOARDS HERE)
      routes: {
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
      },
    );
  }
}

// ------------------------------------------------------------
//                          AUTH WRAPPER
// ------------------------------------------------------------
// ------------------------------------------------------------
//                          AUTH WRAPPER
// ------------------------------------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirestoreService().getUserDoc(user.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const LoadingScreen();
            }

            final data = snap.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const RoleMissingScreen();
            }

            final role = data['role'];

            final raw = data['forcePasswordChange'];
            final isDefaultPassword = raw == true || raw == "true" || raw == 1;

            // 🔁 First login → force password change
            if (isDefaultPassword) {
              return const ChangePasswordScreen();
            }

            switch (role) {
              case 'admin':
                return const AdminDashboard();
              case 'nurse':
                return const NurseDashboard();
              case 'porter':
                return const PorterDashboard();
              default:
                return const RoleMissingScreen();
            }
          },
        );
      },
    );
  }
}
