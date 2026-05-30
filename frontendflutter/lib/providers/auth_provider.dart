import 'package:flutter/foundation.dart';
import 'package:frontendflutter/core/auth_token_store.dart';

import 'package:frontendflutter/data/models/auth_models.dart';
import 'package:frontendflutter/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  GoogleUserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  GoogleUserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<GoogleUserProfile?> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      AuthTokenStore.setToken(user?.idToken);
      return user;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    AuthTokenStore.clear();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
