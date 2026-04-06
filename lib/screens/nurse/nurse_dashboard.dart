import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/imgbb_service.dart';
import 'create_request.dart';
import '../../core/utils/sla_utils.dart';

class NurseDashboard extends StatefulWidget {
  const NurseDashboard({super.key});

  @override
  State<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  final user = FirebaseAuth.instance.currentUser!;
  String selectedFilter = "all";
  String get nurseId => user.uid;

  // ============================================================
  // PROFILE SHEET (UPLOAD PHOTO LIKE PORTER)
  // ============================================================
  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                .doc(nurseId)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final photoUrl = data?["photoUrl"];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "My Profile",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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

                        // loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final Uint8List bytes = await image.readAsBytes();

                        // upload to imgbb
                        final imageUrl = await ImgbbService.uploadBytes(bytes);

                        // save URL in Firestore
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(nurseId)
                            .update({
                          "photoUrl": imageUrl,
                        });

                        if (context.mounted)
                          Navigator.pop(context); // close loader

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("✅ Profile photo updated")),
                          );
                        }
                      } catch (e) {
                        // close loader if open
                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Upload failed: $e")),
                          );
                        }
                      }
                    },
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? const Icon(Icons.camera_alt, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Tap the photo to update",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // TOP HEADER (Professional Hospital Style)
  // ============================================================
  Widget _topHeader(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(nurseId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = (data?['name'] ?? 'Nurse').toString();
        final photoUrl = data?['photoUrl'];

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
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.camera_alt, color: Colors.white)
                        : null,
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
                        "Nurse",
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
              _statsSection(isSmall),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 12),
              Expanded(child: _requestsList(isSmall)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(isSmall ? "New" : "New Request"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
          );
        },
      ),
    );
  }

  // ========================= STATS (PRO STYLE) =========================
  Widget _statsSection(bool isSmall) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("nurseId", isEqualTo: nurseId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 70);

        int pending = 0, inTransit = 0, completed = 0;

        for (var d in snap.data!.docs) {
          final s = d["status"];
          if (s == "requested" || s == "accepted") pending++;
          if (s == "in_transit") inTransit++;
          if (s == "completed") completed++;
        }

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
      },
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

  // ========================= FILTERS =========================
  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip("all", "All"),
          _filterChip("pending", "Pending"),
          _filterChip("arrival_claimed_source", "Arrival Claimed"),
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

  // ========================= REQUEST LIST (PRO STYLE) =========================
  Widget _requestsList(bool isSmall) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("nurseId", isEqualTo: nurseId)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0077B6),
              strokeWidth: 3,
            ),
          );
        }

        final docs = snap.data!.docs.where((d) {
          final s = d["status"];
          if (selectedFilter == "all") return true;
          if (selectedFilter == "pending") {
            return s == "requested" || s == "accepted";
          }
          return s == selectedFilter;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No requests",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final r = doc.data() as Map<String, dynamic>;

            final porterName = r["porterName"];
            final porterId = r["porterId"]; // ✅ NEW
            final priority = (r["priority"] ?? "").toString().toUpperCase();
            final transport =
                (r["transportType"] ?? "").toString().toUpperCase();

            DateTime? scheduledAt;
            if (r["scheduledAt"] != null) {
              scheduledAt = (r["scheduledAt"] as Timestamp).toDate();
            }

            final status = (r["status"] ?? "").toString();
            final from = r["from"]?["itemName"] ?? "Unknown";
            final to = r["to"]?["itemName"] ?? "Unknown";
            final note = (r["note"] ?? "").toString();

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
                padding: EdgeInsets.all(isSmall ? 12 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$from → $to",
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (scheduledAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Scheduled: ${scheduledAt.day.toString().padLeft(2, '0')}-"
                        "${scheduledAt.month.toString().padLeft(2, '0')}-"
                        "${scheduledAt.year} "
                        "${scheduledAt.hour.toString().padLeft(2, '0')}:"
                        "${scheduledAt.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Note: $note",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],

                    // ====================================================
                    // SHOW PORTER IMAGE + NAME (NEW)
                    // ====================================================
                    if (porterName != null && porterId != null) ...[
                      const SizedBox(height: 12),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(porterId)
                            .snapshots(),
                        builder: (context, porterSnap) {
                          final porterData =
                              porterSnap.data?.data() as Map<String, dynamic>?;
                          final porterPhotoUrl = porterData?["photoUrl"];

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      const Color(0xFF3B82F6).withOpacity(0.15),
                                  backgroundImage: porterPhotoUrl != null
                                      ? NetworkImage(porterPhotoUrl)
                                      : null,
                                  child: porterPhotoUrl == null
                                      ? const Icon(Icons.person,
                                          size: 14, color: Color(0xFF3B82F6))
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Accepted by $porterName",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(priority),
                        _pill(transport),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (status == "arrival_claimed_source")
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => confirmArrivalAtSource(doc.id),
                          icon: const Icon(Icons.check),
                          label: const Text(
                            "Confirm Porter Arrival",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    if (status == "arrived_source_confirmed")
                      const Text(
                        "✅ Arrival Confirmed",
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========================= BADGES =========================
  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final info = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: info.color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: info.color.withOpacity(0.25)),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  _StatusInfo _statusStyle(String s) {
    switch (s) {
      case "requested":
        return const _StatusInfo("REQUESTED", Color(0xFF64748B));
      case "accepted":
        return const _StatusInfo("ACCEPTED", Color(0xFF3B82F6));
      case "arrival_claimed_source":
        return const _StatusInfo("ARRIVAL CLAIMED", Color(0xFFF59E0B));
      case "arrived_source_confirmed":
        return const _StatusInfo("ARRIVAL CONFIRMED", Color(0xFF22C55E));
      case "in_transit":
        return const _StatusInfo("IN TRANSIT", Color(0xFF8B5CF6));
      case "completed":
        return const _StatusInfo("COMPLETED", Color(0xFF16A34A));
      default:
        return _StatusInfo(s.toUpperCase(), const Color(0xFF111827));
    }
  }

  // ========================= ACTION (UNCHANGED) =========================
  Future<void> confirmArrivalAtSource(String requestId) async {
    final ref =
        FirebaseFirestore.instance.collection("requests").doc(requestId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      if (data["status"] != "arrival_claimed_source") return;

      tx.update(ref, {
        "status": "arrived_source_confirmed",
        "timeline.arrivedSourceConfirmedAt": FieldValue.serverTimestamp(),
        "flags.awaitingNurseConfirmation": false,
        "lastUpdatedAt": FieldValue.serverTimestamp(),
      });
    });
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
