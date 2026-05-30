class AuthTokenStore {
  static String? _idToken;

  static String? get idToken => _idToken;

  static void setToken(String? token) {
    _idToken = token;
  }

  static void clear() {
    _idToken = null;
  }

  static Map<String, String> withAuth(Map<String, String> baseHeaders) {
    final headers = <String, String>{...baseHeaders};
    final token = _idToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
