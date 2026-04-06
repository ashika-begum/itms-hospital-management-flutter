import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/admin_user_creator.dart';

// ✅ ADD THIS FUNCTION
String normalizePhone(String phone) {
  phone = phone.replaceAll(RegExp(r'\D'), '');
  if (phone.length == 10) {
    return "91$phone";
  }
  return phone;
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  String role = "nurse";
  bool loading = false;

  final roles = ["nurse", "porter"];

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> createUser() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final email = emailCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and phone are required")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final creds = await AdminUserCreator.createUser(
        name: name,
        phone: phone,
        role: role,
        personalEmail: email.isEmpty ? null : email,
      );

      if (!mounted) return;

      final message = """
🟦 *ITMS Login Credentials*

👤 *Username:* ${creds["username"]}
🔑 *Temporary Password:* ${creds["tempPassword"]}

🌐 Login URL:
https://inpatient-transport.web.app

⚠️ Please change your password after first login.
""";

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("User Created"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(message),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy"),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: message),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Credentials copied"),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: const Text("WhatsApp"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        final phone = normalizePhone(phoneCtrl.text.trim());
                        final url =
                            "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text("Done"),
            ),
          ],
        ),
      );

      nameCtrl.clear();
      phoneCtrl.clear();
      emailCtrl.clear();
      setState(() => role = "nurse");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Create User"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "New Staff Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _input(
                    controller: nameCtrl,
                    label: "Full Name",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _input(
                    controller: phoneCtrl,
                    label: "WhatsApp Number",
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _input(
                    controller: emailCtrl,
                    label: "Email (optional)",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => role = v!),
                    decoration: InputDecoration(
                      labelText: "Role",
                      prefixIcon: const Icon(Icons.work_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ElevatedButton(
                            onPressed: createUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Create User",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
