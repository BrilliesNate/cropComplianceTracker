import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_constants.dart';
import '../../models/enums.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.currentUser?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  authProvider.currentUser?.role.name ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentRoute == RouteConstants.dashboard,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.dashboard);
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Audit Tracker'),
            selected: currentRoute == RouteConstants.auditTracker,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.auditTracker);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Compliance Report'),
            selected: currentRoute == RouteConstants.complianceReport,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.complianceReport);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Audit Index'),
            selected: currentRoute == RouteConstants.auditIndex,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.auditIndex);
            },
          ),
          const Divider(),


          if (authProvider.isAdmin) ...[
            const ListTile(
              title: Text(
                'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              selected: currentRoute == RouteConstants.userManagement,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(RouteConstants.userManagement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text('formConfigManagement'),
              selected: currentRoute == RouteConstants.formConfigManagement,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(RouteConstants.formConfigManagement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category Management'),
              selected: currentRoute == RouteConstants.categoryManagement,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(RouteConstants.categoryManagement);
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed(RouteConstants.login);
            },
          ),
        ],
      ),
    );
  }
}