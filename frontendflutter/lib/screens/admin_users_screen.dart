import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../data/models/admin_user_model.dart';
import '../data/models/rol_model.dart';
import '../data/services/admin_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/scaffold_with_nav.dart';

/// Pantalla de administración de usuarios (superadmin).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AdminUserModel> _displayedUsers = [];
  List<RolModel> _roles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final usuarios = await AdminService.getUsuarios();
      final roles = await AdminService.getRoles();

      // Filter out current user
      final currentUserId = context.read<AuthProvider>().currentUser?.idUsuario;
      final filtered = usuarios.where((u) => u.idUsuario != currentUserId).toList();

      setState(() {
        _displayedUsers = filtered;
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editRole(AdminUserModel user) async {
    RolModel? selectedRole = _roles.firstWhere(
      (r) => r.idRol == user.idRol,
      orElse: () => RolModel(idRol: user.idRol ?? 0, nombreRol: 'Desconocido'),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(AppColors.white),
              title: Text(
                'Editar Rol: ${user.nombreCompleto}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(AppColors.darkText),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar nuevo rol:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(AppColors.darkText),
                          ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RolModel>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _roles
                          .map((rol) => DropdownMenuItem(
                                value: rol,
                                child: Text(rol.nombreRol),
                              ))
                          .toList(),
                      onChanged: (RolModel? newRole) {
                        if (newRole != null) {
                          setState(() {
                            selectedRole = newRole;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(AppColors.lightText),
                        ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColors.primaryOrange),
                  ),
                  onPressed: () async {
                    if (selectedRole != null && selectedRole!.idRol != user.idRol) {
                      try {
                        await AdminService.updateUsuarioRol(user.idUsuario, selectedRole!.idRol);
                        Navigator.pop(context);
                        _loadData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar rol: $e'),
                            backgroundColor: const Color(AppColors.errorRed),
                          ),
                        );
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Color(AppColors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(AdminUserModel user) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.white),
          title: Text(
            'Eliminar Usuario',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(AppColors.darkText),
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar a ${user.nombreCompleto}? Esta acción no se puede deshacer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(AppColors.darkText),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(AppColors.lightText),
                    ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.errorRed),
              ),
              onPressed: () async {
                try {
                  await AdminService.deleteUsuario(user.idUsuario);
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.nombreCompleto} ha sido eliminado'),
                      backgroundColor: const Color(AppColors.successGreen),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar usuario: $e'),
                      backgroundColor: const Color(AppColors.errorRed),
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Color(AppColors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Administración de Usuarios',
      currentIndex: 3,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(AppColors.primaryOrange)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(AppColors.errorRed),
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.primaryOrange),
              ),
              onPressed: _loadData,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Color(AppColors.white)),
              ),
            ),
          ],
        ),
      );
    }

    if (_displayedUsers.isEmpty) {
      return Center(
        child: Text(
          'No hay usuarios para mostrar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(AppColors.lightText),
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _displayedUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _displayedUsers[index];
        return _UserCard(
          user: user,
          roles: _roles,
          onEdit: () => _editRole(user),
          onDelete: () => _deleteUser(user),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  final List<RolModel> roles;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.roles,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        border: Border.all(color: const Color(0x1A000000), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Photo circle
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(AppColors.accentBeige),
            backgroundImage: user.fotoPerfil != null && user.fotoPerfil!.isNotEmpty
                ? NetworkImage(user.fotoPerfil!)
                : null,
            child: user.fotoPerfil == null || user.fotoPerfil!.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 32,
                    color: Color(AppColors.primaryOrange),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Name, email, role column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nombreCompleto ?? 'Sin nombre',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(AppColors.darkText),
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(AppColors.lightText),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rol: ${_getRoleName()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(AppColors.darkText),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Edit and delete icons
          IconButton(
            icon: const Icon(Icons.edit, color: Color(AppColors.primaryBlue)),
            onPressed: onEdit,
            tooltip: 'Editar rol',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(AppColors.errorRed)),
            onPressed: onDelete,
            tooltip: 'Eliminar usuario',
          ),
        ],
      ),
    );
  }

  String _getRoleName() {
    if (user.idRol == null) return 'Desconocido';
    try {
      final role = roles.firstWhere((r) => r.idRol == user.idRol);
      return role.nombreRol;
    } catch (e) {
      return 'Desconocido';
    }
  }
}
