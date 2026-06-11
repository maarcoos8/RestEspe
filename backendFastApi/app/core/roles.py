"""
Role constants and definitions.
"""

# Role IDs
ROLE_USUARIO = 1
ROLE_RESPONSABLE = 2
ROLE_ADMINISTRADOR_GLOBAL = 3
ROLE_SUPERADMIN = 4

# Default role for new users (Google OAuth)
DEFAULT_ROLE_ID = ROLE_USUARIO

# Mapping for reference
ROLE_NAMES = {
    ROLE_USUARIO: "Usuario",
    ROLE_RESPONSABLE: "Responsable",
    ROLE_ADMINISTRADOR_GLOBAL: "Administrador Global",
    ROLE_SUPERADMIN: "Superadmin",
}
