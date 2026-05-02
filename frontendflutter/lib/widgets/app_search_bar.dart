import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/models/search_models.dart';
import '../providers/search_provider.dart';

/// Barra de búsqueda para la pantalla de mapa.
/// Permite escribir texto pero sin ejecutar búsqueda aún.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({super.key});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late final LayerLink _layerLink;
  OverlayEntry? _overlayEntry;
  SearchProvider? _searchProvider;
  bool _overlayVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    _layerLink = LayerLink();
    _focusNode.addListener(_syncOverlay);
    _searchController.addListener(_handleTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<SearchProvider>();
    if (_searchProvider == provider) {
      return;
    }

    _searchProvider?.removeListener(_handleProviderChanged);
    _searchProvider = provider;
    _searchProvider?.addListener(_handleProviderChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchProvider?.removeListener(_handleProviderChanged);
    _focusNode.removeListener(_syncOverlay);
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    _searchProvider?.onQueryChanged(_searchController.text);
    _syncOverlay();
  }

  void _handleProviderChanged() {
    if (!mounted) {
      return;
    }
    _syncOverlay();
    _overlayEntry?.markNeedsBuild();
  }

  void _syncOverlay() {
    final provider = _searchProvider;
    if (provider == null) {
      return;
    }

    final shouldShow = _focusNode.hasFocus && _searchController.text.trim().isNotEmpty;

    if (!shouldShow || (!provider.isLoading && !provider.hasResults)) {
      _removeOverlay();
      return;
    }

    _showOverlay();
  }

  void _showOverlay() {
    if (_overlayVisible) {
      return;
    }

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final provider = overlayContext.read<SearchProvider>();
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissOverlay,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 64),
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: MediaQuery.of(overlayContext).size.width - 32,
                      child: _SearchResultsPanel(
                        provider: provider,
                        onLocationSelected: (location) {
                          provider.selectLocation(location);
                          _dismissOverlay();
                        },
                        onRestaurantSelected: (restaurant) {
                          provider.selectRestaurant(restaurant);
                          _dismissOverlay();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _overlayVisible = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayVisible = false;
  }

  void _dismissOverlay() {
    if (mounted) {
      _focusNode.unfocus();
    }
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
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
                focusNode: _focusNode,
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
      ),
    );
  }
}

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel({
    required this.provider,
    required this.onLocationSelected,
    required this.onRestaurantSelected,
  });

  final SearchProvider provider;
  final ValueChanged<SearchLocationResult> onLocationSelected;
  final ValueChanged<SearchRestaurantResult> onRestaurantSelected;

  @override
  Widget build(BuildContext context) {
    final hasResults = provider.locations.isNotEmpty || provider.restaurants.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 360),
      child: provider.isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            )
          : !hasResults
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Sin resultados'),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  children: [
                    if (provider.restaurants.isNotEmpty) ...[
                      _SectionHeader(title: '🍴 Restaurantes'),
                      ...provider.restaurants.map(
                        (restaurant) => _SearchItem(
                          title: restaurant.nombre,
                          subtitle: restaurant.direccionTexto ?? 'Sin dirección',
                          icon: Icons.restaurant_rounded,
                          onTap: () => onRestaurantSelected(restaurant),
                        ),
                      ),
                    ],
                    if (provider.locations.isNotEmpty) ...[
                      _SectionHeader(title: '📍 Ubicaciones'),
                      ...provider.locations.map(
                        (location) => _SearchItem(
                          title: location.displayName,
                          subtitle: 'Abrir ubicación en el mapa',
                          icon: Icons.place_rounded,
                          onTap: () => onLocationSelected(location),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(AppColors.primaryOrange),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(AppColors.accentBeige),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(AppColors.primaryOrange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(AppColors.darkText),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(AppColors.lightText),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}