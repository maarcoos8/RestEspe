import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav_bar.dart';

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
          // Contenido de la pantalla (vacío por ahora)
          Expanded(
            child: Container(
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
