import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_user_creator.dart';
import '../theme/app_colors.dart';

String normalizePhone(String phone) {
  phone = phone.replaceAll(RegExp(r'\D'), '');
  if (phone.length == 10) return "91$phone";
  return phone;
}

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = "nurse";
  bool _loading = false;

  Future<void> _createUser() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;

    setState(() => _loading = true);

    final result = await AdminUserCreator.createUser(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _role,
    );

    if (!mounted) return;

    final phone = normalizePhone(_phoneCtrl.text);
    final message = """
🟦 *ITMS Login Credentials*

👤 *Username:* ${result["username"]}
🔑 *Password:* ${result["password"]}

🌐 Login:
https://inpatient-transport.web.app

⚠️ Please change password after first login
""";

    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "User Created Successfully",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Username", result["username"]!),
            _infoRow("Password", result["password"]!),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: message),
                      );
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text("Copied to clipboard"),
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
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );

    setState(() => _loading = false);
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _role = "nurse";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create User",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            _blueField(
              controller: _nameCtrl,
              label: "Full Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _blueField(
              controller: _phoneCtrl,
              label: "WhatsApp Number",
              icon: Icons.phone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(
                labelText: "Role",
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "nurse", child: Text("Nurse")),
                DropdownMenuItem(value: "porter", child: Text("Porter")),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  onPressed: _loading ? null : _createUser,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Create"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blueField({
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
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
