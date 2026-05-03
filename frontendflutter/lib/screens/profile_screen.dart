import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/animated_favorite_card.dart';

/// Pantalla de perfil del usuario.
/// Muestra la información del usuario autenticado con Google y sus favoritos.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _syncedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentUser = context.read<AuthProvider>().currentUser;
    final currentUserId = currentUser?.idUsuario;

    if (_syncedUserId != currentUserId) {
      _syncedUserId = currentUserId;
      unawaited(context.read<FavoritesProvider>().syncUser(currentUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(AppColors.background),
      child: SafeArea(
        top: false,
        child: Consumer2<AuthProvider, FavoritesProvider>(
          builder: (context, authProvider, favoritesProvider, _) {
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      label: const Text('Cerrar Sesión'),
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
                  const SizedBox(height: 24),
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0x22000000),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Establecimientos favoritos',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(AppColors.darkText),
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (favoritesProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(
                        color: Color(AppColors.primaryOrange),
                      ),
                    )
                  else if (favoritesProvider.favoriteRestaurants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Todavía no tienes establecimientos favoritos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(AppColors.lightText),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.separated(
                      itemCount: favoritesProvider.favoriteRestaurants.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final favorite = favoritesProvider.favoriteRestaurants[index];
                        return AnimatedFavoriteCard(
                          restaurant: favorite,
                        );
                      },
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
