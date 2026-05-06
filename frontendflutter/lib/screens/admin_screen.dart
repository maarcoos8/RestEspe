import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'admin_users_screen.dart';
import 'admin_establishments_screen.dart';
import 'admin_application_screen.dart';

/// Pantalla de administración (superadmin).
/// Muestra tres apartados principales: Usuarios, Establecimientos y Aplicación.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _navigateToSection(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(AppColors.background),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administración',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Panel de control de superadmin',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(AppColors.lightText),
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                // Tarjeta: Administración de Usuarios
                _AdminCard(
                  icon: Icons.people_rounded,
                  title: 'Administración de Usuarios',
                  description: 'Gestiona los usuarios de la aplicación',
                  onTap: () =>
                      _navigateToSection(context, const AdminUsersScreen()),
                ),
                const SizedBox(height: 16),
                // Tarjeta: Administración de Establecimientos
                _AdminCard(
                  icon: Icons.store_rounded,
                  title: 'Administración de Establecimientos',
                  description: 'Gestiona los establecimientos registrados',
                  onTap: () => _navigateToSection(
                      context, const AdminEstablishmentsScreen()),
                ),
                const SizedBox(height: 16),
                // Tarjeta: Administración de la Aplicación
                _AdminCard(
                  icon: Icons.settings_rounded,
                  title: 'Administración de la Aplicación',
                  description: 'Configura y gestiona la aplicación',
                  onTap: () =>
                      _navigateToSection(context, const AdminApplicationScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para tarjeta de sección de administración.
class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: const Border.fromBorderSide(
            BorderSide(
              color: Color(0x1A000000),
              width: 1,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.accentBeige),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: const Color(AppColors.primaryOrange),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(AppColors.lightText),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(AppColors.primaryOrange),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
