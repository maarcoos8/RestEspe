import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/models/search_models.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_map.dart';
import '../widgets/app_search_bar.dart';
import '../providers/search_provider.dart';

/// Pantalla principal después del login.
/// Contiene el header y la barra de navegación inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Índice inicial: Mapa

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: Column(
        children: [
          // Header reutilizable
          const AppHeader(),
          // Contenido central: mapa solo en la pestaña Mapa
          Expanded(
            child: _currentIndex == 1
                ? Selector<
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
                  )
                : Container(
                    color: const Color(AppColors.background),
                  ),
          ),
        ],
      ),
      // Barra de navegación inferior
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Aquí irá la lógica de navegación entre pantallas
        },
      ),
    );
  }
}
