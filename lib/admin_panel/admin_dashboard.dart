import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'navigation_sidebar.dart';
import 'manage_users_screen.dart';
import 'admin_manage_locations.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardHome(),
    ManageUsersScreen(),
    AdminManageLocations(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Row(
        children: [
          NavigationSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              setState(() => _selectedIndex = i);
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               DASHBOARD HOME                               */
/* -------------------------------------------------------------------------- */

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AdminHeader(),
          SizedBox(height: 30),
          DashboardStatGrid(),
          SizedBox(height: 30),
          RequestStatusOverview(),
          SizedBox(height: 30),
          AverageResponseTimeCard(),
          SizedBox(height: 30),
          RecentRequestsList(),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                BLUE HEADER                                 */
/* -------------------------------------------------------------------------- */

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0077B6),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Image.asset(
            "assets/icons/itms_splash.png",
            height: 50,
          ),
          const SizedBox(width: 16),
          const Text(
            "Admin Dashboard",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            STAT CARDS GRID                                 */
/* -------------------------------------------------------------------------- */

class DashboardStatGrid extends StatelessWidget {
  const DashboardStatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1200) columns = 3;
        if (constraints.maxWidth < 900) columns = 2;
        if (constraints.maxWidth < 600) columns = 1;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            LiveStatCard(
              title: "Total Requests",
              icon: Icons.assignment,
              queryBuilder: _Queries.totalRequests,
            ),
            LiveStatCard(
              title: "Completed",
              icon: Icons.check_circle,
              queryBuilder: _Queries.completedRequests,
            ),
            LiveStatCard(
              title: "Pending",
              icon: Icons.schedule,
              queryBuilder: _Queries.pendingRequests,
            ),
          ],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                STAT CARD                                   */
/* -------------------------------------------------------------------------- */

class LiveStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Query Function() queryBuilder;

  const LiveStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.queryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: queryBuilder().snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF0077B6).withOpacity(0.1),
                child: Icon(icon, color: const Color(0xFF0077B6)),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              AnimatedNumber(count),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            ANIMATED NUMBER                                 */
/* -------------------------------------------------------------------------- */

class AnimatedNumber extends StatelessWidget {
  final int value;
  const AnimatedNumber(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      builder: (context, val, _) {
        return Text(
          val.toString(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         REQUEST STATUS OVERVIEW                            */
/* -------------------------------------------------------------------------- */

class RequestStatusOverview extends StatelessWidget {
  const RequestStatusOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        int pending = 0, completed = 0, inProgress = 0;

        for (var doc in snapshot.data!.docs) {
          final status = doc['status'];
          if (status == 'pending') {
            pending++;
          } else if (status == 'completed') {
            completed++;
          } else {
            inProgress++;
          }
        }

        final total = pending + completed + inProgress;
        if (total == 0) return const SizedBox();

        return _card(
          title: "Requests by Status",
          child: Column(
            children: [
              _bar("Pending", pending / total, Colors.orange),
              _bar("In Progress", inProgress / total, Colors.blue),
              _bar("Completed", completed / total, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              color: color,
              backgroundColor: color.withOpacity(0.15),
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                       AVERAGE RESPONSE TIME                                */
/* -------------------------------------------------------------------------- */

class AverageResponseTimeCard extends StatelessWidget {
  const AverageResponseTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        int totalMinutes = 0;
        int count = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('createdAt') &&
              data.containsKey('completedAt')) {
            final start = (data['createdAt'] as Timestamp).toDate();
            final end = (data['completedAt'] as Timestamp).toDate();
            final minutes = end.difference(start).inMinutes;

            if (minutes > 0 && minutes <= 120) {
              totalMinutes += minutes;
              count++;
            }
          }
        }

        if (count == 0) return const SizedBox();

        final avg = (totalMinutes / count).toStringAsFixed(1);

        return _card(
          title: "Average Completion Time",
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0077B6).withOpacity(0.1),
                child: const Icon(Icons.timer, color: Color(0xFF0077B6)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$avg minutes",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "From request creation to completion",
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          RECENT REQUESTS LIST                              */
/* -------------------------------------------------------------------------- */

class RecentRequestsList extends StatelessWidget {
  const RecentRequestsList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        return _card(
          title: "Recent Requests",
          child: Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "• ${data['type'] ?? 'Request'} — ${data['status']}",
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             SHARED CARD UI                                 */
/* -------------------------------------------------------------------------- */

Widget _card({String? title, required Widget child}) {
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
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        child,
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*                              FIRESTORE QUERIES                             */
/* -------------------------------------------------------------------------- */

class _Queries {
  static Query totalRequests() =>
      FirebaseFirestore.instance.collection('requests');

  static Query completedRequests() => FirebaseFirestore.instance
      .collection('requests')
      .where('status', isEqualTo: 'completed');

  static Query pendingRequests() => FirebaseFirestore.instance
      .collection('requests')
      .where('status', isEqualTo: 'pending');
}
