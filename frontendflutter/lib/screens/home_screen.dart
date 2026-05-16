import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/role_constants.dart';
import '../data/models/search_models.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_map.dart';
import '../widgets/app_search_bar.dart';
import '../providers/search_provider.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'admin_establishments_screen.dart';
import 'create_establishment_screen.dart';
import 'establishments_list_screen.dart';

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

  void _navigateToCreateEstablishment() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreateEstablishmentScreen(),
      ),
    );
  }

  Widget? _getFloatingActionButton() {
    final authProvider = context.read<AuthProvider>();
    final roleId = authProvider.currentUser?.idRol;

    // Mostrar botón flotante solo si está en la pestaña de administración
    // y es administrador global
    if (_currentIndex == 3 && roleId == RoleConstants.rolAdministradorGlobal) {
      return FloatingActionButton(
        onPressed: _navigateToCreateEstablishment,
        backgroundColor: const Color(AppColors.primaryOrange),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    return null;
  }

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
          floatingActionButton: _getFloatingActionButton(),
        );
      },
    );
  }

  Widget _buildContent() {
    final authProvider = context.read<AuthProvider>();

    switch (_currentIndex) {
      case 0:
        // Índice 0: Listado
        return const EstablishmentsListScreen();
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
        // Si el usuario es `Administrador Global`, mostrar directamente
        // la pantalla de administración de establecimientos embebida
        // Si el usuario es `Propietario`, mostrar sus establecimientos filtrando por su ID
        final roleId = authProvider.currentUser?.idRol;
        final userId = authProvider.currentUser?.idUsuario;
        
        if (roleId == RoleConstants.rolAdministradorGlobal) {
          return const AdminEstablishmentsScreen(embedInHome: true);
        } else if (roleId == RoleConstants.rolPropietario && userId != null) {
          return AdminEstablishmentsScreen(embedInHome: true, propietarioId: userId);
        }

        return const AdminScreen();
      default:
        return Container(color: const Color(AppColors.background));
    }
  }
}
