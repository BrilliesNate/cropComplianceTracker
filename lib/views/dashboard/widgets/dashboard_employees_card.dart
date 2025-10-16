import 'package:flutter/material.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/firestore_service.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';
import 'package:provider/provider.dart';

class DashboardEmployeesCard extends StatefulWidget {
  final AuthProvider authProvider;

  const DashboardEmployeesCard({
    Key? key,
    required this.authProvider,
  }) : super(key: key);

  @override
  State<DashboardEmployeesCard> createState() => _DashboardEmployeesCardState();
}

class _DashboardEmployeesCardState extends State<DashboardEmployeesCard> {
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _usersPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.authProvider.isAdmin && widget.authProvider.selectedUser != null
                        ? 'All Users (Managing: ${widget.authProvider.selectedUser!.name})'
                        : widget.authProvider.isAdmin
                        ? 'All Users'
                        : 'Team Members',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.authProvider.isAdmin)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteConstants.userManagement);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    tooltip: 'Add User',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Compact Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _currentPage = 1; // Reset to first page on search
                });
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),

            // User List - NO SCROLLING, just Column with list items
            widget.authProvider.isAdmin
                ? _buildAllUsersView(context, widget.authProvider)
                : _buildCompanyUsersView(context, widget.authProvider),

            // Pagination
            const SizedBox(height: 8),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = _getTotalPages();

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage of $totalPages',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaginationButton(
                Icons.chevron_left,
                _currentPage > 1,
                    () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 4),
              _buildPaginationButton(
                Icons.chevron_right,
                _currentPage < totalPages,
                    () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllUsersView(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authProvider.allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No users found', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    final filteredUsers = authProvider.allUsers.where((user) {
      if (_searchQuery.isEmpty) return true;
      return user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery) ||
          user.role.name.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No matches', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    // Pagination
    final totalPages = (filteredUsers.length / _usersPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _usersPerPage;
    final endIndex = (startIndex + _usersPerPage > filteredUsers.length)
        ? filteredUsers.length
        : startIndex + _usersPerPage;
    final paginatedUsers = filteredUsers.sublist(startIndex, endIndex);

    // CHANGED: Use Column instead of ListView to remove scrolling
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < paginatedUsers.length; i++) ...[
          if (i > 0) Divider(height: 1, color: Colors.grey[200]),
          _buildUserListItem(
            context,
            paginatedUsers[i],
            isSelected: authProvider.selectedUser?.id == paginatedUsers[i].id,
            onTap: () => _selectUserForManagement(context, paginatedUsers[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildCompanyUsersView(BuildContext context, AuthProvider authProvider) {
    final currentCompanyId = authProvider.currentUser?.companyId;

    return FutureBuilder<List<UserModel>>(
      future: _fetchUsersForCompany(currentCompanyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Error loading team', style: TextStyle(color: Colors.red[600], fontSize: 13)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No team members', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          );
        }

        final filteredUsers = snapshot.data!.where((user) {
          if (_searchQuery.isEmpty) return true;
          return user.name.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery) ||
              user.role.name.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No matches', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          );
        }

        // Pagination
        final totalPages = (filteredUsers.length / _usersPerPage).ceil();
        if (_currentPage > totalPages && totalPages > 0) {
          _currentPage = totalPages;
        }
        final startIndex = (_currentPage - 1) * _usersPerPage;
        final endIndex = (startIndex + _usersPerPage > filteredUsers.length)
            ? filteredUsers.length
            : startIndex + _usersPerPage;
        final paginatedUsers = filteredUsers.sublist(startIndex, endIndex);

        // CHANGED: Use Column instead of ListView to remove scrolling
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < paginatedUsers.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey[200]),
              _buildUserListItem(
                context,
                paginatedUsers[i],
                isSelected: false,
                onTap: null,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUserListItem(
      BuildContext context,
      UserModel user, {
        bool isSelected = false,
        VoidCallback? onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.08) : null,
            border: isSelected
                ? Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3))
                : null,
          ),
          child: Row(
            children: [
              // Small colored dot for visual identity
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getColorFromName(user.name),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // User info - compact and scannable
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.role.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectUserForManagement(BuildContext context, UserModel user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    authProvider.selectUser(user);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading ${user.name}\'s documents...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await documentProvider.refreshForUserContext(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Now managing: ${user.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Switch Back',
              textColor: Colors.white,
              onPressed: () async {
                authProvider.clearUserSelection();
                await documentProvider.refreshForUserContext(context);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<List<UserModel>> _fetchUsersForCompany(String? companyId) async {
    if (companyId == null) return [];
    final FirestoreService firestoreService = FirestoreService();
    return firestoreService.getUsers(companyId: companyId);
  }

  Color _getColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  int _getTotalPages() {
    if (widget.authProvider.isAdmin) {
      final userCount = widget.authProvider.allUsers.where((user) {
        if (_searchQuery.isEmpty) return true;
        return user.name.toLowerCase().contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery) ||
            user.role.name.toLowerCase().contains(_searchQuery);
      }).length;
      return userCount > 0 ? (userCount / _usersPerPage).ceil() : 1;
    }
    return 1;
  }

  Widget _buildPaginationButton(IconData icon, bool enabled, VoidCallback onPressed) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Theme.of(context).primaryColor : Colors.grey[400],
        ),
      ),
    );
  }
}