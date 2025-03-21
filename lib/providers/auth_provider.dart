import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../core/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser!;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.role == UserRole.ADMIN;
  bool get isAuditer => _currentUser?.role == UserRole.AUDITER;
  bool get isUser => _currentUser?.role == UserRole.USER;

  // Initialize
  Future<void> initializeUser() async {
    _setLoading(true);
    _error = null;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
      }
    } catch (e) {
      _error = 'Failed to initialize user: $e';
    } finally {
      _setLoading(false);
    }
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
}