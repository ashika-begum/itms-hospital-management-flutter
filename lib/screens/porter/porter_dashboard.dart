import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/porter/scan_destination_qr.dart';
import '../../services/imgbb_service.dart';
import '../../services/auth_service.dart';

class PorterDashboard extends StatefulWidget {
  const PorterDashboard({super.key});

  @override
  State<PorterDashboard> createState() => _PorterDashboardState();
}

class _PorterDashboardState extends State<PorterDashboard> {
  int _lastPendingCount = 0;

  String selectedFilter = "all";
  String get porterId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(context),
              const SizedBox(height: 16),
              Text(
                "Your Requests",
                style: TextStyle(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _body(context, isSmall)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP HEADER (same as nurse style)
  // ============================================================
  Widget _topHeader(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(porterId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = (data?['name'] ?? 'Porter').toString();
        final photoUrl = data?['photoUrl'];
        print("PHOTO URL FROM FIRESTORE: $photoUrl");

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 14,
            14,
            14,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0077B6),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 10),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1.0),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: GestureDetector(
                  onTap: () => _showProfileSheet(context),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: ClipOval(
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(Icons.person,
                                    color: Colors.white);
                              },
                            )
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome back 👋",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        name,
                        key: ValueKey(name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        "Porter",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Logout",
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await AuthService.instance.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BODY (logic unchanged)
  // ============================================================
  Widget _body(BuildContext context, bool isSmall) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0077B6),
              strokeWidth: 3,
            ),
          );
        }

        final all = snapshot.data!.docs;

        // ================= COUNTS ================= (UNCHANGED)
        int pendingCount = 0;
        int inTransitCount = 0;
        int completedCount = 0;

        for (var r in all) {
          final d = r.data() as Map<String, dynamic>;
          final s = d['status'];

          if (s == 'requested' && d['porterId'] == null) {
            pendingCount++;
          }

          if (d['porterId'] == porterId && s == 'in_transit') {
            inTransitCount++;
          }

          if (d['porterId'] == porterId && s == 'completed') {
            completedCount++;
          }
        }

        // ================= LISTS ================= (UNCHANGED)
        final available = all.where((r) {
          final d = r.data() as Map<String, dynamic>;
          return d['status'] == 'requested' && d['porterId'] == null;
        }).toList();

        final inProgressList = all.where((r) {
          final d = r.data() as Map<String, dynamic>;
          if (d['porterId'] != porterId) return false;

          return [
            'accepted',
            'arrival_claimed_source',
            'arrived_source_confirmed',
            'in_transit',
            'arrival_claimed_destination',
            'arrived_destination_confirmed',
          ].contains(d['status']);
        }).toList();

        final completedList = all.where((r) {
          final d = r.data() as Map<String, dynamic>;
          return d['porterId'] == porterId && d['status'] == 'completed';
        }).toList();

        // 🔔 NEW REQUEST ALERT (UNCHANGED)
        if (available.length > _lastPendingCount && _lastPendingCount != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🚑 New transport request received"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }

        _lastPendingCount = available.length;

        // ================= FILTERED VIEW (UNCHANGED) =================
        final arrivalClaimedOnly = inProgressList.where((r) {
          final d = r.data() as Map<String, dynamic>;
          final s = d['status'];
          return s == 'arrival_claimed_source' ||
              s == 'arrival_claimed_destination';
        }).toList();

        final inTransitOnly = inProgressList.where((r) {
          final d = r.data() as Map<String, dynamic>;
          return d['status'] == 'in_transit';
        }).toList();

        // ============================================================
        // UI
        // ============================================================
        return ListView(
          children: [
            _statsSection(
                pendingCount, inTransitCount, completedCount, isSmall),
            const SizedBox(height: 16),
            _filters(),
            const SizedBox(height: 12),
            if (selectedFilter == "all") ...[
              _section("My In-Progress Requests"),
              if (inProgressList.isEmpty)
                _empty("No active requests")
              else
                ...inProgressList.map((r) => _requestCard(r, context)),
              _section("Available Requests"),
              if (available.isEmpty)
                _empty("No pending requests")
              else
                ...available.map((r) => _requestCard(r, context)),
              _section("Recently Completed"),
              if (completedList.isEmpty)
                _empty("No completed requests")
              else
                ...completedList
                    .map((r) => _requestCard(r, context, readOnly: true)),
            ] else if (selectedFilter == "pending") ...[
              _section("Available Requests"),
              if (available.isEmpty)
                _empty("No pending requests")
              else
                ...available.map((r) => _requestCard(r, context)),
            ] else if (selectedFilter == "arrival_claimed") ...[
              _section("Arrival Claimed"),
              if (arrivalClaimedOnly.isEmpty)
                _empty("No arrival claimed requests")
              else
                ...arrivalClaimedOnly.map((r) => _requestCard(r, context)),
            ] else if (selectedFilter == "in_transit") ...[
              _section("In Transit"),
              if (inTransitOnly.isEmpty)
                _empty("No in-transit requests")
              else
                ...inTransitOnly.map((r) => _requestCard(r, context)),
            ] else if (selectedFilter == "completed") ...[
              _section("Completed"),
              if (completedList.isEmpty)
                _empty("No completed requests")
              else
                ...completedList
                    .map((r) => _requestCard(r, context, readOnly: true)),
            ],
          ],
        );
      },
    );
  }

  // ============================================================
  // STATS SECTION (same as nurse vertical cards)
  // ============================================================
  Widget _statsSection(
      int pending, int inTransit, int completed, bool isSmall) {
    return Column(
      children: [
        _statCard(
          "Pending",
          pending,
          Icons.pending_actions_outlined,
          const Color(0xFFF59E0B),
          isSmall,
        ),
        const SizedBox(height: 12),
        _statCard(
          "In Transit",
          inTransit,
          Icons.local_shipping_outlined,
          const Color(0xFF3B82F6),
          isSmall,
        ),
        const SizedBox(height: 12),
        _statCard(
          "Completed",
          completed,
          Icons.verified_outlined,
          const Color(0xFF22C55E),
          isSmall,
        ),
      ],
    );
  }

  Widget _statCard(
      String label, int count, IconData icon, Color accent, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 55,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "$count",
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS (same nurse style)
  // ============================================================
  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip("all", "All"),
          _filterChip("pending", "Pending"),
          _filterChip("arrival_claimed", "Arrival Claimed"),
          _filterChip("in_transit", "In Transit"),
          _filterChip("completed", "Completed"),
        ],
      ),
    );
  }

  Widget _filterChip(String k, String l) {
    final selected = selectedFilter == k;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(l),
        selected: selected,
        onSelected: (_) => setState(() => selectedFilter = k),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF0F172A),
        ),
        selectedColor: const Color(0xFF0077B6),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF0077B6) : const Color(0xFFE5E7EB),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  // ============================================================
  // REQUEST CARD (unchanged)
  // ============================================================
  Widget _requestCard(DocumentSnapshot r, BuildContext context,
      {bool readOnly = false}) {
    final data = r.data() as Map<String, dynamic>;

    final from = data["from"] as Map<String, dynamic>?;
    final to = data["to"] as Map<String, dynamic>?;
    final nurseId = data['nurseId'];

    final fromText = from?["itemName"] ?? "Unknown";
    final toText = to?["itemName"] ?? "Unknown";

    final note = data["note"] ?? "";
    final priority = (data["priority"] ?? "").toString().toUpperCase();
    final transport = (data["transportType"] ?? "").toString().toUpperCase();

    DateTime? scheduledAt;
    if (data["scheduledAt"] != null) {
      scheduledAt = (data["scheduledAt"] as Timestamp).toDate();
    }

    Future<String> getNurseName(String nurseId) async {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(nurseId)
          .get();
      return snap['name'] ?? 'Nurse';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$fromText → $toText",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            FutureBuilder<String>(
              future: getNurseName(nurseId),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return Text(
                  "Requested by: ${snapshot.data}",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                );
              },
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Note: $note"),
            ],
            if (scheduledAt != null) ...[
              const SizedBox(height: 8),
              Text(
                "Scheduled: ${scheduledAt.day}-${scheduledAt.month}-${scheduledAt.year} "
                "${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(priority)),
                Chip(label: Text(transport)),
              ],
            ),
            if (!readOnly) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _buttons(r),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS (UNCHANGED)
  // ============================================================
  Widget _buttons(DocumentSnapshot r) {
    final data = r.data() as Map<String, dynamic>;
    final status = data['status'];

    if (status == 'requested') {
      return ElevatedButton(
        onPressed: () => acceptRequest(r.id),
        child: const Text("Accept"),
      );
    }

    if (status == 'accepted' && data['porterId'] == porterId) {
      return ElevatedButton(
        onPressed: () => claimArrivalAtSource(r.id),
        child: const Text("Reached Patient"),
      );
    }

    if (status == 'arrived_source_confirmed' && data['porterId'] == porterId) {
      return ElevatedButton(
        onPressed: () => startTransit(r.id),
        child: const Text("Start Transit"),
      );
    }

    if (status == 'arrival_claimed_destination' &&
        data['porterId'] == porterId) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("Scan Destination QR"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanDestinationQR(
                requestId: r.id,
                expectedItemId: data['to']['itemId'],
              ),
            ),
          );
        },
      );
    }

    if (status == 'in_transit' && data['porterId'] == porterId) {
      return ElevatedButton(
        onPressed: () => claimArrivalAtDestination(r.id),
        child: const Text("Reached Destination"),
      );
    }

    return const SizedBox();
  }

  // ============================================================
  // acceptRequest (UNCHANGED)
  // ============================================================
  Future<void> acceptRequest(String requestId) async {
    final porterId = FirebaseAuth.instance.currentUser!.uid;
    final reqRef =
        FirebaseFirestore.instance.collection("requests").doc(requestId);
    final userRef =
        FirebaseFirestore.instance.collection("users").doc(porterId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) return;

      final data = reqSnap.data() as Map<String, dynamic>;

      if (data["status"] != "requested") return;
      if (data["porterId"] != null) return;

      final porterSnap = await tx.get(userRef);
      final porterName = porterSnap.data()?["name"] ?? "Porter";

      tx.update(reqRef, {
        "status": "accepted",
        "porterId": porterId,
        "porterName": porterName,
        "timeline.acceptedAt": FieldValue.serverTimestamp(),
        "lastUpdatedAt": FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // PROFILE SHEET (UNCHANGED)
  // ============================================================
  void _showProfileSheet(BuildContext context) {
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(porterId)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final photoUrl = data?["photoUrl"];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("My Profile",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 75,
                          maxWidth: 800,
                        );
                        if (image == null) return;

                        if (!context.mounted) return;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final bytes = await image.readAsBytes();
                        final imageUrl = await ImgbbService.uploadBytes(bytes);

                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(porterId)
                            .update({
                          "photoUrl": imageUrl,
                        });

                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("✅ Profile photo updated")),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Upload failed: $e")),
                          );
                        }
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      child: ClipOval(
                        child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(Icons.camera_alt);
                                },
                              )
                            : const Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration:
                        const InputDecoration(labelText: "Phone Number"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(porterId)
                          .update({"phone": phoneCtrl.text.trim()});
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );
}

