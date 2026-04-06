import 'package:inpatient_transport/admin_panel/admin_dashboard.dart';
import 'package:inpatient_transport/admin_panel/admin_manage_locations.dart';
import 'package:inpatient_transport/admin_panel/manage_users_screen.dart';

final routes = {
  '/admin-dashboard': (context) => const AdminDashboard(),
  '/admin-users': (context) => const ManageUsersScreen(),
  '/admin-locations': (context) => const AdminManageLocations(),
};
