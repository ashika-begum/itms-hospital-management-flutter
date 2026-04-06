import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  // FROM
  String? fromCategoryId, fromCategoryName, fromItemId, fromItemName;

  // TO
  String? toCategoryId, toCategoryName, toItemId, toItemName;

  // EXTRA
  String priority = "routine";
  String transportType = "wheelchair";
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ==================================================
  // UI
  // ==================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Create Request",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionCard(
                    title: "From Location",
                    icon: Icons.my_location_outlined,
                    child: Column(
                      children: [
                        _categoryDropdown(isFrom: true),
                        const SizedBox(height: 12),
                        _itemDropdown(isFrom: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: "To Location",
                    icon: Icons.location_on_outlined,
                    child: Column(
                      children: [
                        _categoryDropdown(isFrom: false),
                        const SizedBox(height: 12),
                        _itemDropdown(isFrom: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DETAILS SECTION
                  _sectionCard(
                    title: "Details",
                    icon: Icons.tune_outlined,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 500;

                        return Column(
                          children: [
                            // PRIORITY + TRANSPORT
                            isSmall
                                ? Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: priority,
                                        decoration: _inputDecoration(
                                          label: "Priority",
                                          hint: "Select priority",
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                              value: "routine",
                                              child: Text("Routine")),
                                          DropdownMenuItem(
                                              value: "urgent",
                                              child: Text("Urgent")),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => priority = v!),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: transportType,
                                        decoration: _inputDecoration(
                                          label: "Transport Type",
                                          hint: "Select type",
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                              value: "wheelchair",
                                              child: Text("Wheelchair")),
                                          DropdownMenuItem(
                                              value: "stretcher",
                                              child: Text("Stretcher")),
                                          DropdownMenuItem(
                                              value: "bed", child: Text("Bed")),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => transportType = v!),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: priority,
                                          decoration: _inputDecoration(
                                            label: "Priority",
                                            hint: "Select priority",
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                                value: "routine",
                                                child: Text("Routine")),
                                            DropdownMenuItem(
                                                value: "urgent",
                                                child: Text("Urgent")),
                                          ],
                                          onChanged: (v) =>
                                              setState(() => priority = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: transportType,
                                          decoration: _inputDecoration(
                                            label: "Transport Type",
                                            hint: "Select type",
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                                value: "wheelchair",
                                                child: Text("Wheelchair")),
                                            DropdownMenuItem(
                                                value: "stretcher",
                                                child: Text("Stretcher")),
                                            DropdownMenuItem(
                                                value: "bed",
                                                child: Text("Bed")),
                                          ],
                                          onChanged: (v) => setState(
                                              () => transportType = v!),
                                        ),
                                      ),
                                    ],
                                  ),

                            const SizedBox(height: 12),

                            // DATE + TIME
                            isSmall
                                ? Column(
                                    children: [
                                      _pickerField(
                                        label: "Date",
                                        icon: Icons.calendar_today_outlined,
                                        valueText: scheduledDate == null
                                            ? "Select date"
                                            : "${scheduledDate!.day.toString().padLeft(2, '0')}-"
                                                "${scheduledDate!.month.toString().padLeft(2, '0')}-"
                                                "${scheduledDate!.year}",
                                        onTap: () async {
                                          final d = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now()
                                                .add(const Duration(days: 30)),
                                          );
                                          if (d != null) {
                                            setState(() => scheduledDate = d);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _pickerField(
                                        label: "Time",
                                        icon: Icons.access_time_outlined,
                                        valueText: scheduledTime == null
                                            ? "Select time"
                                            : scheduledTime!.format(context),
                                        onTap: () async {
                                          final t = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (t != null) {
                                            setState(() => scheduledTime = t);
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _pickerField(
                                          label: "Date",
                                          icon: Icons.calendar_today_outlined,
                                          valueText: scheduledDate == null
                                              ? "Select date"
                                              : "${scheduledDate!.day.toString().padLeft(2, '0')}-"
                                                  "${scheduledDate!.month.toString().padLeft(2, '0')}-"
                                                  "${scheduledDate!.year}",
                                          onTap: () async {
                                            final d = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                  const Duration(days: 30)),
                                            );
                                            if (d != null) {
                                              setState(() => scheduledDate = d);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _pickerField(
                                          label: "Time",
                                          icon: Icons.access_time_outlined,
                                          valueText: scheduledTime == null
                                              ? "Select time"
                                              : scheduledTime!.format(context),
                                          onTap: () async {
                                            final t = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (t != null) {
                                              setState(() => scheduledTime = t);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                label: "Note (optional)",
                                hint: "Any extra information for the porter",
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submitRequest,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        "Submit Request",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "After submitting, the porter will be able to accept the request.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // UI HELPERS
  // ==================================================
  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
      hintStyle: const TextStyle(color: Colors.black45),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077B6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF0077B6)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required IconData icon,
    required String valueText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(label: label),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0077B6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valueText,
                style: TextStyle(
                  color: valueText.startsWith("Select")
                      ? Colors.black45
                      : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // CATEGORY DROPDOWN
  // ==================================================
  Widget _categoryDropdown({required bool isFrom}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("categories").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 52,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF0077B6),
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: isFrom ? fromCategoryId : toCategoryId,
          decoration: _inputDecoration(
            label: "Category",
            hint: "Select category",
          ),
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc.id,
              child: Text(
                doc["name"],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          validator: (v) => (v == null) ? "Please select a category" : null,
          onChanged: (val) {
            final doc = snapshot.data!.docs.firstWhere((d) => d.id == val);
            setState(() {
              if (isFrom) {
                fromCategoryId = val;
                fromCategoryName = doc["name"];
                fromItemId = null;
                fromItemName = null;
              } else {
                toCategoryId = val;
                toCategoryName = doc["name"];
                toItemId = null;
                toItemName = null;
              }
            });
          },
        );
      },
    );
  }

  // ==================================================
  // ITEM DROPDOWN
  // ==================================================
  Widget _itemDropdown({required bool isFrom}) {
    final categoryId = isFrom ? fromCategoryId : toCategoryId;

    if (categoryId == null) {
      return DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: _inputDecoration(
          label: "Location",
          hint: "Select category first",
        ),
        disabledHint: const Text("Select category first"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("categories_items")
          .where("categoryId", isEqualTo: categoryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 52,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF0077B6),
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: isFrom ? fromItemId : toItemId,
          decoration: _inputDecoration(
            label: "Location",
            hint: "Select location",
          ),
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc.id,
              child: Text(
                doc["name"],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          validator: (v) => (v == null) ? "Please select a location" : null,
          onChanged: (val) {
            final doc = snapshot.data!.docs.firstWhere((d) => d.id == val);
            setState(() {
              if (isFrom) {
                fromItemId = val;
                fromItemName = doc["name"];
              } else {
                toItemId = val;
                toItemName = doc["name"];
              }
            });
          },
        );
      },
    );
  }

  // ==================================================
  // FIRESTORE SAVE (UNCHANGED)
  // ==================================================
  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    if (scheduledDate == null || scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time")),
      );
      return;
    }

    final scheduledAt = DateTime(
      scheduledDate!.year,
      scheduledDate!.month,
      scheduledDate!.day,
      scheduledTime!.hour,
      scheduledTime!.minute,
    );

    final docRef = FirebaseFirestore.instance.collection("requests").doc();

    await docRef.set({
      "requestId": docRef.id,
      "nurseId": _user!.uid,
      "porterId": null,
      "status": "requested",
      "createdAt": FieldValue.serverTimestamp(),
      "lastUpdatedAt": FieldValue.serverTimestamp(),
      "flags": {
        "awaitingNurseConfirmation": false,
      },
      "priority": priority,
      "transportType": transportType,
      "note": _noteController.text.trim(),
      "scheduledAt": Timestamp.fromDate(scheduledAt),
      "timeline": {
        "requestedAt": FieldValue.serverTimestamp(),
        "acceptedAt": null,
        "arrivalClaimedSourceAt": null,
        "arrivedSourceConfirmedAt": null,
        "inTransitAt": null,
        "arrivalClaimedDestinationAt": null,
        "completedAt": null,
      },
      "from": {
        "categoryId": fromCategoryId,
        "categoryName": fromCategoryName,
        "itemId": fromItemId,
        "itemName": fromItemName,
      },
      "to": {
        "categoryId": toCategoryId,
        "categoryName": toCategoryName,
        "itemId": toItemId,
        "itemName": toItemName,
      },
    });

    if (!mounted) return;
    Navigator.pop(context);
  }
}
