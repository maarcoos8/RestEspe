import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';

/// Pantalla de perfil del usuario.
/// Muestra la información del usuario autenticado con Google.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(AppColors.background),
      child: SafeArea(
        top: false,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.currentUser;

            if (user == null) {
              return Center(
                child: Text(
                  'No hay usuario autenticado',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Foto de perfil principal
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(AppColors.primaryOrange),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: user.fotoPerfil != null && user.fotoPerfil!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              user.fotoPerfil!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(AppColors.accentBeige),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 72,
                                    color: Color(AppColors.darkText),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(AppColors.accentBeige),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 72,
                              color: Color(AppColors.darkText),
                            ),
                          ),
                  ),
                    const SizedBox(height: 24),
                    Text(
                      user.nombreCompleto ?? 'Usuario',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(AppColors.darkText),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(AppColors.lightText),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
