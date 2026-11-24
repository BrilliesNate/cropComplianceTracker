import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:cropCompliance/models/company_model.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../core/constants/route_constants.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/utils/session_store.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthProvider() {
    _authSub = _authService.authStateChanges.listen(_onFirebaseUserChanged);
  }

  // ── Session integrity ─────────────────────────────────────────────────────
  // Everything Firestore does is authorised as Firebase Auth's signed-in
  // account — not as the user this app is showing. On the web that account is
  // shared by every tab of the same address, so signing in (or out) in another
  // tab can change it underneath this one. If the two ever disagree we end the
  // session here rather than carry on showing one person's screen while acting
  // as another.
  StreamSubscription<User?>? _authSub;
  bool _signingOut = false; // an intentional logout is in progress
  bool _sessionEnded = false; // consumed by the app shell to return to login

  void _onFirebaseUserChanged(User? firebaseUser) {
    final home = _homeUser;
    if (home == null || _signingOut) return; // nobody signed in on screen
    if (firebaseUser != null && firebaseUser.uid == home.id) return;

    print('AuthProvider: Firebase account changed '
        '(${home.email} → ${firebaseUser?.email ?? 'signed out'}); ending session');
    _clearSession();
    _error = firebaseUser == null
        ? LocaleProvider.instance.l10n.authSignedOut
        : LocaleProvider.instance.l10n.authOtherAccount;
    _sessionEnded = true;
    notifyListeners();
  }

  /// True once (then resets) after the session was ended by a change of the
  /// Firebase account; the app shell uses it to send the user to the login page.
  bool takeSessionEnded() {
    final ended = _sessionEnded;
    _sessionEnded = false;
    return ended;
  }

  // ── Remembering the farm in view across a page reload ────────────────────
  // A reload (or the browser silently restoring a background tab) used to drop
  // the farm a multi-farm user had switched to, and the company an admin was
  // viewing, landing them somewhere else. These per-tab keys bring them back.
  String _farmKey(String uid) => 'cc.activeFarm.$uid';
  String _adminCompanyKey(String uid) => 'cc.adminCompany.$uid';

  void _rememberFarm(String companyId) {
    final uid = _homeUser?.id;
    if (uid != null) SessionStore.write(_farmKey(uid), companyId);
  }

  void _rememberAdminCompany(String? companyId) {
    final uid = _homeUser?.id;
    if (uid == null) return;
    if (companyId == null) {
      SessionStore.remove(_adminCompanyKey(uid));
    } else {
      SessionStore.write(_adminCompanyKey(uid), companyId);
    }
  }

  /// After a reload: put the user back on the farm / company they had open.
  Future<void> _restoreViewAfterReload() async {
    final home = _homeUser;
    if (home == null) return;
    if (isAdmin) {
      final id = SessionStore.read(_adminCompanyKey(home.id));
      if (id == null || id.isEmpty) return;
      final company = await _firestoreService.getCompany(id);
      if (company != null) {
        _selectedCompany = company;
      } else {
        SessionStore.remove(_adminCompanyKey(home.id));
      }
      return;
    }
    final farmId = SessionStore.read(_farmKey(home.id));
    if (farmId == null || farmId.isEmpty) return;
    if (_currentUser?.companyId == farmId) return;
    for (final c in _accessibleCompanies) {
      if (c.id == farmId) {
        _currentCompany = c;
        _currentUser = home.copyWith(companyId: farmId);
        return;
      }
    }
    SessionStore.remove(_farmKey(home.id)); // no longer one of their farms
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // The user as stored in Firestore (primary company, farm-access list, etc).
  // Never mutated by farm switching.
  UserModel? _homeUser;

  // The user as the rest of the app sees them. Identical to [_homeUser] except
  // that, for a multi-farm user who has switched farms, `companyId` is the farm
  // currently in view. Everything that reads `currentUser.companyId` therefore
  // follows the switch without needing to know about it. Never written back.
  UserModel? _currentUser;

  CompanyModel? _currentCompany; // The farm currently in view (non-admin)
  List<CompanyModel> _accessibleCompanies = []; // Farms this user may switch between
  bool _isLoading = false;
  String? _error;

  // Company selection for admins
  CompanyModel? _selectedCompany;
  List<UserModel> _allUsers = []; // Keep for user management screen
  bool _isLoadingUsers = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  CompanyModel? get currentCompany => _currentCompany;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.role == UserRole.ADMIN;
  bool get isAuditer => _currentUser?.role == UserRole.AUDITER;
  bool get isUser => _currentUser?.role == UserRole.USER;

  /// The first screen inside a farm. Auditors only ever see the Audit Index.
  String get farmHomeRoute =>
      isAuditer ? RouteConstants.auditIndex : RouteConstants.dashboard;

  /// Where this user lands after signing in. Admins get the admin dashboard and
  /// users with several farms get the farm picker (My Farms); everyone else goes
  /// straight into their one farm.
  String get homeRoute {
    if (isAdmin) return RouteConstants.adminDashboard;
    if (canSwitchCompany) return RouteConstants.myFarms;
    return farmHomeRoute;
  }

  // ── Multi-farm access ─────────────────────────────────────────────────────

  /// Farms this user has been given access to (alphabetical). Empty for admins,
  /// who work through company selection instead.
  List<CompanyModel> get accessibleCompanies => _accessibleCompanies;

  /// True when the user has more than one farm to choose between.
  bool get canSwitchCompany => !isAdmin && _accessibleCompanies.length > 1;

  // DEPRECATED: User selection getters - kept for backward compatibility but always return null/false
  // TODO: Remove these once all files are updated
  UserModel? get selectedUser => null; // CHANGED: Always null - no user selection
  bool get hasSelectedUser => false; // CHANGED: Always false - no user selection

  // Keep these for backward compatibility
  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get companyUsers => _allUsers;
  bool get isLoadingUsers => _isLoadingUsers;

  // Company selection getters
  CompanyModel? get selectedCompany => _selectedCompany;
  bool get isManagingCompany => _selectedCompany != null;

  // CHANGED: effectiveUser now always returns currentUser (no user switching)
  UserModel? get effectiveUser => _currentUser;

  // Get the effective company (selected company for admin, or current user's company)
  CompanyModel? get effectiveCompany => _selectedCompany ?? _currentCompany;

  // Get available packages for the effective company
  List<String> get effectivePackages => effectiveCompany?.packages ?? ['siza_wieta'];

  // Check if effective company has specific packages
  bool get hasSizaWieta => effectiveCompany?.hasSizaWieta ?? true;
  bool get hasGlobalGap => effectiveCompany?.hasGlobalGap ?? false;
  bool get hasBothPackages => effectiveCompany?.hasBothPackages ?? false;

  // CHANGED: Always false - admins manage companies, not individual users
  bool get isActingOnBehalfOfUser => false;

  /// Adopts [user] as the signed-in user, with their primary company in view.
  void _adoptUser(UserModel user) {
    _homeUser = user;
    _currentUser = user;
    _selectedCompany = null;
    _currentCompany = null;
    _accessibleCompanies = [];
  }

  // Initialize
  Future<void> initializeUser() async {
    _setLoading(true);
    _error = null;

    try {
      // Wait for Firebase to finish restoring the saved session (web reload).
      final user = await _authService.restoredUser();
      if (user != null) {
        final stored = await _authService.getUserData(user.uid);

        if (stored != null && !stored.isActive) {
          // Resuming a session on an account that was deactivated meanwhile.
          await _authService.logoutUser();
          _clearSession();
          _error = AccountDeactivatedException.message;
          return;
        }

        if (stored != null) _adoptUser(stored);

        // Load the user's company (and, for multi-farm users, all their farms)
        // and — for admins — every user, side by side rather than one after the
        // other (every round trip here is time before the first screen).
        if (_currentUser != null) {
          await Future.wait([
            _loadCurrentCompany(),
            if (isAdmin) loadAllUsers(),
          ]);
          await _restoreViewAfterReload();
        }
      }
    } catch (e) {
      _error = LocaleProvider.instance.l10n.authInitFailed('$e');
    } finally {
      _setLoading(false);
    }
  }

  // Load the current user's company — and, for non-admins with access to more
  // than one farm, every farm they can switch to.
  Future<void> _loadCurrentCompany() async {
    final home = _homeUser;
    if (home == null) return;

    try {
      if (!isAdmin && home.hasMultipleCompanies) {
        final loaded = await Future.wait(
          home.accessibleCompanyIds.map((id) async {
            try {
              final doc = await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(id)
                  .get();
              if (!doc.exists) {
                print('AuthProvider: farm $id no longer exists');
                return null;
              }
              return CompanyModel.fromMap(doc.data()!, doc.id);
            } catch (e) {
              // Usually "permission-denied": the Firestore rules that allow
              // reading extra farms haven't been deployed.
              print('AuthProvider: cannot read farm $id: $e');
              return null;
            }
          }),
        );
        if (loaded.whereType<CompanyModel>().length < home.accessibleCompanyIds.length) {
          print('AuthProvider: only ${loaded.whereType<CompanyModel>().length} of '
              '${home.accessibleCompanyIds.length} farms could be loaded for ${home.email}');
        }
        _accessibleCompanies = loaded.whereType<CompanyModel>().toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        // Prefer the primary farm; if it can't be loaded fall back to the first
        // farm that can, so the user is never left with no farm in view.
        CompanyModel? start;
        for (final c in _accessibleCompanies) {
          if (c.id == home.companyId) start = c;
        }
        start ??= _accessibleCompanies.isNotEmpty ? _accessibleCompanies.first : null;

        _currentCompany = start;
        if (start != null) _currentUser = home.copyWith(companyId: start.id);
      } else {
        _currentCompany = await _firestoreService.getCompany(home.companyId);
        _accessibleCompanies = [if (_currentCompany != null) _currentCompany!];
      }
      print('AuthProvider: Loaded company ${_currentCompany?.name} with packages: ${_currentCompany?.packages} '
          '(${_accessibleCompanies.length} accessible farm(s))');
    } catch (e) {
      print('AuthProvider: Error loading company: $e');
    }
  }

  /// Switches a multi-farm user to another farm they have been granted. Returns
  /// false if the farm isn't one of theirs (or can't be loaded).
  Future<bool> switchCompany(String companyId) async {
    final home = _homeUser;
    if (isAdmin || home == null || !home.canAccessCompany(companyId)) return false;
    if (_currentUser?.companyId == companyId && _currentCompany?.id == companyId) {
      return true;
    }

    CompanyModel? company;
    for (final c in _accessibleCompanies) {
      if (c.id == companyId) company = c;
    }
    company ??= await _firestoreService.getCompany(companyId);
    if (company == null) return false;

    _currentCompany = company;
    _currentUser = home.copyWith(companyId: companyId);
    _rememberFarm(companyId);
    notifyListeners();
    print('AuthProvider: Switched to farm ${company.name} (ID: $companyId)');
    return true;
  }

  // Load ALL users from the system (for user management, not for selection)
  Future<void> loadAllUsers() async {
    if (!isAdmin || _currentUser == null) return;

    _isLoadingUsers = true;
    notifyListeners();

    try {
      _allUsers = await _firestoreService.getUsers();
      _allUsers.sort((a, b) => a.name.compareTo(b.name));

      print('AuthProvider: Loaded ${_allUsers.length} users');
    } catch (e) {
      print('Error loading all users: $e');
      _error = LocaleProvider.instance.l10n.authLoadUsersFailed('$e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  // Set selected company (admin managing a company)
  void setSelectedCompany(CompanyModel company) {
    if (!isAdmin) return;

    _selectedCompany = company;
    _rememberAdminCompany(company.id);
    notifyListeners();

    print('AuthProvider: Admin now managing company: ${company.name} (ID: ${company.id})');
  }

  // DEPRECATED: User selection - does nothing now
  // TODO: Remove once all files are updated
  void selectUser(UserModel user) {
    print('AuthProvider: selectUser() is deprecated - admins should select companies, not users');
    // Do nothing - user selection is removed
  }

  // Clear company selection (admin goes back to admin dashboard)
  void clearCompanySelection() {
    if (!isAdmin) return;

    print('AuthProvider: Clearing company selection');
    _selectedCompany = null;
    _rememberAdminCompany(null);
    notifyListeners();
    print('AuthProvider: Company selection cleared');
  }

  // DEPRECATED: Alias for clearCompanySelection - kept for backward compatibility
  // TODO: Update all files to use clearCompanySelection() then remove this
  void clearUserSelection() {
    clearCompanySelection();
  }

  // Get display name for current context
  String getContextDisplayName() {
    if (isManagingCompany) {
      return LocaleProvider.instance.l10n.authAdminView(_selectedCompany!.name);
    }
    return _currentUser?.name ?? LocaleProvider.instance.l10n.unknownUser;
  }

  // Get context description for admin actions
  String getContextDescription() {
    if (isManagingCompany) {
      return LocaleProvider.instance.l10n.authManaging(_selectedCompany!.name);
    }
    return LocaleProvider.instance.l10n.authPersonalAccount;
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
        _adoptUser(user);
        _allUsers = [];

        // Load the user's company (and farms they can switch between), plus
        // every user for admins, in parallel.
        await Future.wait([
          _loadCurrentCompany(),
          if (isAdmin) loadAllUsers(),
        ]);

        return true;
      } else {
        _error = LocaleProvider.instance.l10n.authInvalidLogin;
        return false;
      }
    } on AccountDeactivatedException {
      _clearSession();
      _error = AccountDeactivatedException.message;
      return false;
    } catch (e) {
      _error = LocaleProvider.instance.l10n.authLoginFailed('$e');
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
        _adoptUser(user);
        _allUsers = [];

        // Load the user's company
        await _loadCurrentCompany();

        // Load all users if admin
        if (isAdmin) {
          await loadAllUsers();
        }

        return true;
      } else {
        _error = LocaleProvider.instance.l10n.authRegisterFailed;
        return false;
      }
    } catch (e) {
      _error = LocaleProvider.instance.l10n.authRegisterFailedReason('$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    _signingOut = true;

    try {
      await _authService.logoutUser();
      _clearSession();
    } catch (e) {
      _error = LocaleProvider.instance.l10n.authLogoutFailed('$e');
    } finally {
      _signingOut = false;
      _setLoading(false);
    }
  }

  /// Forgets everything about the signed-in user.
  void _clearSession() {
    final uid = _homeUser?.id;
    if (uid != null) {
      SessionStore.remove(_farmKey(uid));
      SessionStore.remove(_adminCompanyKey(uid));
    }
    _homeUser = null;
    _currentUser = null;
    _currentCompany = null;
    _accessibleCompanies = [];
    _selectedCompany = null;
    _allUsers = [];
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _authService.resetPassword(email);
      return result;
    } catch (e) {
      _error = LocaleProvider.instance.l10n.authResetFailed('$e');
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
