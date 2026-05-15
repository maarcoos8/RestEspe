import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../data/models/admin_establishment_model.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/services/admin_service.dart';
import '../data/services/restaurant_detail_service.dart';
import '../widgets/restaurant_card_widget.dart';

/// Pantalla de listado de establecimientos para usuarios.
///
/// Incluye búsqueda por nombre, scroll infinito y orden por proximidad
/// cuando la ubicación del dispositivo está disponible.
class EstablishmentsListScreen extends StatefulWidget {
  const EstablishmentsListScreen({super.key});

  @override
  State<EstablishmentsListScreen> createState() => _EstablishmentsListScreenState();
}

class _EstablishmentsListScreenState extends State<EstablishmentsListScreen> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  final RestaurantDetailService _restaurantDetailService = RestaurantDetailService();
  final List<RestaurantDetail> _establishments = [];

  Timer? _debounceTimer;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _appliedFilter = '';
  String? _errorMessage;
  int _skip = 0;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _filterController.addListener(_onFilterTextChanged);
    _initialize();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _filterController.dispose();
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

  void _onFilterTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final nextFilter = _filterController.text.trim();
      if (nextFilter == _appliedFilter) {
        return;
      }

      setState(() {
        _appliedFilter = nextFilter;
      });
      _loadFirstPage();
    });
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _skip = 0;
      _hasMore = true;
      _establishments.clear();
    });

    try {
      final items = await AdminService.getEstablecimientos(
        skip: 0,
        limit: _pageSize,
        nombre: _appliedFilter,
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

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final items = await AdminService.getEstablecimientos(
        skip: _skip,
        limit: _pageSize,
        nombre: _appliedFilter,
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

  Future<List<RestaurantDetail>> _loadRestaurantDetails(List<AdminEstablishmentModel> items) async {
    final details = await Future.wait(
      items.map((item) => _restaurantDetailService.getRestaurantDetail(item.idEstablecimiento)),
    );

    return details.whereType<RestaurantDetail>().toList(growable: false);
  }

  void _sortByProximityIfAvailable() {
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
              child: TextField(
                controller: _filterController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Filtrar por nombre',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(AppColors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0x1A000000)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0x1A000000)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(AppColors.primaryOrange)),
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
                separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}