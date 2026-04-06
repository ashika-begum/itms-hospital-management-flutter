import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/itms_splash.png",
              width: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 35,
              height: 35,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF0077B6), // medical blue
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Loading...",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
