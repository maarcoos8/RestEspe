import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/role_constants.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/services/admin_service.dart';
import '../providers/auth_provider.dart';
import '../screens/create_establishment_screen.dart';

/// Widget que muestra los botones de acción para un establecimiento.
/// Incluye botones para editar, borrar y verificar.
class EstablishmentActionsButtons extends StatefulWidget {
  const EstablishmentActionsButtons({
    super.key,
    required this.restaurant,
    this.onDeleted,
    this.onEdit,
    this.onVerify,
  });

  final RestaurantDetail restaurant;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdit;
  final VoidCallback? onVerify;

  @override
  State<EstablishmentActionsButtons> createState() =>
      _EstablishmentActionsButtonsState();
}

class _EstablishmentActionsButtonsState
    extends State<EstablishmentActionsButtons> {
  bool _isDeleting = false;

  void _onEdit() {
    // Extraer los IDs de tipos de establecimiento
    final tiposIds = widget.restaurant.tiposEstablecimiento
        .map((tipo) => tipo.idTipo)
        .toList();

    // Navegar a la pantalla de edición
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEstablishmentScreen(
          restaurantToEdit: widget.restaurant,
          tiposEstablecimientoIds: tiposIds,
        ),
      ),
    ).then((result) {
      // Si se guardó exitosamente (result == true), ejecutar el callback
      if (result == true) {
        widget.onEdit?.call();
      }
    });
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar establecimiento'),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${widget.restaurant.nombre}"? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _isDeleting
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _deleteEstablishment();
                    },
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppColors.errorRed),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEstablishment() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await AdminService.deleteEstablecimiento(
        widget.restaurant.idEstablecimiento,
      );

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Establecimiento "${widget.restaurant.nombre}" eliminado correctamente',
          ),
          backgroundColor: const Color(AppColors.successGreen),
          duration: const Duration(seconds: 2),
        ),
      );

      // Llamar el callback y navegar atrás
      widget.onDeleted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.toString()}'),
          backgroundColor: const Color(AppColors.errorRed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.currentUser;
        
        // Verificar si el usuario tiene permisos para ver estos botones
        final canManage = RoleConstants.canManageEstablishments(currentUser?.idRol);
        final isOwner = currentUser?.idUsuario == widget.restaurant.propietarioId;
        final canDelete = (canManage && isOwner) || RoleConstants.isAdmin(currentUser?.idRol);
        
        // Si el usuario no tiene permisos, no mostrar los botones
        if (!canDelete) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón Editar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(AppColors.white),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onEdit,
                  borderRadius: BorderRadius.circular(14),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(AppColors.primaryBlue),
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Borrar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(AppColors.white),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showDeleteConfirmationDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(AppColors.errorRed),
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Verificar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(AppColors.white),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onVerify,
                  borderRadius: BorderRadius.circular(14),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(AppColors.primaryGreen),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
