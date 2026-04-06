import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'admin_destination_qr_screen.dart';

class AdminManageLocations extends StatefulWidget {
  const AdminManageLocations({super.key});

  @override
  State<AdminManageLocations> createState() => _AdminManageLocationsState();
}

class _AdminManageLocationsState extends State<AdminManageLocations> {
  final _categoryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? selectedCategoryId;

  Future<void> _createCategory() async {
    if (_categoryCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection("categories").add({
      "name": _categoryCtrl.text.trim(),
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
    });

    _categoryCtrl.clear();
  }

  Future<void> _createLocation() async {
    if (selectedCategoryId == null || _locationCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection("categories_items").add({
      "categoryId": selectedCategoryId,
      "name": _locationCtrl.text.trim(),
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
    });

    _locationCtrl.clear();
  }

  Future<void> _deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection("categories").doc(id).delete();
  }

  Future<void> _deleteLocation(String id) async {
    await FirebaseFirestore.instance
        .collection("categories_items")
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 BLUE HEADER
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
              "Manage Hospital Locations",
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
              children: [
                _categoryCard(),
                const SizedBox(height: 24),
                _locationCard(),
                const SizedBox(height: 24),
                _categoryWithLocations(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _categoryCard() {
    return _cardWrapper(
      title: "Create Category",
      subtitle: "Example: Department, Ward, OT",
      child: Column(
        children: [
          TextField(
            controller: _categoryCtrl,
            decoration: _inputDecoration("Category Name"),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _createCategory,
              child: const Text("Save Category"),
            ),
          )
        ],
      ),
    );
  }

  Widget _locationCard() {
    return _cardWrapper(
      title: "Add Location",
      subtitle: "Rooms, Blocks, OPDs",
      child: Column(
        children: [
          _categoryDropdown(),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: _inputDecoration("Location Name"),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: selectedCategoryId == null ? null : _createLocation,
              child: const Text("Save Location"),
            ),
          )
        ],
      ),
    );
  }

  Widget _categoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("categories").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();

        final docs = snap.data!.docs;

        // ✅ Collect valid category ids
        final validIds = docs.map((d) => d.id).toList();

        // ✅ If selectedCategoryId no longer exists → reset it
        if (selectedCategoryId != null &&
            !validIds.contains(selectedCategoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedCategoryId = null;
            });
          });
        }

        return DropdownButtonFormField<String>(
          value: validIds.contains(selectedCategoryId)
              ? selectedCategoryId
              : null, // ✅ Safe value
          decoration: _inputDecoration("Select Category"),
          items: docs.map((doc) {
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(doc["name"]),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedCategoryId = v),
        );
      },
    );
  }

  Widget _categoryWithLocations() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("categories").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        return Column(
          children: snap.data!.docs.map((cat) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  cat["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(cat.id),
                ),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("categories_items")
                        .where("categoryId", isEqualTo: cat.id)
                        .snapshots(),
                    builder: (context, locSnap) {
                      if (!locSnap.hasData) return const SizedBox();

                      return Column(
                        children: locSnap.data!.docs.map((loc) {
                          return ListTile(
                            leading: const Icon(Icons.location_on,
                                color: AppColors.primaryBlue),
                            title: Text(loc["name"]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code,
                                      color: AppColors.primaryBlue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminDestinationQRScreen(
                                          destinationId: loc.id,
                                          destinationName: loc["name"],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteLocation(loc.id),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _cardWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
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
    );
  }
}
