import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/models/search_models.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_map.dart';
import '../widgets/app_search_bar.dart';
import '../providers/search_provider.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';

/// Pantalla principal después del login.
/// Contiene el header y la barra de navegación inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 1});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex = widget.initialIndex; // Índice inicial: Mapa

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          backgroundColor: const Color(AppColors.background),
          body: Column(
            children: [
              // Header reutilizable con foto del usuario
              AppHeader(
                onTitlePressed: () {
                  setState(() {
                    _currentIndex = 1; // Mismo comportamiento que pulsar "Mapa"
                  });
                },
                userProfilePhoto: authProvider.currentUser?.fotoPerfil,
                showUserPhoto: _currentIndex != 2,
                showProfileButton: _currentIndex != 2,
                onProfilePressed: () {
                  setState(() {
                    _currentIndex = 2; // Índice del perfil
                  });
                },
              ),
              // Contenido central según el índice
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
          // Barra de navegación inferior
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            userRoleId: authProvider.currentUser?.idRol,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        // Índice 0: Búsqueda/Favoritos
        return Container(
          color: const Color(AppColors.background),
          child: Center(
            child: Text(
              'Búsqueda y Favoritos',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      case 1:
        // Índice 1: Mapa
        return Selector<
            SearchProvider,
            ({MapFocusRequest? focusRequest, List<SearchRestaurantResult> visibleRestaurants})
          >(
            selector: (_, provider) => (
              focusRequest: provider.focusRequest,
              visibleRestaurants: provider.visibleRestaurants,
            ),
            builder: (context, mapState, _) {
              return Stack(
                children: [
                  AppMap(
                    focusRequest: mapState.focusRequest,
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: AppSearchBar(),
                  ),
                ],
              );
            },
          );
      case 2:
        // Índice 2: Perfil
        return const ProfileScreen();
      case 3:
        // Índice 3: Administración (solo para roles != usuario)
        return const AdminScreen();
      default:
        return Container(color: const Color(AppColors.background));
    }
  }
}
