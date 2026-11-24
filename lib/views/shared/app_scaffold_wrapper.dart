import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/views/shared/language_toggle.dart';
import 'package:cropCompliance/views/shared/admin_farm_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/utils/session_actions.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

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
      'icon': Icons.grid_view,
      'route': RouteConstants.dashboard,
      'adminOnly': false,
    },
    {
      'icon': Icons.track_changes,
      'route': RouteConstants.auditTracker,
      'adminOnly': false,
    },
    {
      'icon': Icons.bar_chart,
      'route': RouteConstants.complianceReport,
      'adminOnly': false,
    },
    {
      'icon': Icons.folder_outlined,
      'route': RouteConstants.auditIndex,
      'adminOnly': false,
    },
    {
      'icon': Icons.receipt_long_outlined,
      'route': RouteConstants.payslipManager,
      'adminOnly': false,
    },
  ];

  // Admin menu items
  final List<Map<String, dynamic>> _adminMenuItems = [
    {
      'icon': Icons.people_outline,
      'route': RouteConstants.userManagement,
    },
    {
      'icon': Icons.category_outlined,
      'route': RouteConstants.categoryManagement,
    },

    {
      'icon': Icons.toggle_on_outlined,
      'route': RouteConstants.overrid,
    },
    {
      'icon': Icons.business_outlined,
      'route': RouteConstants.companyManagement,
    },
    {
      'icon': Icons.build_outlined,
      'route': RouteConstants.dataFixUtility,
    },
    {
      'icon': Icons.eco_outlined,
      'route': RouteConstants.farmableConsole,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    // Keep the notification listener bound to the signed-in user.
    // start() is idempotent — it only re-subscribes if the user changed.
    // Auditors get no notifications (and no push registration) at all.
    final uid = authProvider.currentUser?.id;
    if (uid != null && !authProvider.isAuditer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).start(uid);
          PushNotificationService.instance.init(uid);
        }
      });
    }

    final isLargeScreen = MediaQuery.of(context).size.width > 1100;
    final isMediumScreen = MediaQuery.of(context).size.width > 800 && MediaQuery.of(context).size.width <= 1100;
    final primaryColor = Theme.of(context).primaryColor;
    final isPhone = MediaQuery.of(context).size.width < 650;

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
          // Admin with a farm open: the orange farm badge (tap name to
          // switch farm, × for all farms). On phones it gets its own strip
          // under the title instead (see `bottom:`), where it has room.
          if (!isPhone && adminFarmOpen(authProvider)) ...[
            const SizedBox(width: 8),
            const Flexible(child: AdminFarmChip(compact: true)),
          ],
        ],
      ),
      bottom: isPhone ? adminFarmAppBarBottom(context) : null,
      elevation: 0,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      actions: [
        if (authProvider.canSwitchCompany) _buildFarmSwitcher(context, authProvider),
        if (!authProvider.isAuditer) _buildNotificationBell(context),
        if (widget.actions != null) ...widget.actions!,
        // English / Afrikaans
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Center(child: LanguageToggle(compact: true, onDark: true)),
        ),
      ],
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
                    child: Material(
                      // ListTiles paint on the nearest Material; the coloured container
                      // above would hide their selection/hover effects.
                      type: MaterialType.transparency,
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
                                ..._visibleMenuItems(authProvider).map((item) {
                                  final bool isSelected = routeProvider.activeRoute == item['route'];

                                  return _buildMenuItem(
                                    context,
                                    item['icon'],
                                    _menuTitle(context, item['route'] as String),
                                    item['route'],
                                    isSelected,
                                    _isSidebarCollapsed,
                                    onTap: () {
                                      routeProvider.setActiveRoute(item['route']);
                                      Navigator.of(context).pushReplacementNamed(item['route']);
                                    },
                                  );
                                }).toList(),

                                // Farmable section — only shown when company has a linked farm
                                if (!authProvider.isAuditer && authProvider.effectiveCompany?.hasFarmable == true) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          context.l10n.menuFarmableSection,
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
                                  _buildMenuItem(
                                    context,
                                    Icons.map_outlined,
                                    context.l10n.menuFarmRegister,
                                    RouteConstants.farmRegister,
                                    routeProvider.activeRoute == RouteConstants.farmRegister,
                                    _isSidebarCollapsed,
                                    onTap: () {
                                      routeProvider.setActiveRoute(RouteConstants.farmRegister);
                                      Navigator.of(context).pushReplacementNamed(RouteConstants.farmRegister);
                                    },
                                  ),
                                  _buildMenuItem(
                                    context,
                                    Icons.science_outlined,
                                    context.l10n.menuSprayRecords,
                                    RouteConstants.sprayRecords,
                                    routeProvider.activeRoute == RouteConstants.sprayRecords,
                                    _isSidebarCollapsed,
                                    onTap: () {
                                      routeProvider.setActiveRoute(RouteConstants.sprayRecords);
                                      Navigator.of(context).pushReplacementNamed(RouteConstants.sprayRecords);
                                    },
                                  ),
                                ],

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
                                      _menuTitle(context, item['route'] as String),
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
                                  context.l10n.logout,
                                  '',
                                  false,
                                  _isSidebarCollapsed,
                                  onTap: () => signOutAndReset(context),
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
                                      context.l10n.menuCollapse,
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

  /// Menu entries this user may see. Auditors get the Audit Index and nothing
  /// else; everyone else gets the full list.
  /// Menu item names in the app language, by route.
  String _menuTitle(BuildContext context, String route) {
    final l10n = context.l10n;
    switch (route) {
      case RouteConstants.dashboard:
        return l10n.dashboardTitle;
      case RouteConstants.auditTracker:
        return l10n.trackerTitle;
      case RouteConstants.complianceReport:
        return l10n.menuComplianceReport;
      case RouteConstants.auditIndex:
        return l10n.menuAuditIndex;
      case RouteConstants.payslipManager:
        return l10n.menuPayslipManager;
      case RouteConstants.myFarms:
        return l10n.menuMyFarms;
      case RouteConstants.userManagement:
        return l10n.menuUserManagement;
      case RouteConstants.categoryManagement:
        return l10n.menuCategoryManagement;
      case RouteConstants.overrid:
        return l10n.menuDocumentSettings;
      case RouteConstants.companyManagement:
        return l10n.menuCompanyManagement;
      case RouteConstants.dataFixUtility:
        return l10n.menuDataFixUtility;
      case RouteConstants.farmableConsole:
        return l10n.menuFarmableConsole;
    }
    return route;
  }

  List<Map<String, dynamic>> _visibleMenuItems(AuthProvider auth) {
    final items = auth.isAuditer
        ? _menuItems.where((i) => i['route'] == RouteConstants.auditIndex).toList()
        : _menuItems;
    // Users with several farms get their farm picker at the top of the menu.
    if (auth.canSwitchCompany) {
      return [
        {
          'icon': Icons.agriculture_outlined,
          'route': RouteConstants.myFarms,
          'adminOnly': false,
        },
        ...items,
      ];
    }
    return items;
  }

  /// App-bar chip showing the farm in view; tapping opens the farm switcher.
  /// Icon-only on narrow screens so it can never crowd the title.
  Widget _buildFarmSwitcher(BuildContext context, AuthProvider auth) {
    final name = auth.effectiveCompany?.name ?? context.l10n.farmSelect;
    final compact = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: context.l10n.farmSwitchTooltip(name),
        child: Material(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showFarmSwitcher(context, auth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.agriculture_outlined, color: Colors.white, size: 18),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFarmSwitcher(BuildContext context, AuthProvider auth) async {
    final currentId = auth.effectiveCompany?.id;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FarmSwitcherSheet(
        farms: auth.accessibleCompanies,
        currentId: currentId,
      ),
    );

    if (selected == null || selected == currentId || !context.mounted) return;

    final ok = await switchFarm(context, selected);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.farmSwitchFailed)),
      );
    }
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
                  TextSpan(text: context.l10n.adminModeManagingFor),
                  TextSpan(
                    text: authProvider.selectedUser!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : Text(
              context.l10n.adminModeOwnDocs,
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
              label: Text(
                context.l10n.actionSwitchBack,
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
              tooltip: context.l10n.selectUserToManage,
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
                context.l10n.selectUserToManage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.selectUserToManageHint,
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
                        title: Text(authProvider.currentUser?.name ?? context.l10n.you),
                        subtitle: Text(context.l10n.manageOwnDocs),
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
                        subtitle: Text(user.role.label(context.l10n)),
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
                    child: Text(context.l10n.commonCancel),
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

          // Farm switcher — only for users with access to more than one farm.
          // (The app-bar chip is icon-only on phones, so this is the clear way in.)
          if (authProvider.canSwitchCompany)
            ListTile(
              leading: Icon(Icons.swap_horiz, color: primaryColor),
              title: Text(
                authProvider.effectiveCompany?.name ?? context.l10n.farmSelect,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(context.l10n.farmTapToSwitch, style: const TextStyle(fontSize: 12)),
              tileColor: primaryColor.withOpacity(0.06),
              onTap: () {
                Navigator.of(context).pop(); // close the drawer
                _showFarmSwitcher(context, authProvider);
              },
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
                ..._visibleMenuItems(authProvider).map((item) {
                  final bool isSelected = routeProvider.activeRoute == item['route'];

                  return _buildMenuItem(
                    context,
                    item['icon'],
                    _menuTitle(context, item['route'] as String),
                    item['route'],
                    isSelected,
                    false,
                    onTap: () {
                      routeProvider.setActiveRoute(item['route']);
                      Navigator.of(context).pushReplacementNamed(item['route']);
                    },
                  );
                }).toList(),

                // Farmable section in drawer
                if (!authProvider.isAuditer && authProvider.effectiveCompany?.hasFarmable == true) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          context.l10n.menuFarmableSection,
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
                  _buildMenuItem(
                    context,
                    Icons.map_outlined,
                    context.l10n.menuFarmRegister,
                    RouteConstants.farmRegister,
                    routeProvider.activeRoute == RouteConstants.farmRegister,
                    false,
                    onTap: () {
                      routeProvider.setActiveRoute(RouteConstants.farmRegister);
                      Navigator.of(context).pushReplacementNamed(RouteConstants.farmRegister);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.science_outlined,
                    context.l10n.menuSprayRecords,
                    RouteConstants.sprayRecords,
                    routeProvider.activeRoute == RouteConstants.sprayRecords,
                    false,
                    onTap: () {
                      routeProvider.setActiveRoute(RouteConstants.sprayRecords);
                      Navigator.of(context).pushReplacementNamed(RouteConstants.sprayRecords);
                    },
                  ),
                ],

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
                      _menuTitle(context, item['route'] as String),
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
                  context.l10n.logout,
                  '',
                  false,
                  false,
                  onTap: () => signOutAndReset(context),
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
                  : '',
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
                    authProvider.currentUser?.name ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    authProvider.currentUser?.role.name ?? '',
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

  /// Notification bell with an unread-count badge, shown in the app bar.
  Widget _buildNotificationBell(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notif, _) {
        final count = notif.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: context.l10n.notificationsTitle,
              onPressed: () {
                Navigator.of(context).pushNamed(RouteConstants.notifications);
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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

/// Bottom sheet listing the farms a user may switch between. Searchable once
/// the list is long enough to need it.
class _FarmSwitcherSheet extends StatefulWidget {
  final List<CompanyModel> farms;
  final String? currentId;

  const _FarmSwitcherSheet({required this.farms, required this.currentId});

  @override
  State<_FarmSwitcherSheet> createState() => _FarmSwitcherSheetState();
}

class _FarmSwitcherSheetState extends State<_FarmSwitcherSheet> {
  String _query = '';

  String _packagesLabel(CompanyModel c) {
    final labels = AppConstants.auditPackages
        .where((p) => c.packages.contains(p.id))
        .map((p) => p.shortLabel)
        .toList();
    return labels.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final q = _query.trim().toLowerCase();
    final farms = q.isEmpty
        ? widget.farms
        : widget.farms.where((f) => f.name.toLowerCase().contains(q)).toList();
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  context.l10n.farmSwitchFarm,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  context.l10n.farmAccessCount(widget.farms.length),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              if (widget.farms.length > 6)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: context.l10n.farmSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: farms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(context.l10n.farmNoMatchQuery(_query),
                              style: TextStyle(color: Colors.grey[600])),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: farms.length,
                        itemBuilder: (context, i) {
                          final farm = farms[i];
                          final isCurrent = farm.id == widget.currentId;
                          final subtitle = _packagesLabel(farm);
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  isCurrent ? primary : primary.withOpacity(0.12),
                              child: Text(
                                farm.name.isNotEmpty ? farm.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              farm.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            subtitle: subtitle.isEmpty ? null : Text(subtitle),
                            trailing: isCurrent
                                ? Icon(Icons.check_circle, color: primary)
                                : null,
                            onTap: () => Navigator.of(context).pop(farm.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}