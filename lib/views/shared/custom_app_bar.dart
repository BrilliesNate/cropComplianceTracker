import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/enums.dart';
import '../../core/constants/route_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: showBackButton,
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
        if (authProvider.isAuthenticated)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
                Navigator.of(context).pushReplacementNamed(RouteConstants.login);
              } else if (value == 'profile') {
                // Navigate to profile
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}