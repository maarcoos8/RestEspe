/// Role constants for authorization and UI visibility.
abstract class RoleConstants {
  // Role IDs
  static const int rolUsuario = 1;
  static const int rolResponsable = 2;
  static const int rolAdministradorGlobal = 3;
  static const int rolSuperadmin = 4;

  // Default role for new users (Google OAuth)
  static const int defaultRoleId = rolUsuario;

  // Role names for display
  static const Map<int, String> roleNames = {
    rolUsuario: 'Usuario',
    rolResponsable: 'Responsable',
    rolAdministradorGlobal: 'Administrador Global',
    rolSuperadmin: 'Superadmin',
  };

  /// Get role name by ID
  static String getRoleName(int roleId) {
    return roleNames[roleId] ?? 'Desconocido';
  }

  /// Check if user has a specific role
  static bool hasRole(int? userRoleId, int requiredRoleId) {
    return userRoleId == requiredRoleId;
  }

  /// Check if user has admin-level permissions
  static bool isAdmin(int? userRoleId) {
    return userRoleId == rolAdministradorGlobal || userRoleId == rolSuperadmin;
  }

  /// Check if user is superadmin
  static bool isSuperadmin(int? userRoleId) {
    return userRoleId == rolSuperadmin;
  }

  /// Check if user can manage establishments (responsable o admin)
  static bool canManageEstablishments(int? userRoleId) {
    return userRoleId == rolResponsable ||
        userRoleId == rolAdministradorGlobal ||
        userRoleId == rolSuperadmin;
  }
}
