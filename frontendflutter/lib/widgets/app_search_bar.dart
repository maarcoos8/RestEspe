import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Barra de búsqueda para la pantalla de mapa.
/// Permite escribir texto pero sin ejecutar búsqueda aún.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({super.key});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: const Color(AppColors.lightText),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Busca establecimientos o ubicaciones',
                hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(AppColors.lightText),
                      fontWeight: FontWeight.w400,
                    ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(AppColors.darkText),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.tune_rounded,
            color: const Color(AppColors.primaryOrange),
            size: 28,
          ),
        ],
      ),
    );
  }
}