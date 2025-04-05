import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart'; // Add this import
import '../../core/constants/route_constants.dart';

class AppScaffoldWrapper extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final FloatingActionButton? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AppScaffoldWrapper({
    Key? key,
    required this.child,
    required this.title,
    this.actions,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.floatingActionButton,
    this.appBar,
  }) : super(key: key);

  @override
  State<AppScaffoldWrapper> createState() => _AppScaffoldWrapperState();
}

class _AppScaffoldWrapperState extends State<AppScaffoldWrapper> {
  bool _isSidebarCollapsed = false;
  final double _sidebarWidth = 210;
  final double _collapsedSidebarWidth = 70;

  @override
  void initState() {
    super.initState();
    // Initialize the route provider with the current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != null) {
        Provider.of<RouteProvider>(context, listen: false).setActiveRoute(currentRoute);
      }
    });
  }

  // Menu items
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Dashboard',
      'icon': Icons.grid_view,
      'route': RouteConstants.dashboard,
      'adminOnly': false,
    },
    {
      'title': 'Compliance Tracker',
      'icon': Icons.track_changes,
      'route': RouteConstants.auditTracker,
      'adminOnly': false,
    },
    {
      'title': 'Compliance Report',
      'icon': Icons.bar_chart,
      'route': RouteConstants.complianceReport,
      'adminOnly': false,
    },
    {
      'title': 'Audit Index',
      'icon': Icons.folder_outlined,
      'route': RouteConstants.auditIndex,
      'adminOnly': false,
    },
  ];

  // Admin menu items
  final List<Map<String, dynamic>> _adminMenuItems = [
    {
      'title': 'User Management',
      'icon': Icons.people_outline,
      'route': RouteConstants.userManagement,
    },
    {
      'title': 'Category Management',
      'icon': Icons.category_outlined,
      'route': RouteConstants.categoryManagement,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context); // Get the route provider

    final isLargeScreen = MediaQuery.of(context).size.width > 1100;
    final isMediumScreen = MediaQuery.of(context).size.width > 800 && MediaQuery.of(context).size.width <= 1100;
    final primaryColor = Theme.of(context).primaryColor;

    // Determine the effective sidebar width
    double effectiveSidebarWidth = 0;
    if (isLargeScreen) {
      effectiveSidebarWidth = _isSidebarCollapsed ? _collapsedSidebarWidth : _sidebarWidth;
    } else if (isMediumScreen) {
      effectiveSidebarWidth = _collapsedSidebarWidth;
    }

    // Create AppBar with back button style
    final appBar = widget.appBar ?? AppBar(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_open, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      elevation: 0,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      actions: widget.actions,
    );

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.grey[100],
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: appBar,
      drawer: (!isLargeScreen && !isMediumScreen)
          ? _buildDrawer(context, authProvider, routeProvider)
          : null,
      body: Row(
        children: [
          // Persistent sidebar for large and medium screens
          if (isLargeScreen || isMediumScreen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: effectiveSidebarWidth,
              color: Colors.white,
              child: Column(
                children: [
                  // Banner image
                  ClipRRect(
                    child: Image.asset(
                      'assets/images/menuImage.png',
                      width: effectiveSidebarWidth,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: effectiveSidebarWidth,
                        height: 120,
                        color: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.image,
                          color: primaryColor.withOpacity(0.3),
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  // User profile
                  _buildUserProfile(context, authProvider, _isSidebarCollapsed),

                  // Divider
                  const Divider(height: 1),

                  // Menu header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "MENU",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu items
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ..._menuItems.map((item) {
                            // Check if this item is selected based on the active route
                            final bool isSelected = routeProvider.activeRoute == item['route'];

                            return _buildMenuItem(
                              context,
                              item['icon'],
                              item['title'],
                              item['route'],
                              isSelected,
                              _isSidebarCollapsed,
                              onTap: () {
                                // Update the route provider when navigating
                                routeProvider.setActiveRoute(item['route']);
                                Navigator.of(context).pushReplacementNamed(item['route']);
                              },
                            );
                          }).toList(),

                          if (authProvider.isAdmin) ...[
                            // Admin header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    "ADMIN",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Admin menu items
                            ..._adminMenuItems.map((item) {
                              // Check if this item is selected
                              final bool isSelected = routeProvider.activeRoute == item['route'];

                              return _buildMenuItem(
                                context,
                                item['icon'],
                                item['title'],
                                item['route'],
                                isSelected,
                                _isSidebarCollapsed,
                                onTap: () {
                                  // Update the route provider when navigating
                                  routeProvider.setActiveRoute(item['route']);
                                  Navigator.of(context).pushReplacementNamed(item['route']);
                                },
                              );
                            }).toList(),
                          ],

                          // Divider before logout
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Logout
                          _buildMenuItem(
                            context,
                            Icons.logout,
                            'Logout',
                            '',
                            false,
                            _isSidebarCollapsed,
                            onTap: () {
                              authProvider.logout();
                              routeProvider.setActiveRoute(RouteConstants.login);
                              Navigator.of(context).pushReplacementNamed(RouteConstants.login);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapse button at the bottom
                  if (!_isSidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isSidebarCollapsed = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Collapse',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, RouteProvider routeProvider) {
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      child: Column(
        children: [
          // Logo and banner
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.eco,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Crop Compliance',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Banner image
                ClipRRect(
                  child: Image.asset(
                    'assets/images/banner.png',
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 120,
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        color: primaryColor.withOpacity(0.3),
                        size: 48,
                      ),
                    ),
                  ),
                ),

                // User profile
                _buildUserProfile(context, authProvider, false),

                // Divider
                const Divider(height: 1),
              ],
            ),
          ),

          // Menu header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  "MENU",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._menuItems.map((item) {
                  // Check if this item is selected
                  final bool isSelected = routeProvider.activeRoute == item['route'];

                  return _buildMenuItem(
                    context,
                    item['icon'],
                    item['title'],
                    item['route'],
                    isSelected,
                    false,
                    onTap: () {
                      // Update the route provider when navigating
                      routeProvider.setActiveRoute(item['route']);
                      Navigator.of(context).pushReplacementNamed(item['route']);
                    },
                  );
                }).toList(),

                if (authProvider.isAdmin) ...[
                  // Admin header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "ADMIN",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin menu items
                  ..._adminMenuItems.map((item) {
                    // Check if this item is selected
                    final bool isSelected = routeProvider.activeRoute == item['route'];

                    return _buildMenuItem(
                      context,
                      item['icon'],
                      item['title'],
                      item['route'],
                      isSelected,
                      false,
                      onTap: () {
                        // Update the route provider when navigating
                        routeProvider.setActiveRoute(item['route']);
                        Navigator.of(context).pushReplacementNamed(item['route']);
                      },
                    );
                  }).toList(),
                ],

                // Divider before logout
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Logout
                _buildMenuItem(
                  context,
                  Icons.logout,
                  'Logout',
                  '',
                  false,
                  false,
                  onTap: () {
                    authProvider.logout();
                    routeProvider.setActiveRoute(RouteConstants.login);
                    Navigator.of(context).pushReplacementNamed(RouteConstants.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthProvider authProvider, bool isCollapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with user initial
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: 20,
            child: Text(
              authProvider.currentUser?.name.isNotEmpty ?? false
                  ? authProvider.currentUser!.name.substring(0, 1).toUpperCase()
                  : 'N',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // User name and role (only show if not collapsed)
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.currentUser?.name ?? 'Nathan Test',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    authProvider.currentUser?.role.name ?? 'ADMIN',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      IconData icon,
      String title,
      String route,
      bool isSelected,
      bool isCollapsed, {
        VoidCallback? onTap,
      }) {
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? primaryColor : Colors.grey[600],
      ),
      title: !isCollapsed
          ? Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          color: isSelected ? primaryColor : Colors.grey[800],
        ),
      )
          : null,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      selected: isSelected,
      selectedTileColor: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
      selectedColor: primaryColor,
      onTap: onTap,
    );
  }
}