// ============================================================
// WORKFLOW FUNCTIONS (UNCHANGED)
// ============================================================
Future<void> claimArrivalAtSource(String requestId) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseFirestore.instance.collection("requests").doc(requestId);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;

    if (data["status"] != "accepted") return;
    if (data["porterId"] != uid) return;

    tx.update(ref, {
      "status": "arrival_claimed_source",
      "timeline.arrivalClaimedSourceAt": FieldValue.serverTimestamp(),
      "lastUpdatedAt": FieldValue.serverTimestamp(),
    });
  });
}

Future<void> startTransit(String requestId) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseFirestore.instance.collection("requests").doc(requestId);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    if (data['status'] != 'arrived_source_confirmed') return;
    if (data['porterId'] != uid) return;

    tx.update(ref, {
      'status': 'in_transit',
      'timeline.inTransitAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  });
}

Future<void> claimArrivalAtDestination(String requestId) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseFirestore.instance.collection("requests").doc(requestId);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    if (data['status'] != 'in_transit') return;
    if (data['porterId'] != uid) return;

    tx.update(ref, {
      'status': 'arrival_claimed_destination',
      'flags.awaitingDestinationVerification': true,
      'timeline.arrivalClaimedDestinationAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  });
}

Future<void> verifyDestinationByQR({
  required String requestId,
  required String scannedDestinationId,
}) async {
  final ref = FirebaseFirestore.instance.collection("requests").doc(requestId);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;

    if (data['status'] != 'arrived_destination_confirmed') return;

    final toItemId = data['to']?['itemId'];
    if (toItemId != scannedDestinationId) {
      throw Exception("Wrong destination QR");
    }

    tx.update(ref, {
      'status': 'completed',
      'flags.awaitingDestinationVerification': false,
      'timeline.destinationVerifiedAt': FieldValue.serverTimestamp(),
      'timeline.completedAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  });
}
