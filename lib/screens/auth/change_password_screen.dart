import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ===============================
  // CHANGE PASSWORD LOGIC
  // ===============================
  Future<void> _changePassword() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showMsg("All fields are required");
      return;
    }

    if (newPass.length < 8) {
      _showMsg("Password must be at least 8 characters");
      return;
    }

    if (newPass != confirm) {
      _showMsg("New passwords do not match");
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.instance.updatePassword(oldPass, newPass);

      if (!mounted) return;

      _showMsg("Password updated successfully");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      _showMsg("Invalid old password");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  InputDecoration _input(String label, bool show, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: IconButton(
        icon: Icon(show ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // 🔵 TOP BLUE WAVE SECTION
                  ClipPath(
                    clipper: TopWaveClipper(),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      color: const Color.fromARGB(255, 8, 84, 170),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/itms_splash.png",
                            height: 170,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Change Password",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 13, 49, 180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        // OLD PASSWORD
                        TextField(
                          controller: _oldCtrl,
                          obscureText: !_showOld,
                          decoration: _input(
                            "Old Password",
                            _showOld,
                            () => setState(() => _showOld = !_showOld),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // NEW PASSWORD
                        TextField(
                          controller: _newCtrl,
                          obscureText: !_showNew,
                          decoration: _input(
                            "New Password",
                            _showNew,
                            () => setState(() => _showNew = !_showNew),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // CONFIRM PASSWORD
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: !_showConfirm,
                          decoration: _input(
                            "Confirm New Password",
                            _showConfirm,
                            () => setState(() => _showConfirm = !_showConfirm),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 10, 91, 126),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Update Password",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Password must be at least 8 characters",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================
// WAVE CLIPPER (Same as Login)
// ===============================
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - 60);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 60,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 120,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
