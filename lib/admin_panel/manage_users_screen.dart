import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'add_user_dialog.dart';
import 'dart:math';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: const Text(
              "Manage Users",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add User"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddUserDialog(),
                    );
                  },
                ),
                const SizedBox(height: 40),
                _sectionTitle("Nurses"),
                const SizedBox(height: 14),
                _userTable(context, role: "nurse"),
                const SizedBox(height: 50),
                _sectionTitle("Porters"),
                const SizedBox(height: 14),
                _userTable(context, role: "porter"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _userTable(BuildContext context, {required String role}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: role)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: DataTable(
            columnSpacing: 40,
            columns: const [
              DataColumn(label: Text("User")),
              DataColumn(label: Text("Created")),
              DataColumn(label: Text("Action")),
            ],
            rows: users.map((u) {
              final data = u.data() as Map<String, dynamic>;

              final name = data["name"] ?? "";
              final username = data["username"] ?? "";
              final phone = data["phone"] ?? "";

              final createdAt = (data["createdAt"] is Timestamp)
                  ? data["createdAt"].toDate().toString().substring(0, 16)
                  : "N/A";

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(name.toString()[0].toUpperCase()),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name),
                            Text(username,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(createdAt)),
                  DataCell(
                    Row(
                      children: [
                        TextButton(
                          child: const Text("Edit"),
                          onPressed: () {
                            _editUserDialog(context, u.id, data);
                          },
                        ),
                        TextButton(
                          child: const Text("Delete",
                              style: TextStyle(color: Colors.red)),
                          onPressed: () =>
                              _confirmDelete(context, userId: u.id),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------- EDIT USER ----------------

  void _editUserDialog(
      BuildContext context, String userId, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data["name"]);
    final phoneCtrl = TextEditingController(text: data["phone"]);

    final oldPhone = data["phone"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .update({
                "name": nameCtrl.text.trim(),
                "phone": phoneCtrl.text.trim(),
              });

              String phone = phoneCtrl.text.trim();
              String name = nameCtrl.text.trim();

              if (oldPhone != phone) {
                String newPassword = _generatePassword();

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .update({
                  "name": name,
                  "phone": phone,
                  "password": newPassword,
                });

                _sendWhatsapp(
                  phone,
                  data["username"],
                  newPassword,
                );
              } else {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .update({
                  "name": name,
                  "phone": phone,
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE ----------------

  void _confirmDelete(BuildContext context, {required String userId}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---------------- WHATSAPP ----------------

  Future<void> _sendWhatsapp(
      String phone, String username, String password) async {
    final message = """
*ITMS Login Credentials*

Username: $username
Password: $password

Login:
https://inpatient-transport.web.app

Please change password after first login
""";

    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    await launchUrl(Uri.parse(url));
  }
}

String _generatePassword() {
  const chars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$!";
  Random rand = Random();

  return List.generate(
    10,
    (index) => chars[rand.nextInt(chars.length)],
  ).join();
}
