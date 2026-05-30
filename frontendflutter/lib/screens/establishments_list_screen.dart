import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/models/admin_establishment_model.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/models/search_models.dart';
import '../data/services/admin_service.dart';
import '../data/services/restaurant_detail_service.dart';
import '../providers/search_provider.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/restaurant_card_widget.dart';
import 'restaurant_detail_screen.dart';

/// Pantalla de listado de establecimientos para usuarios.
///
/// Incluye búsqueda por nombre, scroll infinito y orden por proximidad
/// cuando la ubicación del dispositivo está disponible.
class EstablishmentsListScreen extends StatefulWidget {
  const EstablishmentsListScreen({super.key});

  @override
  State<EstablishmentsListScreen> createState() =>
      _EstablishmentsListScreenState();
}

class _EstablishmentsListScreenState extends State<EstablishmentsListScreen> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final RestaurantDetailService _restaurantDetailService =
      RestaurantDetailService();
  final List<RestaurantDetail> _establishments = [];

  Timer? _debounceTimer;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _appliedFilter = '';
  String? _errorMessage;
  int _skip = 0;
  Position? _currentLocation;
  SearchProvider? _searchProvider;
  RestaurantMapFilters _lastAppliedFilters = const RestaurantMapFilters();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<SearchProvider>();
    if (_searchProvider == provider) {
      return;
    }

    _searchProvider?.removeListener(_handleSearchProviderChanged);
    _searchProvider = provider;
    _lastAppliedFilters = provider.filters;
    _searchProvider?.addListener(_handleSearchProviderChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchProvider?.removeListener(_handleSearchProviderChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _resolveCurrentLocation();
    await _loadFirstPage();
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _currentLocation = null;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _currentLocation = null;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = position;
      });
      _sortByProximityIfAvailable();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentLocation = null;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _onFilterTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final nextFilter = value.trim();
      if (nextFilter == _appliedFilter) {
        return;
      }

      setState(() {
        _appliedFilter = nextFilter;
      });
      _loadFirstPage();
    });
  }

  void _handleSearchProviderChanged() {
    final provider = _searchProvider;
    if (provider == null) {
      return;
    }

    final currentFilters = provider.filters;
    if (_areFiltersEqual(_lastAppliedFilters, currentFilters)) {
      return;
    }

    _lastAppliedFilters = currentFilters;
    _loadFirstPage();
  }

  bool _areFiltersEqual(RestaurantMapFilters left, RestaurantMapFilters right) {
    return left.onlyVerified == right.onlyVerified &&
        left.minimumRating == right.minimumRating &&
        _sameIntLists(left.selectedDietIds, right.selectedDietIds) &&
        _sameIntLists(left.selectedTypeIds, right.selectedTypeIds);
  }

  bool _sameIntLists(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    final sortedLeft = [...left]..sort();
    final sortedRight = [...right]..sort();
    for (int i = 0; i < sortedLeft.length; i++) {
      if (sortedLeft[i] != sortedRight[i]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _skip = 0;
      _hasMore = true;
      _establishments.clear();
    });

    try {
      final activeFilters = _searchProvider?.filters;
      final items = await AdminService.getEstablecimientos(
        skip: 0,
        limit: _pageSize,
        nombre: _appliedFilter,
        categoriaDietaIds: activeFilters?.selectedDietIds,
        tipoEstablecimientoIds: activeFilters?.selectedTypeIds,
        soloVerificados: activeFilters?.onlyVerified == true ? true : null,
        puntuacionMediaMinima: activeFilters?.minimumRating,
      );
      final details = await _loadRestaurantDetails(items);

      if (!mounted) return;
      setState(() {
        _establishments.addAll(details);
        _skip = items.length;
        _hasMore = items.length == _pageSize;
        _isInitialLoading = false;
      });
      _sortByProximityIfAvailable();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final activeFilters = _searchProvider?.filters;
      final items = await AdminService.getEstablecimientos(
        skip: _skip,
        limit: _pageSize,
        nombre: _appliedFilter,
        categoriaDietaIds: activeFilters?.selectedDietIds,
        tipoEstablecimientoIds: activeFilters?.selectedTypeIds,
        soloVerificados: activeFilters?.onlyVerified == true ? true : null,
        puntuacionMediaMinima: activeFilters?.minimumRating,
      );
      final details = await _loadRestaurantDetails(items);

      if (!mounted) return;
      setState(() {
        _establishments.addAll(details);
        _skip += items.length;
        _hasMore = items.length == _pageSize;
        _isLoadingMore = false;
      });
      _sortByProximityIfAvailable();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  Future<List<RestaurantDetail>> _loadRestaurantDetails(
    List<AdminEstablishmentModel> items,
  ) async {
    final details = await Future.wait(
      items.map(
        (item) => _restaurantDetailService.getRestaurantDetail(
          item.idEstablecimiento,
        ),
      ),
    );

    return details.whereType<RestaurantDetail>().toList(growable: false);
  }

  void _sortByProximityIfAvailable() {
    if (!mounted) return;
    final location = _currentLocation;
    if (location == null || _establishments.length < 2) {
      return;
    }

    setState(() {
      _establishments.sort((a, b) {
        final distanceA = _distanceMetersFromCurrentLocation(a);
        final distanceB = _distanceMetersFromCurrentLocation(b);

        if (distanceA == null && distanceB == null) {
          return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        }
        if (distanceA == null) {
          return 1;
        }
        if (distanceB == null) {
          return -1;
        }
        return distanceA.compareTo(distanceB);
      });
    });
  }

  double? _distanceMetersFromCurrentLocation(RestaurantDetail restaurant) {
    final location = _currentLocation;
    final coordinates = restaurant.coordinates;
    if (location == null || coordinates == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      coordinates.latitude,
      coordinates.longitude,
    );
  }

  Future<void> _onRefresh() async {
    await _resolveCurrentLocation();
    await _loadFirstPage();
  }

  void _openRestaurantDetail(RestaurantDetail restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          restaurant: restaurant,
          currentLocation: _currentLocation != null
              ? Position(
                  latitude: _currentLocation!.latitude,
                  longitude: _currentLocation!.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  altitudeAccuracy: 0,
                  heading: 0,
                  headingAccuracy: 0,
                  speed: 0,
                  speedAccuracy: 0,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(AppColors.background),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppSearchBar(
                hintText: 'Filtrar establecimientos por nombre',
                enableSuggestions: false,
                showLocationSuggestions: false,
                onQueryChanged: _onFilterTextChanged,
              ),
            ),
            if (_searchProvider?.hasActiveFilters == true)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.center,
                  child: FilledButton.icon(
                    onPressed: () {
                      _searchProvider?.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Quitar filtros'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(AppColors.primaryOrange),
                      foregroundColor: const Color(AppColors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            if (_currentLocation != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 16,
                      color: Color(AppColors.primaryOrange),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ordenado por proximidad',
                      style: TextStyle(
                        color: Color(AppColors.lightText),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (_isInitialLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(AppColors.primaryOrange),
                  ),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: Text(
                    'Error al cargar establecimientos\n\n$_errorMessage',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else if (_establishments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: Text(
                    _appliedFilter.isEmpty
                        ? 'No hay establecimientos para mostrar.'
                        : 'No hay resultados para ese filtro.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: _establishments.length + (_isLoadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= _establishments.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(AppColors.primaryOrange),
                        ),
                      ),
                    );
                  }

                  return RestaurantCardWidget(
                    restaurant: _establishments[index],
                    currentLocation: _currentLocation,
                    compact: true,
                    onCardTap: () =>
                        _openRestaurantDetail(_establishments[index]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
