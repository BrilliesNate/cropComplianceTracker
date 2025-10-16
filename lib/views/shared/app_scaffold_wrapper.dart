import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/route_provider.dart';
import '../../core/constants/route_constants.dart';
import '../../models/user_model.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    {
      'title': 'override',
      'icon': Icons.category_outlined,
      'route': RouteConstants.overrid,
    },
    {
      'title': 'Company Management',
      'icon': Icons.business_outlined,
      'route': RouteConstants.companyManagement,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

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

    // Create AppBar with user selection indicator
    final appBar = widget.appBar ?? AppBar(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_open, color: Colors.white),
            onPressed: () {
              // Check if we're on mobile (where drawer is used)
              if (!isLargeScreen && !isMediumScreen) {
                // Open the drawer on mobile
                _scaffoldKey.currentState?.openDrawer();
              } else {
                // Toggle sidebar collapse on larger screens
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
          // Selected user indicator in app bar for mobile/tablet
          // Selected user indicator in app bar - SHOW ON ALL SCREENS
          // Selected user indicator in app bar - SHOW ON ALL SCREENS
          if (authProvider.isAdmin && authProvider.selectedUser != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Managing: ${authProvider.selectedUser!.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        authProvider.clearUserSelection();
                        // Refresh documents for the admin's own account
                        final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
                        await documentProvider.refreshForUserContext(context);
                      },
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      elevation: 0,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      actions: widget.actions,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.backgroundColor ?? Colors.grey[100],
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: appBar,
      drawer: (!isLargeScreen && !isMediumScreen)
          ? _buildDrawer(context, authProvider, routeProvider)
          : null,
      body: Column(
        children: [
          // Prominent user selection banner for admins

          Expanded(
            child: Row(
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
                            'assets/images/menuImage.webp',
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

                        // User selector for admins in sidebar
                        if (authProvider.isAdmin && !_isSidebarCollapsed)
                          // _buildSidebarUserSelector(context, authProvider),

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
                                  final bool isSelected = routeProvider.activeRoute == item['route'];

                                  return _buildMenuItem(
                                    context,
                                    item['icon'],
                                    item['title'],
                                    item['route'],
                                    isSelected,
                                    _isSidebarCollapsed,
                                    onTap: () {
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
                                    final bool isSelected = routeProvider.activeRoute == item['route'];

                                    return _buildMenuItem(
                                      context,
                                      item['icon'],
                                      item['title'],
                                      item['route'],
                                      isSelected,
                                      _isSidebarCollapsed,
                                      onTap: () {
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
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildUserSelectionBanner(BuildContext context, AuthProvider authProvider) {
    final primaryColor = Theme.of(context).primaryColor;
    final isLargeScreen = MediaQuery.of(context).size.width > 1100;

    return Container(
      width: double.infinity,
      color: authProvider.selectedUser != null ? Colors.orange.shade100 : primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            authProvider.selectedUser != null ? Icons.warning : Icons.admin_panel_settings,
            color: authProvider.selectedUser != null ? Colors.orange.shade700 : primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: authProvider.selectedUser != null
                ? RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'ADMIN MODE: Managing documents for '),
                  TextSpan(
                    text: authProvider.selectedUser!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : Text(
              'Admin Mode: Managing your own documents',
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (authProvider.selectedUser != null)
            TextButton.icon(
              onPressed: () => authProvider.clearUserSelection(),
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              label: const Text(
                'Switch Back',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (!isLargeScreen) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showUserSelectorDialog(context, authProvider),
              icon: Icon(
                Icons.people,
                color: authProvider.selectedUser != null ? Colors.orange.shade700 : primaryColor,
              ),
              tooltip: 'Select User to Manage',
            ),
          ],
        ],
      ),
    );
  }



  void _showUserSelectorDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select User to Manage',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a user to manage their documents and compliance status.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Option to manage own documents
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(authProvider.currentUser?.name ?? 'You'),
                        subtitle: const Text('Manage your own documents'),
                        trailing: authProvider.selectedUser == null
                            ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () {
                          authProvider.clearUserSelection();
                          Navigator.of(context).pop();
                        },
                      ),
                      const Divider(),
                      // Other users from company
                      ...authProvider.companyUsers.where((user) =>
                      user.id != authProvider.currentUser?.id).map((user) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade400,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.role.name),
                        trailing: authProvider.selectedUser?.id == user.id
                            ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () {
                          authProvider.selectUser(user);
                          Navigator.of(context).pop();
                        },
                      )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, RouteProvider routeProvider) {
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      child: Column(
        children: [
          // Logo and banner
      ClipRRect(
      child: Image.asset(
      'assets/images/menuImage.webp',
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
        ),),),

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
                  final bool isSelected = routeProvider.activeRoute == item['route'];

                  return _buildMenuItem(
                    context,
                    item['icon'],
                    item['title'],
                    item['route'],
                    isSelected,
                    false,
                    onTap: () {
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
                    final bool isSelected = routeProvider.activeRoute == item['route'];

                    return _buildMenuItem(
                      context,
                      item['icon'],
                      item['title'],
                      item['route'],
                      isSelected,
                      false,
                      onTap: () {
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