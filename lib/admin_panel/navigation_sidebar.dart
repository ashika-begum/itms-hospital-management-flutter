import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  // -----------------------------
  // CONFIRM LOGOUT DIALOG
  // -----------------------------
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Confirm Logout"),
        content: const Text(
          "Are you sure you want to logout from ITMS?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/login",
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: const Border(
          right: BorderSide(color: Colors.black12),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.grey.shade50,
              labelType: NavigationRailLabelType.none,
              minWidth: 72,
              groupAlignment: -1,
              indicatorColor: Colors.transparent,
              destinations: [
                _navItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  tooltip: "Dashboard (Ctrl + D)",
                ),
                _navItem(
                  index: 1,
                  icon: Icons.group_outlined,
                  selectedIcon: Icons.group,
                  tooltip: "Manage Users (Ctrl + U)",
                ),
                _navItem(
                  index: 2,
                  icon: Icons.location_on_outlined,
                  selectedIcon: Icons.location_on,
                  tooltip: "Manage Locations (Ctrl + L)",
                ),
              ],
            ),
          ),

          // -----------------------------
          // LOGOUT SECTION
          // -----------------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 12),
                Tooltip(
                  message: "Logout (Ctrl + Q)",
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _confirmLogout(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.power_settings_new,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // CUSTOM NAV ITEM
  // -----------------------------
  NavigationRailDestination _navItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String tooltip,
  }) {
    final bool isSelected = selectedIndex == index;

    return NavigationRailDestination(
      label: const Text(""),
      icon: Tooltip(
        message: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _indicator(isSelected),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : Colors.black54,
            ),
          ],
        ),
      ),
      selectedIcon: Tooltip(
        message: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _indicator(true),
            const SizedBox(width: 12),
            Icon(
              selectedIcon,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // BLUE INDICATOR BAR
  // -----------------------------
  Widget _indicator(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 4,
      height: 34,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
