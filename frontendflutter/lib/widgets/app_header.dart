import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Header reutilizable para todas las pantallas.
/// Muestra el nombre de la app a la izquierda y un botón de perfil a la derecha.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title = AppConstants.appName,
    this.onProfilePressed,
  });

  /// Título a mostrar en el header (por defecto "RestEspe")
  final String title;

  /// Callback cuando se pulsa el botón de perfil
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(AppColors.white),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Contenido del header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Título a la izquierda
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: const Color(AppColors.primaryOrange),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  // Botón de perfil a la derecha
                  InkResponse(
                    onTap: onProfilePressed,
                    radius: 28,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(AppColors.primaryOrange),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(AppColors.darkText),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divisor claro con la página
            Container(
              height: 1,
              color: const Color(AppColors.accentBeige),
            ),
          ],
        ),
      ),
    );
  }
}
