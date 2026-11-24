import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/session_actions.dart';
import 'admin_farm_chip.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

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
      // Admins with a farm open see the orange farm badge (switch / ×)
      // under the title.
      title: TitleWithAdminFarm(title: Text(title)),
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
                signOutAndReset(context);
              } else if (value == 'profile') {
                // Navigate to profile
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(context.l10n.navProfile),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(context.l10n.logout),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}