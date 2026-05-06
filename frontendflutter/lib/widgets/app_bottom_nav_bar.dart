import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/role_constants.dart';

/// Barra de navegación inferior reutilizable para todas las pantallas.
/// Muestra opciones: Listado, Mapa, Perfil, y Administración (solo para roles != usuario).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRoleId,
  });

  /// Índice del elemento actualmente seleccionado (0=Listado, 1=Mapa, 2=Perfil, 3=Admin)
  final int currentIndex;

  /// Callback cuando se selecciona una opción
  final ValueChanged<int> onTap;

  /// ID del rol del usuario (null si no está autenticado)
  final int? userRoleId;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Listado',
      ),
      const _NavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: 'Mapa',
      ),
      const _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Perfil',
      ),
      // Mostrar tab de administración solo si el usuario no es un usuario normal (rol != 1)
      if (userRoleId != null && userRoleId != RoleConstants.rolUsuario)
        const _NavItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          label: 'Administración',
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(AppColors.white),
        border: Border(
          top: BorderSide(
            color: Color(0x1A000000),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return Expanded(
              child: InkResponse(
                onTap: () => onTap(index),
                radius: 28,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(AppColors.accentBeige).withValues(alpha: 0.7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? const Color(AppColors.primaryOrange)
                            : const Color(AppColors.lightText),
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? const Color(AppColors.primaryOrange)
                                  : const Color(AppColors.lightText),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Clase interna para almacenar datos de los items de navegación
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
