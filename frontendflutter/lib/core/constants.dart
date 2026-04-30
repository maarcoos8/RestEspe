/// Constantes de la aplicación RestEspe
class AppConstants {
  // URLs de API
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // Emulador Android
  // static const String apiBaseUrl = 'http://localhost:8000'; // Navegador Web

  // Strings
  static const String appName = 'RestEspe';
  static const String appTagline = 'Savor the best, delivered to your doorstep.';

  // Rutas
  static const String loginRoute = '/login';
  static const String mapRoute = '/map';
  static const String restaurantDetailRoute = '/restaurant/:id';

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
}

class AppColors {
  // Colores primarios
  static const int primaryOrange = 0xFFFF6B00; // Orange
  static const int primaryGreen = 0xFF008A45; // Dark Green
  static const int accentBeige = 0xFFF5EBE0; // Beige claro

  // Colores neutros
  static const int darkText = 0xFF2F3337; // Dark gray para textos
  static const int lightText = 0xFF9CA3AF; // Light gray
  static const int white = 0xFFF8F9FA;
  static const int background = 0xFFFBF7F1; // Fondo crema muy claro

  // Estados
  static const int errorRed = 0xFFDC2626;
  static const int successGreen = 0xFF10B981;
  static const int warningYellow = 0xFFF59E0B;
}
