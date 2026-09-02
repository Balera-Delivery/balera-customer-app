import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService must be initialized before use.');
    }
    return _prefs!;
  }

  // Token Operations
  static Future<bool> saveToken(String token) async {
    return await prefs.setString(AppConstants.keyToken, token);
  }

  static String? getToken() {
    return prefs.getString(AppConstants.keyToken);
  }

  static Future<bool> removeToken() async {
    return await prefs.remove(AppConstants.keyToken);
  }

  // User Operations
  static Future<bool> saveUser(UserModel user) async {
    return await prefs.setString(AppConstants.keyUser, jsonEncode(user.toJson()));
  }

  static UserModel? getUser() {
    final userJson = prefs.getString(AppConstants.keyUser);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> removeUser() async {
    return await prefs.remove(AppConstants.keyUser);
  }

  // Onboarding
  static Future<bool> setOnboardingComplete(bool complete) async {
    return await prefs.setBool(AppConstants.keyOnboardingComplete, complete);
  }

  static bool isOnboardingComplete() {
    return prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  // Clear All on Logout
  static Future<void> clearSession() async {
    await removeToken();
    await removeUser();
  }
}
