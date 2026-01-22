import 'package:cropCompliance/models/company_model.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  CompanyModel? _currentCompany; // NEW: The logged-in user's company
  bool _isLoading = false;
  String? _error;

  // User selection for admins
  UserModel? _selectedUser;
  CompanyModel? _selectedCompany;
  List<UserModel> _allUsers = [];
  bool _isLoadingUsers = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  CompanyModel? get currentCompany => _currentCompany; // NEW
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.role == UserRole.ADMIN;
  bool get isAuditer => _currentUser?.role == UserRole.AUDITER;
  bool get isUser => _currentUser?.role == UserRole.USER;

  // User selection getters
  UserModel? get selectedUser => _selectedUser;
  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get companyUsers => _allUsers; // Keep for backward compatibility
  CompanyModel? get selectedCompany => _selectedCompany;
  bool get isManagingCompany => _selectedCompany != null;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get hasSelectedUser => _selectedUser != null;

  // Get the effective user (selected user for admin operations, or current user)
  UserModel? get effectiveUser => _selectedUser ?? _currentUser;

  // NEW: Get the effective company (selected company for admin, or current user's company)
  CompanyModel? get effectiveCompany => _selectedCompany ?? _currentCompany;

  // NEW: Get available packages for the effective company
  List<String> get effectivePackages => effectiveCompany?.packages ?? ['siza_wieta'];

  // NEW: Check if effective company has specific packages
  bool get hasSizaWieta => effectiveCompany?.hasSizaWieta ?? true;
  bool get hasGlobalGap => effectiveCompany?.hasGlobalGap ?? false;
  bool get hasBothPackages => effectiveCompany?.hasBothPackages ?? false;

  // Check if admin is acting on behalf of another user
  bool get isActingOnBehalfOfUser => isAdmin && _selectedUser != null && _selectedUser!.id != _currentUser!.id;

  // Initialize
  Future<void> initializeUser() async {
    _setLoading(true);
    _error = null;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);

        // NEW: Load the user's company
        if (_currentUser != null) {
          await _loadCurrentCompany();
        }

        // If admin, load ALL users for selection
        if (isAdmin && _currentUser != null) {
          await loadAllUsers();
        }
      }
    } catch (e) {
      _error = 'Failed to initialize user: $e';
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Load the current user's company
  Future<void> _loadCurrentCompany() async {
    if (_currentUser == null) return;

    try {
      _currentCompany = await _firestoreService.getCompany(_currentUser!.companyId);
      print('AuthProvider: Loaded company ${_currentCompany?.name} with packages: ${_currentCompany?.packages}');
    } catch (e) {
      print('AuthProvider: Error loading company: $e');
    }
  }

  // Load ALL users from the system for admin selection
  Future<void> loadAllUsers() async {
    if (!isAdmin || _currentUser == null) return;

    _isLoadingUsers = true;
    notifyListeners();

    try {
      _allUsers = await _firestoreService.getUsers();
      _allUsers.sort((a, b) => a.name.compareTo(b.name));

      print('AuthProvider: Loaded ${_allUsers.length} users for admin selection');

      for (var user in _allUsers) {
        print('User: ${user.name} (${user.email}) - Company: ${user.companyId}');
      }

    } catch (e) {
      print('Error loading all users: $e');
      _error = 'Failed to load users: $e';
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  void setSelectedCompany(CompanyModel company) {
    if (!isAdmin) return;

    _selectedCompany = company;
    notifyListeners();

    print('AuthProvider: Admin now managing company: ${company.name}');
  }

  // Enhanced user selection with better debugging
  void selectUser(UserModel user) {
    if (!isAdmin) {
      print('Only admins can select users');
      return;
    }

    print('AuthProvider: Admin selecting user: ${user.name} (${user.email}) from company: ${user.companyId}');

    _selectedUser = user;
    notifyListeners();

    print('AuthProvider: User selection completed. Selected user ID: ${user.id}');
  }

  // Clear user selection (admin goes back to managing their own account)
  void clearUserSelection() {
    if (!isAdmin) return;

    print('AuthProvider: Clearing user selection');
    _selectedUser = null;
    _selectedCompany = null;
    notifyListeners();
    print('AuthProvider: User and company selection cleared');
  }

  // Get display name for current context
  String getContextDisplayName() {
    if (isActingOnBehalfOfUser) {
      return '${_selectedUser!.name} (via ${_currentUser!.name})';
    }
    return _currentUser?.name ?? 'Unknown User';
  }

  // Get context description for admin actions
  String getContextDescription() {
    if (isActingOnBehalfOfUser) {
      return 'Acting as ${_selectedUser!.name}';
    }
    return 'Personal account';
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;

        // Clear any previous selections
        _selectedUser = null;
        _selectedCompany = null;
        _allUsers = [];

        // NEW: Load the user's company
        await _loadCurrentCompany();

        // Load all users if admin
        if (isAdmin) {
          await loadAllUsers();
        }

        return true;
      } else {
        _error = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String companyId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.registerUser(
        email: email,
        password: password,
        name: name,
        companyId: companyId,
      );

      if (user != null) {
        _currentUser = user;

        // Clear any previous selections
        _selectedUser = null;
        _selectedCompany = null;
        _allUsers = [];

        // NEW: Load the user's company
        await _loadCurrentCompany();

        // Load all users if admin
        if (isAdmin) {
          await loadAllUsers();
        }

        return true;
      } else {
        _error = 'Registration failed';
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logoutUser();
      _currentUser = null;
      _currentCompany = null; // NEW: Clear company

      // Clear user selection data
      _selectedUser = null;
      _selectedCompany = null;
      _allUsers = [];
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _authService.resetPassword(email);
      return result;
    } catch (e) {
      _error = 'Password reset failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}