import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthService get authService => _authService;
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    checkAuthState();
  }

  // Initialize and check persistent login
  Future<void> checkAuthState() async {
    final token = StorageService.getToken();
    final cachedUser = StorageService.getUser();

    if (token != null && token.isNotEmpty) {
      if (cachedUser != null) {
        _currentUser = cachedUser;
      }
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Verify token in background
      try {
        final profileRes = await _authService.getMe();
        if (profileRes.success && profileRes.data != null) {
          _currentUser = profileRes.data;
          await StorageService.saveUser(_currentUser!);
          notifyListeners();
        }
      } catch (_) {
        // Keep cached user if offline
      }
    } else {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String identifier, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.login(
      identifier: identifier,
      password: password,
    );

    if (response.success && response.data != null) {
      _currentUser = response.data;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Login failed. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    String? address,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      address: address,
    );

    if (response.success && response.data != null) {
      _currentUser = response.data;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Registration failed.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    required String fullName,
    String? email,
    String? address,
    String? phoneNumber,
  }) async {
    _errorMessage = null;
    final response = await _authService.updateProfile(
      fullName: fullName,
      email: email,
      address: address,
      phoneNumber: phoneNumber,
    );

    if (response.success && response.data != null) {
      _currentUser = response.data;
      await StorageService.saveUser(_currentUser!);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  // Change Password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _errorMessage = null;
    final response = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (response.success) {
      return true;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to update password.';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
