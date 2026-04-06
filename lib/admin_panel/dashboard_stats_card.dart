import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardStatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String collection;
  final String? filterField;

  const DashboardStatsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.collection,
    this.filterField,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;

          if (filterField == null) {
            count = docs.length;
          } else {
            count = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data["status"] == filterField ||
                  data["role"] == filterField;
            }).length;
          }
        }

        return Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: AppColors.primaryBlue),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                "$count",
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
